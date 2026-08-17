import 'package:flutter/material.dart';
import '../core/services/secure_storage_service.dart';
import '../models/security_settings.dart';

class SettingsProvider extends ChangeNotifier {
  final SecureStorageService _storageService;
  SecuritySettings _settings = const SecuritySettings();
  bool _isLoading = true;

  SettingsProvider({SecureStorageService? storageService})
      : _storageService = storageService ?? SecureStorageService();

  SecuritySettings get settings => _settings;
  bool get isLoading => _isLoading;

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();
    _settings = await _storageService.getSecuritySettings();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateBiometrics(bool enabled) async {
    _settings = _settings.copyWith(biometricsEnabled: enabled);
    await _storageService.saveSecuritySettings(_settings);
    notifyListeners();
  }

  Future<void> updateAutoLock(int seconds) async {
    _settings = _settings.copyWith(autoLockSeconds: seconds);
    await _storageService.saveSecuritySettings(_settings);
    notifyListeners();
  }

  Future<void> updatePrivacyScreen(bool enabled) async {
    _settings = _settings.copyWith(privacyScreenEnabled: enabled);
    await _storageService.saveSecuritySettings(_settings);
    notifyListeners();
  }

  Future<void> updateClipboardClear(int seconds) async {
    _settings = _settings.copyWith(clipboardClearSeconds: seconds);
    await _storageService.saveSecuritySettings(_settings);
    notifyListeners();
  }
}
