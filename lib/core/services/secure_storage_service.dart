import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart';

import '../../models/vault_item.dart';
import '../../models/security_settings.dart';

/// Hardware-backed secure storage service for Caveau.
///
/// Encapsulates interactions with [FlutterSecureStorage], leveraging:
/// - Android Keystore (AES-256 encryption with automatic recovery reset)
/// - iOS & macOS Keychain (with `first_unlock_this_device` accessibility)
///
/// Manages:
/// - Master PIN hashes and salts
/// - Security configuration preferences
/// - Vault item records and index indexing
/// - Password-protected encrypted backup exports (v2: AES-256-GCM + PBKDF2)
///   and backward-compatible verified imports (v1: XOR legacy, v2: AES-GCM)
class SecureStorageService {
  final FlutterSecureStorage _storage;

  /// Stream that emits `true` when a Keystore hardware reset destroys all data.
  /// Consumers can listen to this to display a user-facing warning before the
  /// app transitions to [AuthStatus.setupRequired].
  final StreamController<bool> _keystoreResetController =
      StreamController<bool>.broadcast();

  Stream<bool> get onKeystoreReset => _keystoreResetController.stream;

  /// Initializes [SecureStorageService] with optional injected [FlutterSecureStorage] instance for testing.
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                resetOnError: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
              mOptions: MacOsOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  // Storage key constants
  static const String _keyMasterPinHash = 'caveau_master_pin_hash';
  static const String _keyMasterPinSalt = 'caveau_master_pin_salt';
  static const String _keySecuritySettings = 'caveau_security_settings';
  static const String _keyVaultIndex = 'caveau_vault_index';
  static const String _itemPrefix = 'caveau_item_';

  // Backup v2 crypto constants
  static const int _pbkdf2Iterations = 600000;
  static const int _pbkdf2KeyLength = 32; // 256-bit AES key
  static const int _gcmIvLength = 12;     // 96-bit GCM nonce (NIST recommended)
  static const int _gcmTagLength = 16;    // 128-bit authentication tag

  // ===========================================================================
  // MASTER PIN & SALT MANAGEMENT
  // ===========================================================================

  /// Persists the stretched Master PIN [hash] and its associated cryptographic [salt].
  Future<void> saveMasterPin({
    required String hash,
    required String salt,
  }) async {
    await _storage.write(key: _keyMasterPinHash, value: hash);
    await _storage.write(key: _keyMasterPinSalt, value: salt);
  }

  /// Retrieves the stored Master PIN hash from secure hardware storage.
  /// Emits a Keystore reset event if a [PlatformException] indicates hardware failure.
  Future<String?> getMasterPinHash() async {
    try {
      return await _storage.read(key: _keyMasterPinHash);
    } on PlatformException catch (e) {
      // Android Keystore hardware failure — storage was reset by resetOnError:true
      if (_isKeystoreError(e)) {
        _keystoreResetController.add(true);
      }
      return null;
    }
  }

  /// Retrieves the stored Master PIN salt from secure hardware storage.
  Future<String?> getMasterPinSalt() async {
    try {
      return await _storage.read(key: _keyMasterPinSalt);
    } on PlatformException {
      return null;
    }
  }

  /// Checks whether a Master PIN has been saved in secure storage.
  Future<bool> hasMasterPin() async {
    final hash = await getMasterPinHash();
    return hash != null && hash.isNotEmpty;
  }

  // ===========================================================================
  // SECURITY SETTINGS PERSISTENCE
  // ===========================================================================

  /// Saves the user's [SecuritySettings] serialized JSON to secure storage.
  Future<void> saveSecuritySettings(SecuritySettings settings) async {
    await _storage.write(
      key: _keySecuritySettings,
      value: settings.serialize(),
    );
  }

  /// Loads [SecuritySettings] from secure storage, falling back to default values if not found or corrupted.
  Future<SecuritySettings> getSecuritySettings() async {
    try {
      final raw = await _storage.read(key: _keySecuritySettings);
      if (raw != null && raw.isNotEmpty) {
        return SecuritySettings.deserialize(raw);
      }
    } catch (_) {
      // Return default settings on read or parse failure
    }
    return const SecuritySettings();
  }

  // ===========================================================================
  // VAULT ITEMS & INDEXING
  // ===========================================================================

  /// Retrieves the list of stored vault item IDs from the index key.
  Future<List<String>> _getVaultIndex() async {
    try {
      final raw = await _storage.read(key: _keyVaultIndex);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {
      // In case of corrupt index, fallback to empty list
    }
    return [];
  }

  /// Writes the updated list of vault item [ids] to the index key.
  Future<void> _saveVaultIndex(List<String> ids) async {
    await _storage.write(key: _keyVaultIndex, value: jsonEncode(ids));
  }

  /// Saves or updates a [VaultItem] in secure storage and maintains the index.
  Future<void> saveVaultItem(VaultItem item) async {
    final ids = await _getVaultIndex();
    if (!ids.contains(item.id)) {
      ids.add(item.id);
      await _saveVaultIndex(ids);
    }
    await _storage.write(
      key: '$_itemPrefix${item.id}',
      value: item.serialize(),
    );
  }

  /// Fetches a single [VaultItem] by its unique [id], or `null` if not found.
  Future<VaultItem?> getVaultItem(String id) async {
    try {
      final raw = await _storage.read(key: '$_itemPrefix$id');
      if (raw != null) {
        return VaultItem.deserialize(raw);
      }
    } catch (_) {
      // Return null on parsing failure
    }
    return null;
  }

  /// Retrieves all vault items, automatically cleaning orphaned index keys,
  /// and returning them sorted: favorites first, followed by most recently modified.
  Future<List<VaultItem>> getAllVaultItems() async {
    final ids = await _getVaultIndex();
    final List<VaultItem> items = [];
    final List<String> validIds = [];

    for (final id in ids) {
      final item = await getVaultItem(id);
      if (item != null) {
        items.add(item);
        validIds.add(id);
      }
    }

    // Clean up index if orphaned IDs were found
    if (validIds.length != ids.length) {
      await _saveVaultIndex(validIds);
    }

    // Sort order: Favorites pinned to top, then sorted descending by update timestamp
    items.sort((a, b) {
      if (a.isFavorite != b.isFavorite) {
        return a.isFavorite ? -1 : 1;
      }
      return b.updatedAt.compareTo(a.updatedAt);
    });

    return items;
  }

  /// Deletes a vault item by [id] from secure storage and removes it from the index.
  Future<void> deleteVaultItem(String id) async {
    final ids = await _getVaultIndex();
    ids.remove(id);
    await _saveVaultIndex(ids);
    await _storage.delete(key: '$_itemPrefix$id');
  }

  /// Completely wipes all data stored in secure storage (Master PIN, settings, all vault items).
  Future<void> clearAllData() async {
    await _storage.deleteAll();
  }

  // ===========================================================================
  // ENCRYPTED BACKUP & RESTORE — v2 (AES-256-GCM + PBKDF2)
  // ===========================================================================

  /// Derives a 256-bit AES key from [password] and [salt] using PBKDF2-HMAC-SHA256.
  /// Uses [_pbkdf2Iterations] rounds as per OWASP 2024 recommendations for SHA-256.
  static Uint8List _deriveKeyPbkdf2(String password, Uint8List salt) {
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    pbkdf2.init(Pbkdf2Parameters(salt, _pbkdf2Iterations, _pbkdf2KeyLength));
    return pbkdf2.process(Uint8List.fromList(utf8.encode(password)));
  }

  /// Generates [length] cryptographically secure random bytes.
  static Uint8List _randomBytes(int length) {
    final rng = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => rng.nextInt(256)),
    );
  }

  /// Encrypts [plaintext] with AES-256-GCM using [key] and [iv].
  /// Returns the ciphertext with the 16-byte authentication tag appended.
  static Uint8List _aesGcmEncrypt(
      Uint8List key, Uint8List iv, Uint8List plaintext) {
    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        true, // encrypt
        AEADParameters(
          KeyParameter(key),
          _gcmTagLength * 8, // tag length in bits
          iv,
          Uint8List(0), // no additional authenticated data
        ),
      );
    return cipher.process(plaintext);
  }

  /// Decrypts [ciphertext] (with appended GCM tag) with AES-256-GCM.
  /// Throws [InvalidCipherTextException] if authentication fails (tampered data).
  static Uint8List _aesGcmDecrypt(
      Uint8List key, Uint8List iv, Uint8List ciphertext) {
    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        false, // decrypt
        AEADParameters(
          KeyParameter(key),
          _gcmTagLength * 8,
          iv,
          Uint8List(0),
        ),
      );
    return cipher.process(ciphertext);
  }

  /// Exports all vault items into a password-protected JSON backup envelope.
  ///
  /// Format v2: PBKDF2-HMAC-SHA256 key derivation (600K iterations) +
  /// AES-256-GCM encryption (random 12-byte IV, 128-bit auth tag).
  /// The auth tag provides both integrity and authenticity — no separate checksum needed.
  ///
  /// Backup envelope structure (JSON):
  /// ```json
  /// {
  ///   "caveau_backup": "v2",
  ///   "salt": "<base64>",   // 32-byte PBKDF2 salt
  ///   "iv":   "<base64>",   // 12-byte GCM nonce
  ///   "data": "<base64>"    // ciphertext + 16-byte GCM tag
  /// }
  /// ```
  Future<String> exportEncryptedBackup(String backupPassword) async {
    final items = await getAllVaultItems();
    final payloadJson = jsonEncode({
      'version': '2.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'items': items.map((i) => i.toJson()).toList(),
    });

    // Generate fresh random salt and IV for each export
    final salt = _randomBytes(32);
    final iv = _randomBytes(_gcmIvLength);

    // Derive 256-bit key via PBKDF2-HMAC-SHA256 (600K rounds) and encrypt in background isolate
    final ciphertext = await Isolate.run(() {
      final key = _deriveKeyPbkdf2(backupPassword, salt);
      final plaintext = Uint8List.fromList(utf8.encode(payloadJson));
      return _aesGcmEncrypt(key, iv, plaintext);
    });

    final envelope = {
      'caveau_backup': 'v2',
      'salt': base64Encode(salt),
      'iv': base64Encode(iv),
      'data': base64Encode(ciphertext),
    };

    return jsonEncode(envelope);
  }

  /// Imports and restores vault items from an encrypted [backupJson] envelope using [backupPassword].
  ///
  /// Supports:
  /// - **v2** (AES-256-GCM + PBKDF2): current format. GCM authentication tag
  ///   guarantees integrity — wrong password throws [InvalidCipherTextException].
  /// - **v1** (XOR + SHA-256 checksum): legacy format, maintained for backward compatibility.
  ///
  /// Returns the total count of imported items.
  Future<int> importEncryptedBackup(
      String backupJson, String backupPassword) async {
    final Map<String, dynamic> backup =
        jsonDecode(backupJson) as Map<String, dynamic>;

    final String version = backup['caveau_backup'] as String? ?? '';

    late String payloadJson;

    if (version == 'v2') {
      // --- v2: AES-256-GCM + PBKDF2 ---
      final salt = base64Decode(backup['salt'] as String);
      final iv = base64Decode(backup['iv'] as String);
      final ciphertext = base64Decode(backup['data'] as String);

      payloadJson = await Isolate.run(() {
        final key = _deriveKeyPbkdf2(backupPassword, salt);
        try {
          final plaintext = _aesGcmDecrypt(key, iv, ciphertext);
          return utf8.decode(plaintext);
        } on InvalidCipherTextException {
          // GCM authentication failed — wrong password or tampered data
          throw const FormatException(
              'Password errata o backup corrotto/manomesso');
        }
      });
    } else if (version == 'v1') {
      // --- v1 Legacy: XOR stream cipher + SHA-256 checksum ---
      // Maintained for backward compatibility with backups created before v2.
      final String dataB64 = backup['data'] as String;
      final String checksum = backup['checksum'] as String;

      payloadJson = await Isolate.run(() {
        final encryptedBytes = base64Decode(dataB64);

        // Validate ciphertext integrity
        final actualChecksum = sha256.convert(encryptedBytes).toString();
        if (actualChecksum != checksum) {
          throw const FormatException('Backup corrotto o manomesso');
        }

        // Decrypt v1 payload using derived password key (XOR)
        final keyBytes = sha256.convert(utf8.encode(backupPassword)).bytes;
        final decryptedBytes = List<int>.generate(
          encryptedBytes.length,
          (i) => encryptedBytes[i] ^ keyBytes[i % keyBytes.length],
        );

        return utf8.decode(decryptedBytes);
      });
    } else {
      throw const FormatException('Formato backup non riconosciuto');
    }

    final payload = jsonDecode(payloadJson) as Map<String, dynamic>;
    final List<dynamic> itemsList = payload['items'] as List<dynamic>;

    // Save each imported item into local secure storage
    int importedCount = 0;
    for (final rawItem in itemsList) {
      final item = VaultItem.fromJson(rawItem as Map<String, dynamic>);
      await saveVaultItem(item);
      importedCount++;
    }

    return importedCount;
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  /// Checks if a [PlatformException] from flutter_secure_storage is a Keystore error.
  bool _isKeystoreError(PlatformException e) {
    final code = e.code.toLowerCase();
    final message = (e.message ?? '').toLowerCase();
    // Android Keystore errors typically contain these patterns
    return code.contains('keystore') ||
        code.contains('exception') ||
        message.contains('keystore') ||
        message.contains('keystoreexception') ||
        message.contains('android keystore') ||
        message.contains('user not authenticated');
  }

  /// Releases resources held by this service.
  void dispose() {
    _keystoreResetController.close();
  }
}
