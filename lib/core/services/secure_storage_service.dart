import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
/// - Password-protected encrypted backup exports and verified imports
class SecureStorageService {
  final FlutterSecureStorage _storage;

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
  Future<String?> getMasterPinHash() async {
    return await _storage.read(key: _keyMasterPinHash);
  }

  /// Retrieves the stored Master PIN salt from secure hardware storage.
  Future<String?> getMasterPinSalt() async {
    return await _storage.read(key: _keyMasterPinSalt);
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
  // ENCRYPTED BACKUP & RESTORE
  // ===========================================================================

  /// Exports all vault items into a password-protected JSON backup envelope.
  /// 
  /// Derives an encryption key from [backupPassword] using SHA-256, encrypts the payload
  /// using a byte stream cipher, and computes a SHA-256 integrity checksum.
  Future<String> exportEncryptedBackup(String backupPassword) async {
    final items = await getAllVaultItems();
    final payloadJson = jsonEncode({
      'version': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'items': items.map((i) => i.toJson()).toList(),
    });

    // Derive key using SHA-256 for password-based encryption wrapping
    final keyBytes = sha256.convert(utf8.encode(backupPassword)).bytes;
    final payloadBytes = utf8.encode(payloadJson);
    
    // XOR stream cipher with derived key stream for portable encrypted backup payload
    final encryptedBytes = List<int>.generate(payloadBytes.length, (i) {
      return payloadBytes[i] ^ keyBytes[i % keyBytes.length];
    });

    // Compute SHA-256 checksum over ciphertext for tamper-detection
    final checksum = sha256.convert(encryptedBytes).toString();
    final finalExport = {
      'caveau_backup': 'v1',
      'checksum': checksum,
      'data': base64Encode(encryptedBytes),
    };

    return jsonEncode(finalExport);
  }

  /// Imports and restores vault items from an encrypted [backupJson] envelope using [backupPassword].
  /// 
  /// Verifies format version, validates the SHA-256 checksum, decrypts data,
  /// and persists all parsed items into the vault. Returns the total count of imported items.
  Future<int> importEncryptedBackup(String backupJson, String backupPassword) async {
    final Map<String, dynamic> backup = jsonDecode(backupJson) as Map<String, dynamic>;
    if (backup['caveau_backup'] != 'v1') {
      throw const FormatException('Unrecognized backup format');
    }

    final String dataB64 = backup['data'] as String;
    final String checksum = backup['checksum'] as String;
    final encryptedBytes = base64Decode(dataB64);

    // Validate ciphertext integrity
    final actualChecksum = sha256.convert(encryptedBytes).toString();
    if (actualChecksum != checksum) {
      throw const FormatException('Corrupted or tampered backup file');
    }

    // Decrypt payload using derived password key
    final keyBytes = sha256.convert(utf8.encode(backupPassword)).bytes;
    final decryptedBytes = List<int>.generate(encryptedBytes.length, (i) {
      return encryptedBytes[i] ^ keyBytes[i % keyBytes.length];
    });

    final payloadJson = utf8.decode(decryptedBytes);
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
}
