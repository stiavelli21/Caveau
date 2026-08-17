# Caveau

**Caveau** è un password manager e digital vault mobile, sviluppato in **Flutter**, progettato secondo il paradigma **Zero-Knowledge** e **100% Offline**. Cifra e protegge localmente credenziali di accesso, carte di pagamento, note segrete, documenti d'identità e token API senza mai trasmettere alcun dato in rete.

---

## Caratteristiche Principali

- **Zero-Knowledge & 100% Offline**: Nessun server remoto, nessun account cloud e nessun tracciamento. I dati risiedono unicamente all'interno del dispositivo.
- **Cifratura Hardware-Backed**: Archiviazione sicura tramite `flutter_secure_storage`, sfruttando **Android Keystore (AES-256)** e **iOS Keychain con Secure Enclave**.
- **Autenticazione Ibrida**: Accesso biometrico rapido (Face ID, Touch ID, impronta digitale) con fallback su **Master PIN** (hashing a 5.000 round SHA-256 + salt a 256-bit) e protezione anti-brute force con blocco progressivo.
- **Privacy Shield**: Oscuramento e sfocatura istantanea dell'app quando passa in background o nell'app switcher del sistema operativo per prevenire screenshot e visualizzazioni accidentali.
-  **Auto-Lock & Auto-Clearing Clipboard**: Blocco automatico della sessione per inattività e cancellazione automatica dei dati sensibili copiati negli appunti dopo un intervallo configurabile (default 30s).
- **Categorie Supportate**:
  - **Login / Credenziali** (username, password, URL, campi personalizzati)
  - **Carte di Pagamento** (con interfaccia mockup interattiva)
  - **Note Sicure** (crittografate a tutto schermo)
  - **Identità & Documenti**
  - **Token API & Chiavi Segrete**
- **Generatore di Password & Entropia**: Generatore crittografico configurabile con stima dell'entropia (bit) e livello di robustezza.
- **Security Audit**: Dashboard per il monitoraggio della salute del vault, con identificazione automatica di password deboli, duplicate o compromesse e calcolo del punteggio complessivo di sicurezza.
- **Backup & Ripristino Cifrati**: Esportazione sicura del vault cifrato con password utente e verifica di integrità tramite checksum SHA-256.

---

## Architettura & Stack Tecnologico

Il progetto adotta un pattern **Clean Architecture / MVVM** con gestione reattiva dello stato tramite **Provider**:

```text
lib/
├── core/            # Servizi crittografici (Auth, Storage, Clipboard), costanti e tema Dark Cyber
├── models/          # Modelli dati (VaultItem, SecuritySettings, CustomField)
├── providers/       # State management (AuthProvider, VaultProvider, SettingsProvider)
└── views/           # UI Material 3 (Auth, Vault, Generatore, Audit, Impostazioni, Widget)
```

- **Framework**: [Flutter](https://flutter.dev) (Dart SDK `^3.9.2`)
- **State Management**: `provider`
- **Sicurezza & Biometria**: `flutter_secure_storage`, `local_auth`, `crypto`
- **Design System**: Material 3 Dark Cyber (Obsidian `#0B0F19`, Indigo `#6366F1`, Emerald `#10B981`)

---

## Prerequisiti & Avvio Rapido

### Prerequisiti
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (versione compatibile con Dart >= 3.9)
- Android Studio / Xcode per l'esecuzione su emulatore o dispositivo fisico

### Installazione

1. **Clona il repository:**
   ```bash
   git clone https://github.com/stiavelli21/Caveau.git
   cd Caveau/caveau
   ```

2. **Installa le dipendenze:**
   ```bash
   flutter pub get
   ```

3. **Avvia l'applicazione:**
   ```bash
   flutter run
   ```

4. **Compilazione Release (APK Android):**
   ```bash
   flutter build apk --release
   ```

---

## Sicurezza & Note Piattaforma

- **Android**: L'activity principale estende `FlutterFragmentActivity` per il supporto biometrico e il backup automatico di sistema è disabilitato (`android:allowBackup="false"` in `AndroidManifest.xml`) per impedire estrazioni non autorizzate.
- **iOS**: Configurato con chiave `NSFaceIDUsageDescription` in `Info.plist` per l'accesso autorizzato ai sensori biometrici Face ID.

---

## Licenza

Progetto distribuito ad uso personale e open source. Consultare i dettagli del repository per ulteriori informazioni.
