# Caveau

**Caveau** is an open-source cross-platform password manager and digital vault built with **Flutter**, designed around a **Zero-Knowledge** and **100% Offline** architecture for **Mobile (Android, iOS)** and **Desktop / PC (Windows, macOS, Linux)**. It locally encrypts and protects credentials, payment cards, secure notes, identity documents, and API tokens without ever transmitting any data over the network.

---

## Key Features

- **Zero-Knowledge & 100% Offline**: No remote servers, no cloud accounts, and no telemetry tracking. All data resides exclusively on the local device.
- **Hardware-Backed Encryption**: Secure storage powered by `flutter_secure_storage`, leveraging **Android Keystore (AES-256)**, **iOS Keychain with Secure Enclave isolation**, and desktop secure storage keychains.
- **Platform-Tailored Authentication**:
  - **Mobile (Android, iOS)**: Fast biometric access (Face ID, Touch ID, fingerprint) with fallback to an encrypted **Master PIN** (200,000 rounds of iterative SHA-256 key stretching + 256-bit salt), progressive lockout, and auto-wipe after 8 consecutive failed attempts.
  - **Desktop / PC (Windows, macOS, Linux)**: Biometrics disabled by design; access is managed **exclusively via the Master PIN** with keyboard-friendly interactions (instant focus and Enter-to-unlock).
- **Adaptive Multi-Form Factor UI**:
  - **Desktop Widescreen (Width ≥ 900px)**: 3-column horizontal Master-Detail Split-View featuring a persistent navigation sidebar with real-time category counters, a searchable master list, and a live decrypted detail pane. Utility screens (Password Generator and Security Audit) render in 2-column widescreen layouts.
  - **Mobile (Width < 900px)**: Streamlined single-column mobile interface with gesture navigation (swipe-to-back), compact Floating Action Button, and full-screen detail views.
- **Privacy Shield**: Instant app blurring and obscuration when transitioning to the background or OS app switcher to prevent unintended visibility and screenshots.
- **Auto-Lock & Auto-Clearing Clipboard**: Configurable session timeout on inactivity and automatic clipboard clearing for copied sensitive data (default: 30s).
- **Multi-Language Support (5 Languages)**: Native support for **English (`en`)**, **Italian (`it`)**, **Spanish (`es`)**, **French (`fr`)**, and **German (`de`)** with runtime language switching from the lock screen, settings, and desktop sidebar.
- **Supported Categories**:
  - **Logins & Credentials** (username, password, URL, custom fields)
  - **Payment Cards** (with interactive visual card mockup)
  - **Secure Notes** (fullscreen encrypted notes)
  - **Identities & Documents**
  - **API Tokens & Secret Keys**
- **Password Generator & Entropy**: Cryptographically secure generator with real-time entropy estimation (bits) and strength scoring.
- **Security Audit**: Vault health monitoring dashboard with automatic detection of weak or reused passwords and overall security scoring.
- **Encrypted Backup & Restore**: Password-protected vault export/import using **AES-256-GCM** authenticated encryption and **PBKDF2-HMAC-SHA256** key derivation (600,000 rounds), with backward compatibility for legacy backups.

---

## Architecture & Tech Stack

The project follows a **Clean Architecture / MVVM** pattern with reactive state management via **Provider**:

```text
lib/
├── main.dart        # Entry point, MultiProvider registration & AppLifecycleObserver
├── core/            # Cryptographic services (Auth, Storage, Clipboard), constants, localization & theme
├── models/          # Data models (VaultItem, SecuritySettings, CustomField)
├── providers/       # State management (AuthProvider, VaultProvider, SettingsProvider)
└── views/           # Material 3 UI (Auth, Vault, Generator, Audit, Settings, Widgets, Desktop Layouts)
```

- **Framework**: [Flutter](https://flutter.dev) (Dart SDK `^3.9.2`)
- **State Management**: `provider`
- **Security & Biometrics**: `flutter_secure_storage`, `local_auth`, `pointycastle`, `crypto`
- **Design System**: Material 3 Dark Cyber (Obsidian `#0B0F19`, Indigo `#6366F1`, Emerald `#10B981`)

---

## Prerequisites & Quick Start

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (version compatible with Dart >= 3.9)
- Android Studio / Xcode for running on mobile emulators or physical devices
- Visual Studio / Desktop C++ toolchain for running desktop builds (Windows / macOS / Linux)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/stiavelli21/Caveau.git
   cd Caveau
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the application:**
   - **On Desktop (e.g., Windows):**
     ```bash
     flutter run -d windows
     ```
   - **On Mobile (e.g., Android / iOS):**
     ```bash
     flutter run
     ```

4. **Build Release Packages:**
   - **Android APK:**
     ```bash
     flutter build apk --release
     ```
   - **Windows Executable:**
     ```bash
     flutter build windows --release
     ```

---

## Platform & Security Notes

- **Desktop (Windows / macOS / Linux)**: Biometric authentication is intentionally disabled. Users authenticate exclusively with their Master PIN. Hardware-backed secure storage encrypts data in local credential lockers.
- **Android**: The main activity extends `FlutterFragmentActivity` for biometric authentication support, and system backup is disabled (`android:allowBackup="false"` in `AndroidManifest.xml`) to prevent unauthorized data extraction.
- **iOS**: Configured with the `NSFaceIDUsageDescription` key in `Info.plist` for authorized access to Face ID biometric sensors.

---

## License

This project is distributed for personal and open-source use. See repository details for more information.
