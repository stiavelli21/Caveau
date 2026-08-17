import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';
import 'secure_storage_service.dart';

class AuthService {
  final LocalAuthentication _localAuth;
  final SecureStorageService _storageService;

  AuthService({
    LocalAuthentication? localAuth,
    SecureStorageService? storageService,
  })  : _localAuth = localAuth ?? LocalAuthentication(),
        _storageService = storageService ?? SecureStorageService();

  // --- Biometrics Capabilities ---
  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (_) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  Future<bool> authenticateWithBiometrics({
    String reason = 'Autenticati per accedere al Caveau',
  }) async {
    try {
      final available = await isBiometricAvailable();
      if (!available) return false;

      return await _localAuth.authenticate(
        localizedReason: reason,
      );
    } catch (_) {
      return false;
    }
  }

  // --- Master PIN / Password Security ---
  static String generateSalt([int length = 32]) {
    final random = Random.secure();
    final values = List<int>.generate(length, (_) => random.nextInt(256));
    return base64UrlEncode(values);
  }

  static String hashPin(String pin, String salt) {
    // 5000 rounds iterative SHA-256 for stretching
    var currentHash = sha256.convert(utf8.encode('$salt$pin')).bytes;
    for (int i = 0; i < 5000; i++) {
      currentHash = sha256.convert(currentHash).bytes;
    }
    return base64UrlEncode(currentHash);
  }

  Future<void> setupMasterPin(String pin) async {
    final salt = generateSalt();
    final hash = hashPin(pin, salt);
    await _storageService.saveMasterPin(hash: hash, salt: salt);
  }

  Future<bool> isSetupComplete() async {
    return await _storageService.hasMasterPin();
  }

  Future<bool> verifyMasterPin(String pin) async {
    final settings = await _storageService.getSecuritySettings();

    // Check lockout
    if (settings.lockoutUntil != null &&
        DateTime.now().isBefore(settings.lockoutUntil!)) {
      return false;
    }

    final storedHash = await _storageService.getMasterPinHash();
    final storedSalt = await _storageService.getMasterPinSalt();

    if (storedHash == null || storedSalt == null) {
      return false;
    }

    final computedHash = hashPin(pin, storedSalt);
    final isValid = computedHash == storedHash;

    if (isValid) {
      // Reset failed attempts on success
      if (settings.failedAttempts > 0) {
        await _storageService.saveSecuritySettings(
          settings.copyWith(failedAttempts: 0, lockoutUntil: null),
        );
      }
      return true;
    } else {
      // Increment failed attempts and apply cooldown if >= 5
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
