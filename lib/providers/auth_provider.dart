import 'package:flutter/material.dart';
import '../core/services/auth_service.dart';
import '../core/services/secure_storage_service.dart';

enum AuthStatus {
  initial,
  setupRequired,
  locked,
  authenticated,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final SecureStorageService _storageService;

  AuthStatus _status = AuthStatus.initial;
  bool _isBiometricSupported = false;
  String? _errorMessage;
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;

  AuthProvider({
    AuthService? authService,
    SecureStorageService? storageService,
  })  : _authService = authService ?? AuthService(),
        _storageService = storageService ?? SecureStorageService();

  AuthStatus get status => _status;
  bool get isBiometricSupported => _isBiometricSupported;
  String? get errorMessage => _errorMessage;
  int get failedAttempts => _failedAttempts;
  bool get isLockedOut =>
      _lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!);
  int get lockoutSecondsRemaining {
    if (_lockoutUntil == null) return 0;
    final diff = _lockoutUntil!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  Future<void> checkInitialState() async {
    _isBiometricSupported = await _authService.isBiometricAvailable();
    final isConfigured = await _authService.isSetupComplete();

    if (!isConfigured) {
      _status = AuthStatus.setupRequired;
    } else {
      _status = AuthStatus.locked;
      // Auto-trigger biometric prompt if enabled
      final settings = await _storageService.getSecuritySettings();
      _failedAttempts = settings.failedAttempts;
      _lockoutUntil = settings.lockoutUntil;
    }
    notifyListeners();
  }

  Future<bool> authenticateWithBiometrics({bool silentFail = true}) async {
    _errorMessage = null;
    final settings = await _storageService.getSecuritySettings();
    if (!settings.biometricsEnabled) {
      if (!silentFail) {
        _errorMessage = 'Autenticazione biometrica disabilitata nelle impostazioni';
      }
      notifyListeners();
      return false;
    }

    final success = await _authService.authenticateWithBiometrics();
    if (success) {
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      _failedAttempts = 0;
      notifyListeners();
      return true;
    } else {
      if (!silentFail) {
        _errorMessage = 'Autenticazione biometrica non riuscita o annullata';
      }
      notifyListeners();
      return false;
    }
  }

  Future<bool> authenticateWithPin(String pin) async {
    _errorMessage = null;
    final success = await _authService.verifyMasterPin(pin);

    final settings = await _storageService.getSecuritySettings();
    _failedAttempts = settings.failedAttempts;
    _lockoutUntil = settings.lockoutUntil;

    if (success) {
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } else {
      if (isLockedOut) {
        _errorMessage =
            'Troppi tentativi falliti. Riprova tra $lockoutSecondsRemaining secondi.';
      } else {
        _errorMessage = 'PIN Master non corretto (${5 - _failedAttempts} tentativi rimasti)';
      }
      notifyListeners();
      return false;
    }
  }

  Future<void> setupMasterPin(String pin) async {
    await _authService.setupMasterPin(pin);
    _status = AuthStatus.authenticated;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> changePin({
    required String currentPin,
    required String newPin,
  }) async {
    _errorMessage = null;
    final success = await _authService.changeMasterPin(
      currentPin: currentPin,
      newPin: newPin,
    );
    if (!success) {
      _errorMessage = 'PIN Master attuale non valido';
      notifyListeners();
      return false;
    }
    notifyListeners();
    return true;
  }

  void lock() {
    _status = AuthStatus.locked;
    _errorMessage = null;
    notifyListeners();
  }
}
