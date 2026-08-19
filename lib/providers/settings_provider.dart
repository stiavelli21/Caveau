import 'package:flutter/material.dart';
import '../core/services/secure_storage_service.dart';
import '../models/security_settings.dart';

/// State management provider for user preferences, security parameters, and language.
/// 
/// Interacts directly with [SecureStorageService] to persist and reload settings asynchronously.
class SettingsProvider extends ChangeNotifier {
  final SecureStorageService _storageService;
  SecuritySettings _settings = const SecuritySettings();
  bool _isLoading = true;

  /// Creates a [SettingsProvider] instance with optional storage injection.
  SettingsProvider({SecureStorageService? storageService})
      : _storageService = storageService ?? SecureStorageService();

  /// Current active [SecuritySettings] in memory.
  SecuritySettings get settings => _settings;

  /// Whether the initial settings are currently being loaded from disk.
  bool get isLoading => _isLoading;

  /// Loads security configuration from secure storage.
  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();
    _settings = await _storageService.getSecuritySettings();
    _isLoading = false;
    notifyListeners();
  }

  /// Updates whether biometric authentication (Face ID / Fingerprint) is allowed.
  Future<void> updateBiometrics(bool enabled) async {
    _settings = _settings.copyWith(biometricsEnabled: enabled);
    await _storageService.saveSecuritySettings(_settings);
    notifyListeners();
  }

  /// Updates the auto-lock background timeout in seconds (0 = immediate).
  Future<void> updateAutoLock(int seconds) async {
    _settings = _settings.copyWith(autoLockSeconds: seconds);
    await _storageService.saveSecuritySettings(_settings);
    notifyListeners();
  }

  /// Updates whether the privacy shield blur filter is activated when backgrounded.
  Future<void> updatePrivacyScreen(bool enabled) async {
    _settings = _settings.copyWith(privacyScreenEnabled: enabled);
    await _storageService.saveSecuritySettings(_settings);
    notifyListeners();
  }

  /// Updates the clipboard auto-clear timeout in seconds (0 = disabled).
  Future<void> updateClipboardClear(int seconds) async {
    _settings = _settings.copyWith(clipboardClearSeconds: seconds);
    await _storageService.saveSecuritySettings(_settings);
    notifyListeners();
  }

  /// Updates the active application language code ('it', 'en', 'es', 'fr', 'de').
  Future<void> updateLanguage(String languageCode) async {
    _settings = _settings.copyWith(languageCode: languageCode);
    await _storageService.saveSecuritySettings(_settings);
    notifyListeners();
  }
}
