import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';
import '../utils/app_platform.dart';
import 'secure_storage_service.dart';

// ===========================================================================
// VERIFY PIN RESULT — top-level sealed hierarchy
// ===========================================================================

/// Result of a PIN verification attempt.
sealed class VerifyPinResult {
  const VerifyPinResult();
}

/// PIN verified successfully.
class VerifyPinSuccess extends VerifyPinResult {
  const VerifyPinSuccess();
}

/// PIN is incorrect. [failedAttempts] reflects the new total count.
/// [lockoutUntil] is non-null when a lockout is now active.
class VerifyPinFailure extends VerifyPinResult {
  final DateTime? lockoutUntil;
  final int failedAttempts;

  const VerifyPinFailure({
    required this.failedAttempts,
    this.lockoutUntil,
  });
}

/// Maximum failed attempts exceeded — vault has been auto-wiped.
class VerifyPinAutoWiped extends VerifyPinResult {
  const VerifyPinAutoWiped();
}

// ===========================================================================
// AUTH SERVICE
// ===========================================================================

/// Authentication service for Caveau.
///
/// Handles:
/// 1. Hardware-backed biometric authentication via [LocalAuthentication] (Face ID, Touch ID, Biometric prompt) on supported mobile platforms.
/// 2. Cryptographic Master PIN security using cryptographically secure random salts and key stretching.
/// 3. Progressive exponential anti-brute-force lockout with automatic vault wipe after [_autoWipeThreshold] failures.
///
/// ## Key Stretching
/// - Current algorithm: **200,000 iterative SHA-256 rounds** + 256-bit random salt.
/// - Legacy migration: if a stored hash was generated with 5,000 rounds and matches,
///   it is transparently re-hashed with 200,000 rounds and saved.
///
/// ## Lockout Schedule
/// | Consecutive failures | Lockout duration     |
/// |----------------------|----------------------|
/// | 1–4                  | None                 |
/// | 5                    | 30 seconds           |
/// | 6                    | 5 minutes            |
/// | 7                    | 30 minutes           |
/// | ≥ 8                  | Automatic vault wipe |
class AuthService {
  final LocalAuthentication _localAuth;
  final SecureStorageService _storageService;

  /// Creates an instance of [AuthService] with optional injected dependencies for testing.
  AuthService({
    LocalAuthentication? localAuth,
    SecureStorageService? storageService,
  })  : _localAuth = localAuth ?? LocalAuthentication(),
        _storageService = storageService ?? SecureStorageService();

  // ===========================================================================
  // LOCKOUT SCHEDULE
  // ===========================================================================

  /// Number of consecutive failed attempts after which the vault is auto-wiped.
  static const int _autoWipeThreshold = 8;

  /// Returns the lockout [Duration] for a given number of consecutive [failures].
  /// Returns [Duration.zero] if no lockout should be applied.
  static Duration lockoutDuration(int failures) {
    if (failures < 5) return Duration.zero;
    if (failures == 5) return const Duration(seconds: 30);
    if (failures == 6) return const Duration(minutes: 5);
    return const Duration(minutes: 30); // failures == 7
  }

  // ===========================================================================
  // BIOMETRIC CAPABILITIES & AUTHENTICATION
  // ===========================================================================

  /// Checks whether the device hardware supports biometrics and if enrollment exists.
  /// On desktop (PC), biometrics are disabled and always returns `false`.
  Future<bool> isBiometricAvailable() async {
    if (!AppPlatform.isBiometricsSupportedOnPlatform) {
      return false;
    }
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (_) {
      // In case of hardware access error or missing permission, safely fallback to false
      return false;
    }
  }

  /// Retrieves the list of enrolled biometric sensors on the device (e.g. fingerprint, face, weak/strong).
  /// On desktop (PC), returns an empty list.
  Future<List<BiometricType>> getAvailableBiometrics() async {
    if (!AppPlatform.isBiometricsSupportedOnPlatform) {
      return [];
    }
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Triggers the OS-native biometric authentication prompt.
  /// Returns `true` if authentication succeeded, `false` otherwise.
  /// On desktop (PC), returns `false`.
  Future<bool> authenticateWithBiometrics({
    String reason = 'Authenticate to access Caveau',
  }) async {
    if (!AppPlatform.isBiometricsSupportedOnPlatform) {
      return false;
    }
    try {
      final available = await isBiometricAvailable();
      if (!available) return false;

      return await _localAuth.authenticate(
        localizedReason: reason,
      );
    } catch (_) {
      // Return false if user canceled, sensor timed out, or permission denied
      return false;
    }
  }

  // ===========================================================================
  // MASTER PIN CRYPTOGRAPHY & KEY STRETCHING
  // ===========================================================================

  /// Current number of SHA-256 iterative rounds for key stretching.
  /// Per OWASP 2024 guidance (SHA-256 pure-iterative equivalent).
  static const int _hashIterations = 200000;

  /// Legacy number of iterations used before the security upgrade.
  /// Used for transparent migration of existing stored hashes.
  static const int _legacyHashIterations = 5000;

  /// Generates a cryptographically secure random salt of [length] bytes (default 32 bytes / 256 bits).
  /// Uses [Random.secure] (CSPRNG) and returns a URL-safe Base64 encoded string.
  static String generateSalt([int length = 32]) {
    final random = Random.secure();
    final values = List<int>.generate(length, (_) => random.nextInt(256));
    return base64UrlEncode(values);
  }

  /// Computes a stretched hash of the Master PIN combined with [salt].
  ///
  /// Applies [iterations] rounds of SHA-256 hashing (default: 200,000) to
  /// mitigate brute-force and dictionary attacks by increasing computational cost.
  static String hashPin(String pin, String salt,
      {int iterations = _hashIterations}) {
    // Initial round: hash the concatenated salt and PIN
    var currentHash = sha256.convert(utf8.encode('$salt$pin')).bytes;

    // Iterative SHA-256 rounds for key stretching
    for (int i = 0; i < iterations; i++) {
      currentHash = sha256.convert(currentHash).bytes;
    }

    return base64UrlEncode(currentHash);
  }

  /// Initializes and saves the Master PIN with a newly generated random salt.
  Future<void> setupMasterPin(String pin) async {
    final salt = generateSalt();
    final hash = hashPin(pin, salt);
    await _storageService.saveMasterPin(hash: hash, salt: salt);
  }

  /// Checks if a Master PIN has already been configured on this device.
  Future<bool> isSetupComplete() async {
    return await _storageService.hasMasterPin();
  }

  /// Verifies whether the provided [pin] matches the stored Master PIN hash.
  ///
  /// Enforces brute-force lockout checks, updates failed attempt counters,
  /// and triggers an automatic vault wipe after [_autoWipeThreshold] consecutive failures.
  ///
  /// Includes transparent migration from legacy 5,000-round hashes to 200,000 rounds.
  Future<VerifyPinResult> verifyMasterPin(String pin) async {
    final settings = await _storageService.getSecuritySettings();

    // Check if the user is currently locked out due to excessive failed attempts
    if (settings.lockoutUntil != null &&
        DateTime.now().isBefore(settings.lockoutUntil!)) {
      return VerifyPinFailure(
        failedAttempts: settings.failedAttempts,
        lockoutUntil: settings.lockoutUntil,
      );
    }

    final storedHash = await _storageService.getMasterPinHash();
    final storedSalt = await _storageService.getMasterPinSalt();

    // If no PIN or salt is found in secure storage, verification fails
    if (storedHash == null || storedSalt == null) {
      return const VerifyPinFailure(failedAttempts: 0);
    }

    // Check with current iteration count first
    final computedHash = hashPin(pin, storedSalt);
    bool isValid = computedHash == storedHash;

    // Transparent migration: try legacy 5,000-round hash if current fails
    if (!isValid) {
      final legacyHash = hashPin(pin, storedSalt, iterations: _legacyHashIterations);
      if (legacyHash == storedHash) {
        // PIN is correct — migrate to new 200,000-round hash
        isValid = true;
        await _storageService.saveMasterPin(
          hash: computedHash, // save the new 200K-round hash
          salt: storedSalt,
        );
      }
    }

    if (isValid) {
      // Reset failed attempts counter and lockout timer upon successful authentication
      if (settings.failedAttempts > 0) {
        await _storageService.saveSecuritySettings(
          settings.copyWith(failedAttempts: 0, lockoutUntil: null),
        );
      }
      return const VerifyPinSuccess();
    } else {
      // Increment failed attempts
      final newFailures = settings.failedAttempts + 1;

      // Check for auto-wipe threshold
      if (newFailures >= _autoWipeThreshold) {
        await _storageService.clearAllData();
        return const VerifyPinAutoWiped();
      }

      // Compute exponential lockout duration
      final duration = lockoutDuration(newFailures);
      DateTime? lockout;
      if (duration > Duration.zero) {
        lockout = DateTime.now().add(duration);
      }

      await _storageService.saveSecuritySettings(
        settings.copyWith(
          failedAttempts: newFailures,
          lockoutUntil: lockout,
        ),
      );

      return VerifyPinFailure(
        failedAttempts: newFailures,
        lockoutUntil: lockout,
      );
    }
  }

  /// Changes the Master PIN after verifying that [currentPin] is valid.
  /// Returns `true` if changed successfully, `false` if [currentPin] is incorrect or triggers wipe.
  Future<bool> changeMasterPin({
    required String currentPin,
    required String newPin,
  }) async {
    final result = await verifyMasterPin(currentPin);
    if (result is! VerifyPinSuccess) return false;
    await setupMasterPin(newPin);
    return true;
  }
}
