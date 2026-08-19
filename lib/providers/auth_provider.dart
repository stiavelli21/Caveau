import 'package:flutter/material.dart';
import '../core/services/auth_service.dart';
import '../core/services/secure_storage_service.dart';

/// Overall authentication lifecycle state of the app session.
enum AuthStatus {
  /// App is initializing services and checking whether setup was completed.
  initial,

  /// First launch or wiped vault requiring initial Master PIN creation.
  setupRequired,

  /// Vault is locked and requires biometric or Master PIN authentication.
  locked,

  /// User is authenticated and decrypted vault data is accessible in memory.
  authenticated,
}

/// Specific error category for authentication failures.
enum AuthErrorType {
  biometricsDisabled,
  biometricsFailedOrCanceled,
  pinIncorrect,
  lockedOut,
  currentPinInvalid,
}

/// Provider managing session authentication state, biometrics, PIN verification, and lockout.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final SecureStorageService _storageService;

  AuthStatus _status = AuthStatus.initial;
  bool _isBiometricSupported = false;
  AuthErrorType? _errorType;
  String? _errorMessage;
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;

  /// Creates an [AuthProvider] with optional service injection.
  AuthProvider({
    AuthService? authService,
    SecureStorageService? storageService,
  })  : _authService = authService ?? AuthService(),
        _storageService = storageService ?? SecureStorageService();

  /// Current session authentication status.
  AuthStatus get status => _status;

  /// Whether the device hardware supports biometric verification.
  bool get isBiometricSupported => _isBiometricSupported;

  /// Active error type, if any.
  AuthErrorType? get errorType => _errorType;

  /// Active error message string (fallback).
  String? get errorMessage => _errorMessage;

  /// Consecutive failed authentication attempts.
  int get failedAttempts => _failedAttempts;

  /// Whether the user is currently locked out from PIN entry.
  bool get isLockedOut =>
      _lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!);

  /// Remaining seconds in the lockout cooldown timer.
  int get lockoutSecondsRemaining {
    if (_lockoutUntil == null) return 0;
    final diff = _lockoutUntil!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  /// Maps the active [_errorType] to a localized string from [AppLocalizations].
  String? getLocalizedErrorMessage(dynamic l10n) {
    if (_errorType == null) return _errorMessage;
    switch (_errorType!) {
      case AuthErrorType.biometricsDisabled:
        return l10n.biometricDisabledInSettings;
      case AuthErrorType.biometricsFailedOrCanceled:
        return l10n.biometricFailedOrCanceled;
      case AuthErrorType.lockedOut:
        return l10n.lockoutTimeRemaining(lockoutSecondsRemaining);
      case AuthErrorType.pinIncorrect:
        return l10n.pinAttemptsRemaining(5 - _failedAttempts);
      case AuthErrorType.currentPinInvalid:
        return l10n.currentPinInvalid;
    }
  }

  /// Checks whether a Master PIN exists and determines initial [AuthStatus].
  Future<void> checkInitialState() async {
    _isBiometricSupported = await _authService.isBiometricAvailable();
    final isConfigured = await _authService.isSetupComplete();

    if (!isConfigured) {
      _status = AuthStatus.setupRequired;
    } else {
      _status = AuthStatus.locked;
      // Load current lockout state from persistent settings
      final settings = await _storageService.getSecuritySettings();
      _failedAttempts = settings.failedAttempts;
      _lockoutUntil = settings.lockoutUntil;
    }
    notifyListeners();
  }

  /// Triggers biometric authentication (Face ID / Fingerprint).
  /// If [silentFail] is true, errors are ignored without setting UI error states (useful for auto-prompting).
  Future<bool> authenticateWithBiometrics({bool silentFail = true}) async {
    _errorMessage = null;
    _errorType = null;
    final settings = await _storageService.getSecuritySettings();
    if (!settings.biometricsEnabled) {
      if (!silentFail) {
        _errorType = AuthErrorType.biometricsDisabled;
        _errorMessage = 'Biometric authentication is disabled in settings';
      }
      notifyListeners();
      return false;
    }

    final success = await _authService.authenticateWithBiometrics();
    if (success) {
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      _errorType = null;
      _failedAttempts = 0;
      notifyListeners();
      return true;
    } else {
      if (!silentFail) {
        _errorType = AuthErrorType.biometricsFailedOrCanceled;
        _errorMessage = 'Biometric authentication failed or was cancelled';
      }
      notifyListeners();
      return false;
    }
  }

  /// Verifies the entered Master [pin] against the stored stretched hash.
  Future<bool> authenticateWithPin(String pin) async {
    _errorMessage = null;
    _errorType = null;
    final success = await _authService.verifyMasterPin(pin);

    final settings = await _storageService.getSecuritySettings();
    _failedAttempts = settings.failedAttempts;
    _lockoutUntil = settings.lockoutUntil;

    if (success) {
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      _errorType = null;
      notifyListeners();
      return true;
    } else {
      if (isLockedOut) {
        _errorType = AuthErrorType.lockedOut;
        _errorMessage =
            'Too many failed attempts. Try again in $lockoutSecondsRemaining seconds.';
      } else {
        _errorType = AuthErrorType.pinIncorrect;
        _errorMessage = 'Incorrect Master PIN (${5 - _failedAttempts} attempts remaining)';
      }
      notifyListeners();
      return false;
    }
  }

  /// Sets up a new Master PIN during initial onboarding.
  Future<void> setupMasterPin(String pin) async {
    await _authService.setupMasterPin(pin);
    _status = AuthStatus.authenticated;
    _errorMessage = null;
    _errorType = null;
    notifyListeners();
  }

  /// Changes the Master PIN after verifying the [currentPin].
  Future<bool> changePin({
    required String currentPin,
    required String newPin,
  }) async {
    _errorMessage = null;
    _errorType = null;
    final success = await _authService.changeMasterPin(
      currentPin: currentPin,
      newPin: newPin,
    );
    if (!success) {
      _errorType = AuthErrorType.currentPinInvalid;
      _errorMessage = 'Current Master PIN is invalid';
      notifyListeners();
      return false;
    }
    notifyListeners();
    return true;
  }

  /// Manually locks the vault, returning to [AuthStatus.locked].
  void lock() {
    _status = AuthStatus.locked;
    _errorMessage = null;
    _errorType = null;
    notifyListeners();
  }
}
