import 'package:flutter_test/flutter_test.dart';
import 'package:caveau/core/utils/password_generator.dart';
import 'package:caveau/core/services/auth_service.dart';
import 'package:caveau/models/vault_item.dart';
import 'package:caveau/models/security_settings.dart';

void main() {
  group('PasswordGenerator Tests', () {
    test('generates password of requested length', () {
      for (final len in [8, 16, 24, 32]) {
        final pwd = PasswordGenerator.generate(length: len);
        expect(pwd.length, equals(len));
      }
    });

    test('excludes ambiguous characters when requested', () {
      for (int i = 0; i < 20; i++) {
        final pwd = PasswordGenerator.generate(
          length: 32,
          excludeAmbiguous: true,
        );
        for (final amb in ['I', 'l', '1', 'O', '0']) {
          expect(pwd.contains(amb), isFalse, reason: 'Found ambiguous char $amb');
        }
      }
    });

    test('evaluates password strength correctly', () {
      expect(PasswordGenerator.evaluateStrength('123'), equals(PasswordStrength.veryWeak));
      expect(PasswordGenerator.evaluateStrength('password9'), equals(PasswordStrength.weak));
      expect(PasswordGenerator.evaluateStrength('Password123'), equals(PasswordStrength.medium));
      expect(PasswordGenerator.evaluateStrength('Password123!'), equals(PasswordStrength.strong));
      expect(PasswordGenerator.evaluateStrength('K#9mP\$vL2@qZ8x!w'), equals(PasswordStrength.veryStrong));
    });
  });

  group('VaultItem Serialization Tests', () {
    test('serializes and deserializes correctly', () {
      final item = VaultItem(
        title: 'Google Account',
        category: VaultCategory.login,
        username: 'user@gmail.com',
        password: 'SuperSecretPassword!2026',
        websiteUrl: 'https://accounts.google.com',
        isFavorite: true,
        customFields: [
          CustomField(label: 'Recovery Email', value: 'backup@gmail.com'),
          CustomField(label: 'PIN 2FA', value: '123456', isSecret: true),
        ],
      );

      final jsonString = item.serialize();
      final restored = VaultItem.deserialize(jsonString);

      expect(restored.id, equals(item.id));
      expect(restored.title, equals('Google Account'));
      expect(restored.category, equals(VaultCategory.login));
      expect(restored.username, equals('user@gmail.com'));
      expect(restored.password, equals('SuperSecretPassword!2026'));
      expect(restored.websiteUrl, equals('https://accounts.google.com'));
      expect(restored.isFavorite, isTrue);
      expect(restored.customFields.length, equals(2));
      expect(restored.customFields[0].label, equals('Recovery Email'));
      expect(restored.customFields[1].isSecret, isTrue);
    });

    test('handles Payment Card category fields', () {
      final cardItem = VaultItem(
        title: 'Carta Revolut',
        category: VaultCategory.card,
        cardHolder: 'MARIO ROSSI',
        cardNumber: '4532123456789012',
        cardExpiry: '12/28',
        cardCvv: '789',
        cardPin: '1234',
      );

      final jsonStr = cardItem.serialize();
      final restored = VaultItem.deserialize(jsonStr);

      expect(restored.category, equals(VaultCategory.card));
      expect(restored.cardHolder, equals('MARIO ROSSI'));
      expect(restored.cardNumber, equals('4532123456789012'));
      expect(restored.cardExpiry, equals('12/28'));
      expect(restored.cardCvv, equals('789'));
      expect(restored.cardPin, equals('1234'));
    });
  });

  group('SecuritySettings Tests', () {
    test('default settings have autoLockSeconds set to 30 seconds', () {
      const settings = SecuritySettings();
      expect(settings.autoLockSeconds, equals(30));
      expect(settings.biometricsEnabled, isTrue);
      expect(settings.privacyScreenEnabled, isTrue);
      expect(settings.clipboardClearSeconds, equals(30));
    });

    test('serializes and deserializes security settings', () {
      const settings = SecuritySettings(
        biometricsEnabled: false,
        autoLockSeconds: 60,
        privacyScreenEnabled: true,
        clipboardClearSeconds: 15,
        failedAttempts: 2,
      );

      final jsonStr = settings.serialize();
      final restored = SecuritySettings.deserialize(jsonStr);

      expect(restored.biometricsEnabled, isFalse);
      expect(restored.autoLockSeconds, equals(60));
      expect(restored.privacyScreenEnabled, isTrue);
      expect(restored.clipboardClearSeconds, equals(15));
      expect(restored.failedAttempts, equals(2));
    });
  });

  group('AuthService Cryptographic Hashing Tests', () {
    test('generates random salt with high entropy', () {
      final salt1 = AuthService.generateSalt();
      final salt2 = AuthService.generateSalt();
      expect(salt1, isNotEmpty);
      expect(salt2, isNotEmpty);
      expect(salt1, isNot(equals(salt2)));
    });

    test('hashes PIN consistently with salt', () {
      const salt = 'fixed_test_salt_1234567890';
      const pin = '987654';

      final hash1 = AuthService.hashPin(pin, salt);
      final hash2 = AuthService.hashPin(pin, salt);
      final hashDifferentPin = AuthService.hashPin('987655', salt);

      expect(hash1, equals(hash2));
      expect(hash1, isNot(equals(hashDifferentPin)));
    });
  });
}
