import 'package:flutter_test/flutter_test.dart';
import 'package:caveau/core/constants/app_brand_terms.dart';
import 'package:caveau/core/localization/app_localizations.dart';
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
    test('default settings have autoLockSeconds set to 30 seconds and languageCode it', () {
      const settings = SecuritySettings();
      expect(settings.autoLockSeconds, equals(30));
      expect(settings.biometricsEnabled, isTrue);
      expect(settings.privacyScreenEnabled, isTrue);
      expect(settings.clipboardClearSeconds, equals(30));
      expect(settings.languageCode, equals('it'));
    });

    test('serializes and deserializes security settings with custom language', () {
      const settings = SecuritySettings(
        biometricsEnabled: false,
        autoLockSeconds: 60,
        privacyScreenEnabled: true,
        clipboardClearSeconds: 15,
        failedAttempts: 2,
        languageCode: 'en',
      );

      final jsonStr = settings.serialize();
      final restored = SecuritySettings.deserialize(jsonStr);

      expect(restored.biometricsEnabled, isFalse);
      expect(restored.autoLockSeconds, equals(60));
      expect(restored.privacyScreenEnabled, isTrue);
      expect(restored.clipboardClearSeconds, equals(15));
      expect(restored.failedAttempts, equals(2));
      expect(restored.languageCode, equals('en'));
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

  group('Localization & Brand Terms Tests', () {
    test('immutable brand and universal terms constants remain constant', () {
      expect(AppBrandTerms.appName, equals('Caveau'));
      expect(AppBrandTerms.password, equals('Password'));
      expect(AppBrandTerms.pin, equals('PIN'));
      expect(AppBrandTerms.masterPin, equals('Master PIN'));
      expect(AppBrandTerms.pinMaster, equals('PIN Master'));
      expect(AppBrandTerms.sha256, equals('SHA-256'));
      expect(AppBrandTerms.aes256, equals('AES-256'));
      expect(AppBrandTerms.faceId, equals('Face ID'));
      expect(AppBrandTerms.touchId, equals('Touch ID'));
      expect(AppBrandTerms.apiKey, equals('API Key'));
      expect(AppBrandTerms.androidKeystore, equals('Android Keystore'));
      expect(AppBrandTerms.iosKeychain, equals('iOS Keychain'));
    });

    test('AppLocalizationsIt has correct Italian translations and uses brand terms', () {
      final it = AppLocalizationsIt();
      expect(it.languageCode, equals('it'));
      expect(it.appName, equals('Caveau'));
      expect(it.unlockVaultButton, equals('Sblocca Cassaforte'));
      expect(it.vaultProtectedTitle, contains('Caveau'));
      expect(it.enterMasterPinPrompt, contains('PIN Master'));
      expect(it.settingsTitle, equals('Impostazioni di Sicurezza'));
      expect(it.languageOptionLabel, equals('Lingua'));
      expect(it.categoryDisplayName(VaultCategory.login), contains('Password'));
    });

    test('AppLocalizationsEn has correct English translations and uses brand terms', () {
      final en = AppLocalizationsEn();
      expect(en.languageCode, equals('en'));
      expect(en.appName, equals('Caveau'));
      expect(en.unlockVaultButton, equals('Unlock Vault'));
      expect(en.vaultProtectedTitle, contains('Caveau'));
      expect(en.enterMasterPinPrompt, contains('Master PIN'));
      expect(en.settingsTitle, equals('Security Settings'));
      expect(en.languageOptionLabel, equals('Language'));
      expect(en.categoryDisplayName(VaultCategory.login), contains('Password'));
    });

    test('AppLocalizationsEs has correct Spanish translations and uses brand terms', () {
      final es = AppLocalizationsEs();
      expect(es.languageCode, equals('es'));
      expect(es.appName, equals('Caveau'));
      expect(es.unlockVaultButton, equals('Desbloquear Bóveda'));
      expect(es.vaultProtectedTitle, contains('Caveau'));
      expect(es.enterMasterPinPrompt, contains('Master PIN'));
      expect(es.settingsTitle, equals('Ajustes de Seguridad'));
      expect(es.languageOptionLabel, equals('Idioma'));
      expect(es.categoryDisplayName(VaultCategory.login), contains('Contraseñas'));
    });

    test('AppLocalizationsFr has correct French translations and uses brand terms', () {
      final fr = AppLocalizationsFr();
      expect(fr.languageCode, equals('fr'));
      expect(fr.appName, equals('Caveau'));
      expect(fr.unlockVaultButton, equals('Déverrouiller le Coffre'));
      expect(fr.vaultProtectedTitle, contains('Caveau'));
      expect(fr.enterMasterPinPrompt, contains('Master PIN'));
      expect(fr.settingsTitle, equals('Paramètres de Sécurité'));
      expect(fr.languageOptionLabel, equals('Langue'));
      expect(fr.categoryDisplayName(VaultCategory.login), contains('Mots de Passe'));
    });

    test('AppLocalizationsDe has correct German translations and uses brand terms', () {
      final de = AppLocalizationsDe();
      expect(de.languageCode, equals('de'));
      expect(de.appName, equals('Caveau'));
      expect(de.unlockVaultButton, equals('Tresor Entsperren'));
      expect(de.vaultProtectedTitle, contains('Caveau'));
      expect(de.enterMasterPinPrompt, contains('Master PIN'));
      expect(de.settingsTitle, equals('Sicherheitseinstellungen'));
      expect(de.languageOptionLabel, equals('Sprache'));
      expect(de.categoryDisplayName(VaultCategory.login), contains('Passwörter'));
    });

    test('supportedLanguages metadata list has all 5 languages configured', () {
      expect(AppLocalizations.supportedLanguages.length, equals(5));
      final codes = AppLocalizations.supportedLanguages.map((l) => l.code).toList();
      expect(codes, containsAll(['it', 'en', 'es', 'fr', 'de']));
    });
  });
}
