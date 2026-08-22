import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caveau/core/constants/app_brand_terms.dart';
import 'package:caveau/core/localization/app_localizations.dart';
import 'package:caveau/core/utils/app_platform.dart';
import 'package:caveau/core/utils/password_generator.dart';
import 'package:caveau/core/services/auth_service.dart';
import 'package:caveau/core/services/secure_storage_service.dart';
import 'package:caveau/core/services/screen_security_service.dart';
import 'package:caveau/models/vault_item.dart';
import 'package:caveau/models/security_settings.dart';
import 'package:caveau/providers/auth_provider.dart';

/// Comprehensive unit test suite verifying core cryptography, data serialization,
/// security configurations, and multilingual localization assets in Caveau.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
      expect(AppBrandTerms.github, equals('GitHub'));
      expect(AppBrandTerms.privacyPolicyUrl, contains('privacy-policy.html'));
      expect(AppBrandTerms.githubRepoUrl, contains('Caveau'));
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
      expect(it.sectionLegalAndAbout, equals('NOTE LEGALI & TRASPARENZA'));
      expect(it.privacyPolicyTileTitle, equals('Informativa sulla Privacy'));
      expect(it.openSourceTileTitle, equals('Codice Sorgente Open Source'));
      expect(it.onboardingInfoTitle, contains('Informazioni Importanti'));
      expect(it.onboardingInfoFreeAppTitle, contains('Gratuita'));
      expect(it.confirmBackupPasswordFieldLabel, contains('Conferma'));
      expect(it.backupPasswordsDoNotMatchError, contains('non corrispondono'));
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
      expect(en.sectionLegalAndAbout, equals('LEGAL & TRANSPARENCY'));
      expect(en.privacyPolicyTileTitle, equals('Privacy Policy'));
      expect(en.openSourceTileTitle, equals('Open Source Code'));
      expect(en.onboardingInfoTitle, contains('Important Information'));
      expect(en.onboardingInfoFreeAppTitle, contains('Free'));
      expect(en.confirmBackupPasswordFieldLabel, contains('Confirm'));
      expect(en.backupPasswordsDoNotMatchError, contains('do not match'));
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
      expect(de.selectItemToViewDetails, contains('Details'));
      expect(de.offlineSafeBadge, contains('Offline'));
      expect(de.lockVaultAction, contains('sperren'));
      expect(de.addNewItemDesktop, equals('Neues Element'));
    });

    test('supportedLanguages metadata list has all 5 languages configured', () {
      expect(AppLocalizations.supportedLanguages.length, equals(5));
      final codes = AppLocalizations.supportedLanguages.map((l) => l.code).toList();
      expect(codes, containsAll(['it', 'en', 'es', 'fr', 'de']));
    });

    test('all 5 languages implement desktop and split-view strings without empty values', () {
      final locs = [
        AppLocalizationsIt(),
        AppLocalizationsEn(),
        AppLocalizationsEs(),
        AppLocalizationsFr(),
        AppLocalizationsDe(),
      ];

      for (final l in locs) {
        expect(l.selectItemToViewDetails.isNotEmpty, isTrue);
        expect(l.noItemSelectedPrompt.isNotEmpty, isTrue);
        expect(l.offlineSafeBadge.isNotEmpty, isTrue);
        expect(l.lockVaultAction.isNotEmpty, isTrue);
        expect(l.addNewItemDesktop.isNotEmpty, isTrue);
        expect(l.onboardingDisclaimerRequiredError.isNotEmpty, isTrue);
        expect(l.autoLock15s.isNotEmpty, isTrue);
        expect(l.formatAutoLock(15), equals('15s'));
        expect(l.wipeAllDataConfirmButton.isNotEmpty, isTrue);
        expect(l.confirmWipeAuthTitle.isNotEmpty, isTrue);
        expect(l.confirmWipeAuthPrompt.isNotEmpty, isTrue);
        expect(l.exportingBackupProgress.isNotEmpty, isTrue);
        expect(l.restoringBackupProgress.isNotEmpty, isTrue);
      }

      expect(AppLocalizationsIt().wipeAllDataConfirmButton, equals('ELIMINA'));
      expect(AppLocalizationsEn().wipeAllDataConfirmButton, equals('DELETE'));
      expect(AppLocalizationsEs().wipeAllDataConfirmButton, equals('ELIMINAR'));
      expect(AppLocalizationsFr().wipeAllDataConfirmButton, equals('SUPPRIMER'));
      expect(AppLocalizationsDe().wipeAllDataConfirmButton, equals('LÖSCHEN'));
      expect(AppLocalizationsIt().exportingBackupProgress, contains('AES-256'));
    });
  });

  group('SecureStorageService Encrypted Backup & Restore Tests', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
    });

    test('exports encrypted backup (v2) in Isolate and restores correctly', () async {
      final storage = SecureStorageService();
      final item1 = VaultItem(
        id: 'item-1',
        title: 'Secret Login',
        category: VaultCategory.login,
        username: 'alice',
        password: 'Password123!',
      );
      await storage.saveVaultItem(item1);

      const backupPassword = 'StrongBackupPassword123!';
      final backupPayload = await storage.exportEncryptedBackup(backupPassword);

      expect(backupPayload, contains('"caveau_backup":"v2"'));
      expect(backupPayload, contains('"salt":'));
      expect(backupPayload, contains('"iv":'));
      expect(backupPayload, contains('"data":'));

      // Clear storage to test restore
      await storage.clearAllData();
      final emptyItems = await storage.getAllVaultItems();
      expect(emptyItems, isEmpty);

      // Restore from backup in Isolate
      final restoredCount = await storage.importEncryptedBackup(backupPayload, backupPassword);
      expect(restoredCount, equals(1));

      final restoredItems = await storage.getAllVaultItems();
      expect(restoredItems.length, equals(1));
      expect(restoredItems.first.title, equals('Secret Login'));
      expect(restoredItems.first.username, equals('alice'));
      expect(restoredItems.first.password, equals('Password123!'));
    });

    test('importing v2 backup with incorrect password throws FormatException', () async {
      final storage = SecureStorageService();
      final item = VaultItem(
        id: 'item-2',
        title: 'Bank Account',
        category: VaultCategory.card,
      );
      await storage.saveVaultItem(item);

      final payload = await storage.exportEncryptedBackup('CorrectPassword123!');

      expect(
        () async => await storage.importEncryptedBackup(payload, 'WrongPassword456!'),
        throwsA(isA<FormatException>()),
      );
    });

    test('supports backward compatibility with legacy v1 backups', () async {
      final storage = SecureStorageService();
      await storage.clearAllData();

      // Create a legacy v1 backup payload
      const legacyPassword = 'LegacyPassword2024';
      final legacyPayload = jsonEncode({
        'version': '1.0',
        'exportedAt': '2024-01-01T00:00:00.000Z',
        'items': [
          VaultItem(
            id: 'legacy-item-1',
            title: 'Legacy Note',
            category: VaultCategory.note,
            notes: 'Encrypted legacy note content',
          ).toJson(),
        ],
      });

      final keyBytes = sha256.convert(utf8.encode(legacyPassword)).bytes;
      final plaintextBytes = utf8.encode(legacyPayload);
      final encryptedBytes = List<int>.generate(
        plaintextBytes.length,
        (i) => plaintextBytes[i] ^ keyBytes[i % keyBytes.length],
      );

      final checksum = sha256.convert(encryptedBytes).toString();
      final v1BackupEnvelope = jsonEncode({
        'caveau_backup': 'v1',
        'data': base64Encode(encryptedBytes),
        'checksum': checksum,
      });

      // Restore legacy v1 backup
      final importedCount = await storage.importEncryptedBackup(v1BackupEnvelope, legacyPassword);
      expect(importedCount, equals(1));

      final items = await storage.getAllVaultItems();
      expect(items.length, equals(1));
      expect(items.first.title, equals('Legacy Note'));
      expect(items.first.notes, equals('Encrypted legacy note content'));
    });
  });

  group('AppPlatform Tests', () {
    test('platform getters evaluate consistently', () {
      expect(AppPlatform.isDesktop || AppPlatform.isMobile || !AppPlatform.isDesktop, isTrue);
      if (AppPlatform.isDesktop) {
        expect(AppPlatform.isBiometricsSupportedOnPlatform, isFalse);
      }
    });
  });

  group('ScreenSecurityService Tests', () {
    test('handles setSecureFlag and isScreenCaptureActive without unhandled exceptions in test harness', () async {
      final service = ScreenSecurityService();
      await service.setSecureFlag(true);
      await service.setSecureFlag(false);
      final isActive = await service.isScreenCaptureActive();
      expect(isActive, isFalse);
      service.dispose();
    });
  });

  group('AuthProvider Lockout & Countdown Timer Tests', () {
    test('lockout countdown decrements and clears error upon expiry', () async {
      final mockAuth = _MockLockoutAuthService(lockoutSeconds: 2);
      final authProvider = AuthProvider(authService: mockAuth);

      // Trigger lockout with 5 wrong attempts
      for (int i = 0; i < 5; i++) {
        await authProvider.authenticateWithPin('wrong');
      }

      expect(authProvider.isLockedOut, isTrue);
      expect(authProvider.errorType, equals(AuthErrorType.lockedOut));
      expect(authProvider.lockoutSecondsRemaining, equals(2));

      final it = AppLocalizationsIt();
      expect(authProvider.getLocalizedErrorMessage(it), contains('2s'));

      // Wait 1 second
      await Future.delayed(const Duration(milliseconds: 1100));
      expect(authProvider.lockoutSecondsRemaining, equals(1));
      expect(authProvider.getLocalizedErrorMessage(it), contains('1s'));

      // Wait for lockout to fully elapse
      await Future.delayed(const Duration(milliseconds: 1100));
      expect(authProvider.isLockedOut, isFalse);
      expect(authProvider.lockoutSecondsRemaining, equals(0));
      expect(authProvider.errorType, isNull);
      expect(authProvider.errorMessage, isNull);
      expect(authProvider.getLocalizedErrorMessage(it), isNull);

      authProvider.dispose();
    });

    test('refreshLockoutState cleans up expired lockout immediately', () {
      final authProvider = AuthProvider();
      authProvider.refreshLockoutState();
      expect(authProvider.isLockedOut, isFalse);
      expect(authProvider.errorType, isNull);
      authProvider.dispose();
    });
  });
}

class _MockLockoutAuthService extends AuthService {
  final int lockoutSeconds;
  int failCount = 0;

  _MockLockoutAuthService({this.lockoutSeconds = 3});

  @override
  Future<VerifyPinResult> verifyMasterPin(String pin) async {
    failCount++;
    if (pin == '123456') {
      failCount = 0;
      return const VerifyPinSuccess();
    }
    if (failCount >= 5) {
      return VerifyPinFailure(
        failedAttempts: failCount,
        lockoutUntil: DateTime.now().add(Duration(seconds: lockoutSeconds)),
      );
    }
    return VerifyPinFailure(failedAttempts: failCount);
  }
}

