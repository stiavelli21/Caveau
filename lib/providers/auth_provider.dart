import 'dart:async';
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

  /// The vault was auto-wiped after too many consecutive failed PIN attempts.
  /// The UI should notify the user and transition to [setupRequired].
  autoWiped,
}

/// Specific error category for authentication failures.
enum AuthErrorType {
  biometricsDisabled,
  biometricsFailedOrCanceled,
  pinIncorrect,
  lockedOut,
  currentPinInvalid,
  autoWipe,
}

/// Provider managing session authentication state, biometrics, PIN verification, and lockout.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final SecureStorageService _storageService;
  final DateTime Function() _clock;

  AuthStatus _status = AuthStatus.initial;
  bool _isBiometricSupported = false;
  AuthErrorType? _errorType;
  String? _errorMessage;
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;
  Timer? _lockoutTimer;

  /// Creates an [AuthProvider] with optional service injection.
  AuthProvider({
    AuthService? authService,
    SecureStorageService? storageService,
    DateTime Function()? clock,
  })  : _authService = authService ?? AuthService(),
        _storageService = storageService ?? SecureStorageService(),
        _clock = clock ?? (() => DateTime.now());

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
      _lockoutUntil != null && _clock().isBefore(_lockoutUntil!);

  /// Remaining seconds in the lockout cooldown timer.
  int get lockoutSecondsRemaining {
    if (_lockoutUntil == null) return 0;
    final diffMs = _lockoutUntil!.difference(_clock()).inMilliseconds;
    if (diffMs <= 0) return 0;
    return (diffMs / 1000).ceil();
  }

  /// Number of PIN attempts before the next lockout tier activates.
  int get attemptsUntilNextLockout {
    if (_failedAttempts < 4) return 4 - _failedAttempts;
    return 0;
  }

  /// Number of PIN attempts remaining before auto-wipe (threshold = 8).
  int get attemptsUntilWipe {
    const threshold = 8; // AuthService._autoWipeThreshold
    final remaining = threshold - _failedAttempts;
    return remaining > 0 ? remaining : 0;
  }

  /// Starts or restarts the periodic 1-second countdown timer for active lockout periods.
  void _startLockoutTimer() {
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isLockedOut) {
        timer.cancel();
        _lockoutTimer = null;
        _lockoutUntil = null;
        if (_errorType == AuthErrorType.lockedOut) {
          _errorType = null;
          _errorMessage = null;
        }
        notifyListeners();
      } else {
        notifyListeners();
      }
    });
  }

  /// Refreshes the lockout state, starting countdown or clearing expired states as appropriate.
  void refreshLockoutState() {
    if (_lockoutUntil != null && !isLockedOut) {
      _lockoutTimer?.cancel();
      _lockoutTimer = null;
      _lockoutUntil = null;
      if (_errorType == AuthErrorType.lockedOut) {
        _errorType = null;
        _errorMessage = null;
      }
      notifyListeners();
    } else if (isLockedOut && _lockoutTimer == null) {
      _startLockoutTimer();
    }
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
        if (!isLockedOut) return null;
        return l10n.lockoutTimeRemaining(lockoutSecondsRemaining);
      case AuthErrorType.pinIncorrect:
        // Show warnings about upcoming lockouts and auto-wipe
        if (_failedAttempts >= 6) {
          return l10n.pinWipeWarning(attemptsUntilWipe);
        }
        return l10n.pinAttemptsRemaining(5 - _failedAttempts);
      case AuthErrorType.currentPinInvalid:
        return l10n.currentPinInvalid;
      case AuthErrorType.autoWipe:
        return l10n.autoWipeTriggered;
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
      if (isLockedOut) {
        _errorType = AuthErrorType.lockedOut;
        _startLockoutTimer();
      } else if (_lockoutUntil != null) {
        _lockoutUntil = null;
      }
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
      _lockoutTimer?.cancel();
      _lockoutTimer = null;
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
  /// Handles progressive lockout and auto-wipe on excessive failures.
  Future<bool> authenticateWithPin(String pin) async {
    _errorMessage = null;
    _errorType = null;

    final result = await _authService.verifyMasterPin(pin);

    if (result is VerifyPinSuccess) {
      _lockoutTimer?.cancel();
      _lockoutTimer = null;
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      _errorType = null;
      _failedAttempts = 0;
      _lockoutUntil = null;
      notifyListeners();
      return true;
    } else if (result is VerifyPinAutoWiped) {
      // Vault has been automatically wiped — notify UI
      _lockoutTimer?.cancel();
      _lockoutTimer = null;
      _status = AuthStatus.autoWiped;
      _errorType = AuthErrorType.autoWipe;
      _failedAttempts = 0;
      _lockoutUntil = null;
      notifyListeners();
      return false;
    } else if (result is VerifyPinFailure) {
      _failedAttempts = result.failedAttempts;
      _lockoutUntil = result.lockoutUntil;

      if (isLockedOut) {
        _errorType = AuthErrorType.lockedOut;
        _startLockoutTimer();
      } else {
        _lockoutTimer?.cancel();
        _lockoutTimer = null;
        _errorType = AuthErrorType.pinIncorrect;
      }
      notifyListeners();
      return false;
    }

    // Unreachable fallback
    notifyListeners();
    return false;
  }

  /// Sets up a new Master PIN during initial onboarding.
  Future<void> setupMasterPin(String pin) async {
    _lockoutTimer?.cancel();
    _lockoutTimer = null;
    await _authService.setupMasterPin(pin);
    _status = AuthStatus.authenticated;
    _errorMessage = null;
    _errorType = null;
    _failedAttempts = 0;
    _lockoutUntil = null;
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

  /// Acknowledges the auto-wipe state and transitions to [AuthStatus.setupRequired].
  void acknowledgeAutoWipe() {
    _lockoutTimer?.cancel();
    _lockoutTimer = null;
    _status = AuthStatus.setupRequired;
    _errorMessage = null;
    _errorType = null;
    _failedAttempts = 0;
    _lockoutUntil = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    _lockoutTimer = null;
    super.dispose();
  }
}
