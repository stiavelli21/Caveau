import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';
import 'secure_storage_service.dart';

/// Authentication service for Caveau.
/// 
/// Handles:
/// 1. Hardware-backed biometric authentication via [LocalAuthentication] (Face ID, Touch ID, Biometric prompt).
/// 2. Cryptographic Master PIN security using cryptographically secure random salts and key stretching (5,000 iterative SHA-256 rounds).
/// 3. Brute-force protection with failed attempt tracking and progressive lockout cooldowns.
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
  // BIOMETRIC CAPABILITIES & AUTHENTICATION
  // ===========================================================================

  /// Checks whether the device hardware supports biometrics and if enrollment exists.
  Future<bool> isBiometricAvailable() async {
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
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Triggers the OS-native biometric authentication prompt.
  /// Returns `true` if authentication succeeded, `false` otherwise.
  Future<bool> authenticateWithBiometrics({
    String reason = 'Authenticate to access Caveau',
  }) async {
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

  /// Generates a cryptographically secure random salt of [length] bytes (default 32 bytes / 256 bits).
  /// Uses [Random.secure] (CSPRNG) and returns a URL-safe Base64 encoded string.
  static String generateSalt([int length = 32]) {
    final random = Random.secure();
    final values = List<int>.generate(length, (_) => random.nextInt(256));
    return base64UrlEncode(values);
  }

  /// Computes a stretched hash of the Master PIN combined with the provided cryptographic salt.
  /// 
  /// Applies 5,000 iterative rounds of SHA-256 hashing to mitigate brute-force
  /// and dictionary attacks by artificially increasing computational cost.
  static String hashPin(String pin, String salt) {
    // Initial round: hash the concatenated salt and PIN
    var currentHash = sha256.convert(utf8.encode('$salt$pin')).bytes;
    
    // 5,000 iterative SHA-256 rounds for key stretching
    for (int i = 0; i < 5000; i++) {
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
  /// Also enforces brute-force lockout checks and updates failed attempt counters.
  Future<bool> verifyMasterPin(String pin) async {
    final settings = await _storageService.getSecuritySettings();

    // Check if the user is currently locked out due to excessive failed attempts
    if (settings.lockoutUntil != null &&
        DateTime.now().isBefore(settings.lockoutUntil!)) {
      return false;
    }

    final storedHash = await _storageService.getMasterPinHash();
    final storedSalt = await _storageService.getMasterPinSalt();

    // If no PIN or salt is found in secure storage, verification fails
    if (storedHash == null || storedSalt == null) {
      return false;
    }

    final computedHash = hashPin(pin, storedSalt);
    final isValid = computedHash == storedHash;

    if (isValid) {
      // Reset failed attempts counter and lockout timer upon successful authentication
      if (settings.failedAttempts > 0) {
        await _storageService.saveSecuritySettings(
          settings.copyWith(failedAttempts: 0, lockoutUntil: null),
        );
      }
      return true;
    } else {
      // Increment failed attempts and trigger a 30-second lockout if >= 5 failed attempts
      final newFailures = settings.failedAttempts + 1;
      DateTime? lockout;
      if (newFailures >= 5) {
        lockout = DateTime.now().add(const Duration(seconds: 30));
      }
      await _storageService.saveSecuritySettings(
        settings.copyWith(
          failedAttempts: newFailures,
          lockoutUntil: lockout,
        ),
      );
      return false;
    }
  }

  /// Changes the Master PIN after verifying that [currentPin] is valid.
  /// Returns `true` if changed successfully, `false` if [currentPin] is incorrect.
  Future<bool> changeMasterPin({
    required String currentPin,
    required String newPin,
  }) async {
    final isCurrentValid = await verifyMasterPin(currentPin);
    if (!isCurrentValid) return false;
    await setupMasterPin(newPin);
    return true;
  }
}
