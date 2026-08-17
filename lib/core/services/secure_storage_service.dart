import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../models/vault_item.dart';
import '../../models/security_settings.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

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

  static const String _keyMasterPinHash = 'caveau_master_pin_hash';
  static const String _keyMasterPinSalt = 'caveau_master_pin_salt';
  static const String _keySecuritySettings = 'caveau_security_settings';
  static const String _keyVaultIndex = 'caveau_vault_index';
  static const String _itemPrefix = 'caveau_item_';

  // --- Master PIN Management ---
  Future<void> saveMasterPin({
    required String hash,
    required String salt,
  }) async {
    await _storage.write(key: _keyMasterPinHash, value: hash);
    await _storage.write(key: _keyMasterPinSalt, value: salt);
  }

  Future<String?> getMasterPinHash() async {
    return await _storage.read(key: _keyMasterPinHash);
  }

  Future<String?> getMasterPinSalt() async {
    return await _storage.read(key: _keyMasterPinSalt);
  }

  Future<bool> hasMasterPin() async {
    final hash = await getMasterPinHash();
    return hash != null && hash.isNotEmpty;
  }

  // --- Security Settings ---
  Future<void> saveSecuritySettings(SecuritySettings settings) async {
    await _storage.write(
      key: _keySecuritySettings,
      value: settings.serialize(),
    );
  }

  Future<SecuritySettings> getSecuritySettings() async {
    try {
      final raw = await _storage.read(key: _keySecuritySettings);
      if (raw != null && raw.isNotEmpty) {
        return SecuritySettings.deserialize(raw);
      }
    } catch (_) {}
    return const SecuritySettings();
  }

  // --- Vault Items ---
  Future<List<String>> _getVaultIndex() async {
    try {
      final raw = await _storage.read(key: _keyVaultIndex);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> _saveVaultIndex(List<String> ids) async {
    await _storage.write(key: _keyVaultIndex, value: jsonEncode(ids));
  }

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

  Future<VaultItem?> getVaultItem(String id) async {
    try {
      final raw = await _storage.read(key: '$_itemPrefix$id');
      if (raw != null) {
        return VaultItem.deserialize(raw);
      }
    } catch (_) {}
    return null;
  }

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

    if (validIds.length != ids.length) {
      await _saveVaultIndex(validIds);
    }

    // Sort by favorite first, then updated recently
    items.sort((a, b) {
      if (a.isFavorite != b.isFavorite) {
        return a.isFavorite ? -1 : 1;
      }
      return b.updatedAt.compareTo(a.updatedAt);
    });

    return items;
  }

  Future<void> deleteVaultItem(String id) async {
    final ids = await _getVaultIndex();
    ids.remove(id);
    await _saveVaultIndex(ids);
    await _storage.delete(key: '$_itemPrefix$id');
  }

  Future<void> clearAllData() async {
    await _storage.deleteAll();
  }

  // --- Encrypted Backup & Restore ---
  Future<String> exportEncryptedBackup(String backupPassword) async {
    final items = await getAllVaultItems();
    final payloadJson = jsonEncode({
      'version': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'items': items.map((i) => i.toJson()).toList(),
    });

    // Derive key using SHA-256 for simple portable password hash wrapping
    final keyBytes = sha256.convert(utf8.encode(backupPassword)).bytes;
    final payloadBytes = utf8.encode(payloadJson);
    
    // XOR stream cipher with key stream for local export container
    final encryptedBytes = List<int>.generate(payloadBytes.length, (i) {
      return payloadBytes[i] ^ keyBytes[i % keyBytes.length];
    });

    final checksum = sha256.convert(encryptedBytes).toString();
    final finalExport = {
      'caveau_backup': 'v1',
      'checksum': checksum,
      'data': base64Encode(encryptedBytes),
    };

    return jsonEncode(finalExport);
  }

  Future<int> importEncryptedBackup(String backupJson, String backupPassword) async {
    final Map<String, dynamic> backup = jsonDecode(backupJson) as Map<String, dynamic>;
    if (backup['caveau_backup'] != 'v1') {
      throw const FormatException('Formato di backup non riconosciuto');
    }

    final String dataB64 = backup['data'] as String;
    final String checksum = backup['checksum'] as String;
    final encryptedBytes = base64Decode(dataB64);

    final actualChecksum = sha256.convert(encryptedBytes).toString();
    if (actualChecksum != checksum) {
      throw const FormatException('File di backup corrotto o manomesso');
    }

    final keyBytes = sha256.convert(utf8.encode(backupPassword)).bytes;
    final decryptedBytes = List<int>.generate(encryptedBytes.length, (i) {
      return encryptedBytes[i] ^ keyBytes[i % keyBytes.length];
    });

    final payloadJson = utf8.decode(decryptedBytes);
    final payload = jsonDecode(payloadJson) as Map<String, dynamic>;
    final List<dynamic> itemsList = payload['items'] as List<dynamic>;

    int importedCount = 0;
    for (final rawItem in itemsList) {
      final item = VaultItem.fromJson(rawItem as Map<String, dynamic>);
      await saveVaultItem(item);
      importedCount++;
    }

    return importedCount;
  }
}
