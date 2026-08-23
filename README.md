# Caveau

[🇮🇹 Italiano](#-italiano) | [🇬🇧 English](#-english)

---

## 🇮🇹 Italiano

### Cos'è Caveau

Caveau è una cassaforte digitale personale progettata per funzionare al 100% offline su smartphone (Android, iOS) e computer (Windows, macOS, Linux).

Permette di custodire in un unico posto sicuro tutte le tue password, carte di pagamento, appunti riservati, documenti d'identità e chiavi di accesso.

Nessun dato viene mai inviato su internet o salvato su server remoti: tutto rimane memorizzato e protetto esclusivamente all'interno del tuo dispositivo. Non ci sono account online da registrare, né abbonamenti da pagare, né sistemi di tracciamento pubblicitario.

---

### Funzionalità Principali

- **Completamente Offline e Riservato**: Funziona senza connessione internet. I tuoi dati non lasciano mai il tuo telefono o computer.
- **Protezione con Crittografia Hardware**: I dati sono protetti dai sistemi di sicurezza integrati del dispositivo, gli stessi utilizzati dalle applicazioni bancarie.
- **Accesso Semplice e Immediato**:
  - Su Smartphone e Tablet: Sblocco veloce tramite impronta digitale o riconoscimento facciale, con codice PIN di sicurezza di supporto.
  - Su Computer (PC): Accesso immediato tramite PIN Master da tastiera (basta digitare il PIN e premere Invio).
- **Cosa Puoi Custodire**:
  - Password e Credenziali di accesso (con nome utente, password, indirizzo del sito e campi personalizzati).
  - Carte di Pagamento (con numero della carta, data di scadenza, codice di sicurezza e anteprima visiva).
  - Note Protette (appunti riservati, codici segreti e testi personali).
  - Documenti d'Identità (dati di carte d'identità, patenti e passaporti).
  - Token API e Chiavi di Accesso (per sviluppatori e professionisti IT).
- **Protezione Privacy dello Schermo**: Quando cambi applicazione, la schermata di Caveau si offusca istantaneamente per impedire a sguardi indiscreti o screenshot accidentali di visualizzare i tuoi dati.
- **Blocco Automatico e Pulizia Appunti**: Se lasci l'applicazione incustodita, si blocca da sola dopo un tempo configurabile. Le password copiate negli appunti vengono eliminate automaticamente dopo pochi secondi.
- **Generatore di Password e Analisi Sicurezza**: Crea password robuste, lunghe e difficili da indovinare, e controlla l'intero archivio segnalando password deboli o utilizzate più volte.
- **Backup Cifrato e Portabile**: Puoi esportare una copia di sicurezza protetta da password per trasferire i tuoi dati su un altro dispositivo o conservarli al sicuro.
- **Supporto Multilingua**: Disponibile nativamente in 5 lingue (Italiano, Inglese, Spagnolo, Francese e Tedesco).

---

### Struttura del Progetto

Il codice sorgente è organizzato secondo un'architettura modulare e pulita:

```text
lib/
├── main.dart        # Punto di avvio dell'app e monitoraggio dello stato di attività
├── core/            # Servizi di sicurezza (crittografia, PIN, appunti), costanti e traduzioni
├── models/          # Definizione dei dati (elementi della cassaforte, impostazioni)
├── providers/       # Gestione dello stato dell'app (autenticazione, filtri e ricerca)
└── views/           # Interfaccia grafica (schermate mobile e vista a 3 colonne per PC)
```

- **Linguaggio e Framework**: Flutter (Dart SDK `^3.9.2`)
- **Gestione dello Stato**: `provider`
- **Crittografia e Sicurezza**: `flutter_secure_storage`, `local_auth`, `pointycastle`, `crypto`
- **Stile Grafico**: Material 3 Scuro (Sfondo Ossidiana, Accenti Indaco e Smeraldo)

---

### Requisiti e Come Avviarlo

#### Prerequisiti
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installato sul computer (Dart SDK >= 3.9)
- Per PC Windows: Visual Studio con i carichi di lavoro C++ per Desktop
- Per Smartphone Android: Android Studio e un emulatore o dispositivo collegato
- Per Smartphone iOS o Mac: Xcode (su ambiente macOS)

#### Installazione e Avvio Rapido

1. **Clona la cartella del progetto:**
   ```bash
   git clone https://github.com/stiavelli21/Caveau.git
   cd Caveau
   ```

2. **Scarica le dipendenze necessarie:**
   ```bash
   flutter pub get
   ```

3. **Avvia l'applicazione:**
   - Su PC Windows:
     ```bash
     flutter run -d windows
     ```
   - Su Smartphone (Android / iOS):
     ```bash
     flutter run
     ```

4. **Creare i pacchetti di installazione:**
   - File APK per Android:
     ```bash
     flutter build apk --release
     ```
   - Eseguibile per Windows:
     ```bash
     flutter build windows --release
     ```

---

### Note su Sicurezza e Piattaforme

- **Desktop (Windows, macOS, Linux)**: Per scelta progettuale, l'accesso su PC non utilizza sensori biometrici ma avviene esclusivamente tramite il PIN Master, offrendo un'esperienza ottimizzata per la tastiera.
- **Android**: È attiva la protezione a livello di sistema operativo contro registrazioni dello schermo e screenshot non autorizzati (`FLAG_SECURE`). Il backup automatico del sistema operativo è disabilitato (`allowBackup="false"`) per impedire estrazioni esterne non cifrate.
- **iOS**: È configurata la richiesta di autorizzazione per Face ID e Touch ID nel file di configurazione (`Info.plist`).

---

### Licenza

Progetto distribuito per uso personale e open-source. Consulta i file del repository per maggiori dettagli.

---

## 🇬🇧 English

### What is Caveau

Caveau is an open-source, personal digital vault engineered to run 100% offline across smartphones (Android, iOS) and computers (Windows, macOS, Linux).

It allows you to securely store and organize all your passwords, payment cards, confidential notes, identity documents, and API tokens in a single protected place.

No data is ever transmitted across the internet or stored on remote cloud servers: everything remains encrypted exclusively on your local device. There are no user accounts to register, no subscriptions, and zero analytics or tracking.

---

### Key Features

- **100% Offline & Private**: Operates without requiring an internet connection. Your sensitive data never leaves your device.
- **Hardware-Backed Encryption**: Data is protected by your device's built-in secure storage mechanisms, following the same security standards used by modern banking apps.
- **Fast & Protected Access**:
  - On Mobile (Android, iOS): Fast unlock via fingerprint or facial recognition, with an encrypted Master PIN fallback.
  - On Desktop (Windows, macOS, Linux): Dedicated keyboard-friendly access using the Master PIN (type your PIN and hit Enter).
- **Supported Vault Items**:
  - Passwords & Logins (username, password, website URL, and custom fields).
  - Payment Cards (card number, expiration date, security code, and visual card preview).
  - Secure Notes (confidential notes, recovery keys, and private texts).
  - Identity Documents (ID cards, driver licenses, and passports).
  - API Tokens & Secret Keys (for developers and technical workflows).
- **Privacy Shield**: Automatically obscures and blurs the screen whenever you switch applications, preventing shoulder surfing and unauthorized screenshots.
- **Auto-Lock & Clipboard Auto-Clear**: Automatically locks the vault after an inactivity timeout. Any sensitive data copied to your clipboard is automatically erased after a short duration.
- **Password Generator & Security Audit**: Generates high-entropy passwords and evaluates your vault to highlight weak or reused credentials.
- **Encrypted Portable Backup**: Export and import password-protected backup files to transfer your vault to another device safely.
- **Multi-Language Support**: Native support for 5 languages (English, Italian, Spanish, French, and German).

---

### Project Structure

The source code follows a clean and modular architecture:

```text
lib/
├── main.dart        # Application entry point, provider registration, and lifecycle observer
├── core/            # Cryptographic services (storage, auth, clipboard), constants, and localization
├── models/          # Data models (vault items, security preferences, custom fields)
├── providers/       # State management (authentication, vault search/filters, settings)
└── views/           # User interface (mobile screens and 3-column desktop split view)
```

- **Framework**: Flutter (Dart SDK `^3.9.2`)
- **State Management**: `provider`
- **Security & Storage**: `flutter_secure_storage`, `local_auth`, `pointycastle`, `crypto`
- **Design System**: Material 3 Dark (Obsidian Background, Indigo & Emerald Accents)

---

### Prerequisites & Quick Start

#### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed on your system (Dart SDK >= 3.9)
- For Windows Desktop: Visual Studio with Desktop development with C++
- For Android: Android Studio with an active emulator or connected device
- For iOS / macOS: Xcode (on macOS)

#### Installation & Quick Start

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
   - On Desktop (e.g. Windows):
     ```bash
     flutter run -d windows
     ```
   - On Mobile (e.g. Android / iOS):
     ```bash
     flutter run
     ```

4. **Build release packages:**
   - Android APK:
     ```bash
     flutter build apk --release
     ```
   - Windows Executable:
     ```bash
     flutter build windows --release
     ```

---

### Platform & Security Notes

- **Desktop (Windows, macOS, Linux)**: Biometric authentication is intentionally disabled by design. Access is governed exclusively via the Master PIN with keyboard-centric interactions.
- **Android**: Operating system-level screen protection (`FLAG_SECURE`) is enabled to block unauthorized screenshots and screen recording. Automatic OS backups are disabled (`android:allowBackup="false"`) to prevent unencrypted cloud extraction.
- **iOS**: Configured with the required `NSFaceIDUsageDescription` key in `Info.plist` for authorized biometric sensor access.

---

### License

Distributed for personal and open-source use. See repository files for more details.
