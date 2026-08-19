# AGENTS.md - Architectural Guide for AI Agents

This document provides AI agents (and developers) with a comprehensive overview of how **Caveau** operates, its architectural decisions, and the code organization within the `lib/` directory.

---

## Application Overview

**Caveau** is a mobile application developed in **Flutter** for the local, secure, and offline storage of credentials, passwords, payment cards, encrypted notes, identity documents, and API tokens.

### Fundamental Operating Principles
1. **Zero-Knowledge & 100% Offline**: No data is transmitted over the network or saved on remote servers. All data resides strictly on the local device.
2. **Hardware-Backed Encryption**: Utilizes the `flutter_secure_storage` package to encrypt data leveraging the **Android Keystore** (with AES-256) and the **iOS Keychain** with Secure Enclave isolation (`first_unlock_this_device`).
3. **Hybrid Authentication (`local_auth`)**: Supports biometric sensors (Face ID, Touch ID, fingerprint) with fallback to an encrypted Master PIN (5,000 rounds of iterative SHA-256 hashing + 256-bit salt) and progressive anti-brute-force protection.
4. **OS Protection & Privacy**:
   - **Privacy Shield**: Immediate screen obscuration during OS multitasking/app switching via a blur overlay filter.
   - **Auto-Lock**: Configurable automatic session locking upon leaving the app or following inactivity.
   - **Auto-Clearing Clipboard**: Automatic clearing of sensitive data copied to the clipboard after a set timer (default: 30s).
5. **Native 5-Language Multilingual Support**:
   - Out-of-the-box support for **English (`en`)**, **Italian (`it`)**, **Spanish (`es`)**, **French (`fr`)**, and **German (`de`)**.
   - Dynamic language switching during initial authentication (`LockScreen` and `OnboardingScreen`) as well as from settings (`SettingsScreen`).

---

## Architecture of the `lib/` Directory

The project architecture follows the **Clean Architecture / MVVM** pattern with reactive state management using `provider`:

```
lib/
├── main.dart                      # Entry point, Provider registration, AppLifecycleObserver, intl date initialization
├── core/                          # Constants, low-level services, utilities, and localization
│   ├── constants/
│   │   ├── app_brand_terms.dart   # Immutable brand terms and technical standards (Caveau, PIN, Face ID, etc.)
│   │   ├── app_colors.dart        # Cyber-dark color palette (Obsidian, Indigo, Emerald)
│   │   └── app_theme.dart         # Material 3 Dark Theme configuration
│   ├── localization/
│   │   └── app_localizations.dart # Type-safe translation system (IT, EN, ES, FR, DE) and BuildContext.l10n extension
│   ├── services/
│   │   ├── auth_service.dart      # Biometric wrapper (local_auth) and Master PIN hash/salt logic
│   │   ├── secure_storage_service.dart # Wrapper for flutter_secure_storage, CRUD, and encrypted backup
│   │   ├── screen_security_service.dart # Platform channel for Android FLAG_SECURE & iOS capture detection
│   │   └── clipboard_service.dart # Secure clipboard copy with auto-clear timer
│   └── utils/
│       └── password_generator.dart# Cryptographic password generator, entropy and strength calculation
├── models/                        # Domain models and JSON serialization
│   ├── vault_item.dart            # Vault item model (Login, Card, Note, Identity, API)
│   └── security_settings.dart     # Security preferences (auto-lock, biometrics, privacy, languageCode)
├── providers/                     # State Management (ChangeNotifier)
│   ├── auth_provider.dart         # Authentication state (setup, locked, authenticated, lockout)
│   ├── vault_provider.dart        # Item management, filters, search, favorites, audit score
│   └── settings_provider.dart     # Security & language settings management and persistence
└── views/                         # Graphical user interface (UI / Screens and reusable widgets)
    ├── auth/
    │   ├── lock_screen.dart       # Unlock screen with language selector (Biometrics / Master PIN)
    │   └── onboarding_screen.dart # Initial Master PIN creation with language selector
    ├── vault/
    │   ├── vault_home_screen.dart # Main dashboard, item list, search, and category chips
    │   ├── vault_detail_screen.dart # Detail view with visibility toggle and credit card mockup
    │   └── vault_editor_screen.dart # Item creation/edit form with integrated password generator
    ├── generator/
    │   └── password_generator_screen.dart # Dedicated utility screen for generating complex passwords
    ├── security/
    │   └── security_audit_screen.dart # Audit dashboard analyzing weak and reused passwords
    ├── settings/
    │   └── settings_screen.dart   # PIN management, language selection, encrypted backup, and data wipe
    └── widgets/
        ├── language_selector_button.dart # Button and modal bottom sheet for quick language switching
        ├── password_strength_bar.dart # Visual indicator for password strength
        ├── privacy_shield.dart    # Protective blur overlay for multitasking privacy
        ├── swipe_back_wrapper.dart # Swipe-from-left gesture recognizer to navigate back
        └── vault_card.dart        # Vault item list card with quick-copy actions
```

---

## Detailed Component Overview

### 1. `core/` (Cross-Cutting Logic, Localization, and Services)
- **`constants/`**:
  - `app_brand_terms.dart`: Centralizes invariant brand terms, acronyms, and tech standards (`Caveau`, `PIN`, `Master PIN`, `PIN Master`, `Face ID`, `Touch ID`, `Android Keystore`, `iOS Keychain`, `API Key`, `AES-256`, `SHA-256`, `CVV`, `URL`, `Email`).
  - `app_colors.dart`: Defines UI color constants (Background `#0B0F19`, Surface `#131B2E`, Accents `#6366F1` and `#10B981`).
  - `app_theme.dart`: Centralizes Material 3 dark theme styling, button styles, input fields, cards, and app bars.
- **`localization/`**:
  - `app_localizations.dart`: Abstract interface `AppLocalizations` and full implementations `AppLocalizationsIt`, `AppLocalizationsEn`, `AppLocalizationsEs`, `AppLocalizationsFr`, `AppLocalizationsDe`. Provides the `_AppLocalizationsDelegate`, metadata for supported languages (`supportedLanguages`), and the `context.l10n` extension.
- **`services/`**:
  - `secure_storage_service.dart`: Secure wrapper around `FlutterSecureStorage`. Handles ID indexing, encrypted record storage, password-protected backup export, and SHA-256 checksum-verified import.
  - `auth_service.dart`: Interfaces with `local_auth` for biometrics, generates cryptographic random salts, and computes iterative Master PIN hashes to defend against dictionary attacks.
  - `screen_security_service.dart`: Interfaces with native platform channels to enforce `FLAG_SECURE` (blacking out Android screen recordings and blocking screenshots) and monitor iOS `UIScreen.capturedDidChangeNotification` to automatically trigger `PrivacyShield`.
  - `clipboard_service.dart`: Manages clipboard operations by launching a `Timer` to clear sensitive contents after a specified duration (default 30s) if the clipboard still contains the copied value.
- **`utils/`**:
  - `password_generator.dart`: Generates configurable high-entropy passwords (uppercase, lowercase, numbers, symbols, ambiguous character exclusion such as `Il1O0`) and calculates strength based on bit entropy.

### 2. `models/` (Data & Structures)
- **`vault_item.dart`**: Polymorphic `VaultItem` model supporting:
  - Categories: `login`, `card`, `note`, `identity`, `apiKey`.
  - Standard fields and dynamic `CustomField` list (custom fields with `isSecret` flag).
  - Methods: `toJson()`, `fromJson()`, `serialize()`, and `deserialize()`.
- **`security_settings.dart`**: Model storing user security preferences: auto-lock timeout (0s, 30s, 60s, 300s), biometrics enabled, privacy shield enabled, clipboard timeout, failed attempt lockout state, and language preference (`languageCode`: `'it'`, `'en'`, `'es'`, `'fr'`, `'de'`).

### 3. `providers/` (State Management)
- **`auth_provider.dart`**: Manages `AuthStatus` (`initial`, `setupRequired`, `locked`, `authenticated`), tracks failed login attempts, and enforces cooldown lockout periods.
- **`vault_provider.dart`**: Holds the decrypted in-memory vault items when authenticated. Provides computed getters for search, category filtering, favorites, weak/reused password audits, and calculates `securityScore` (0-100%).
- **`settings_provider.dart`**: Loads and updates security settings and active language in real time with persistence in secure storage (`updateLanguage`).

### 4. `views/` (User Interface)
- **`auth/`**: First-launch setup (`OnboardingScreen`) and regular unlock (`LockScreen`), both equipped with `LanguageSelectorButton` for instant language switching.
- **`vault/`**:
  - `VaultHomeScreen`: Main dashboard featuring search bar, category chips, counters, and item list.
  - `VaultDetailScreen`: Detailed item view with reveal/hide secrets toggle, quick copy, and visual credit card mockup rendering.
  - `VaultEditorScreen`: Add/Edit form with validation and quick shortcut to the password generator.
- **`generator/` & `security/`**:
  - `PasswordGeneratorScreen`: Dedicated utility screen for testing and generating customized passwords.
  - `SecurityAuditScreen`: Vault health monitoring dashboard for identifying and resolving vulnerabilities (weak or duplicate passwords).
- **`settings/`**: PIN management, language selection (`LINGUA / LANGUAGE`), security toggles, encrypted backup export/import, and total data wipe.
- **`widgets/`**: Reusable UI components (`LanguageSelectorButton`, `PrivacyShield`, `VaultCard`, `PasswordStrengthBar`).

### 5. `main.dart`
- Initializes core services, `intl` date formatting locales (`it_IT`, `en_US`, `es_ES`, `fr_FR`, `de_DE`), and registers providers using `MultiProvider` in `CaveauRoot`.
- Configures `MaterialApp` with `locale: Locale(settings.languageCode)` and `localizationsDelegates`.
- Implements `WidgetsBindingObserver` to monitor app lifecycle states (`paused`, `inactive`, `resumed`), instantly triggering `PrivacyShield` and calculating elapsed background time for auto-lock enforcement.

---

## Development & Security Rules for AI Agents

When modifying or extending this application, you must **ALWAYS strictly adhere to the following rules**:

### 1. Mandatory Multilingual Localization Rule
- **No hardcoded strings**: Hardcoded strings, labels, placeholders, or error messages directly in Dart UI code (e.g., `'Enter your PIN'`) are strictly prohibited.
- **Mandatory translation in all 5 languages**: Any new string or UI label must be declared in the abstract `AppLocalizations` interface and implemented across **all 5 language classes**:
  1. `AppLocalizationsIt` (Italian)
  2. `AppLocalizationsEn` (English)
  3. `AppLocalizationsEs` (Spanish)
  4. `AppLocalizationsFr` (French)
  5. `AppLocalizationsDe` (German)
- **Type-Safe Access**: Always access localized strings via `context.l10n.<property>` within widgets.
- **Usage of `AppBrandTerms`**: For invariant brand terms, acronyms, and technological standards (`Caveau`, `PIN`, `Master PIN`, `PIN Master`, `Face ID`, `Touch ID`, `Android Keystore`, `iOS Keychain`, `API Key`, `AES-256`, `SHA-256`, `CVV`, `URL`, `Email`), always reference `AppBrandTerms` constants (e.g., `${AppBrandTerms.appName}`, `${AppBrandTerms.pinMaster}`).

### 2. Cryptography & Security Rules
- **Never store sensitive data in plaintext** or in unencrypted stores like standard `SharedPreferences`. Always use `SecureStorageService`.
- **Android Activity**: Ensure `MainActivity` inherits from `FlutterFragmentActivity` (required for biometric authentication via `local_auth` on Android).
- **Do not remove native permissions or security configurations**:
  - `android:allowBackup="false"` in `AndroidManifest.xml` (prevents unauthorized data extraction through OS backups).
  - `NSFaceIDUsageDescription` in `ios/Runner/Info.plist`.
- **Maintain clear separation between UI and Cryptography**: Hashing, encryption, and key derivation logic must remain isolated within `services/`.
- **Verify with Tests**: Following any change to logic or localized texts, ensure that the entire `flutter test` test suite is updated and passes 100%.

### 3. Absolute Caution & Backward Compatibility for Backups and Exports
- **Critical Attention to Changes**: Treat any modifications to backup export (`exportEncryptedBackup`), import (`importEncryptedBackup`), or model serialization (`VaultItem.toJson` / `fromJson`) with extreme care.
- **Strict Prohibition of Breaking Existing Backups**: No code changes may invalidate or break compatibility with backup files generated by earlier versions of the app. Breaking backward compatibility causes irreversible data loss for users restoring historical backups.
- **Versioning and Backward-Compatible Migrations**:
  - If the payload structure, JSON envelope, or encryption strategy evolves, increment the version identifier (e.g., `'caveau_backup': 'v2'`) while ensuring `importEncryptedBackup` retains complete support for legacy formats (e.g., `'v1'`).
  - Adding or modifying fields in `VaultItem` must be resilient, providing sensible fallbacks/default values in `fromJson` to prevent exceptions when parsing older data.
  - Do not alter integrity verification methods (such as SHA-256 checksums) for legacy formats without maintaining backward compatibility.
- **Mandatory Regression Testing**: Whenever storage or backup modules are touched, verify through automated tests that both newly exported backups and legacy backup files can be imported accurately without data loss.
