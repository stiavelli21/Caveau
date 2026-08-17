# AGENTS.md - Guida Architetturale per Agenti AI

Questo documento fornisce agli agenti AI (e agli sviluppatori) una panoramica completa sul funzionamento di **Caveau**, sulle decisioni architetturali e sull'organizzazione del codice all'interno della cartella `lib/`.

---

## 🎯 Panoramica dell'Applicazione

**Caveau** è un'applicazione mobile sviluppata in **Flutter** per la memorizzazione locale, sicura e offline di credenziali, password, carte di pagamento, note crittografate e token API.

### Principi Fondamentali di Funzionamento
1. **Zero-Knowledge & 100% Offline**: Nessun dato viene trasmesso via rete o salvato su server remoti. Tutti i dati risiedono esclusivamente nel dispositivo.
2. **Hardware-Backed Encryption**: Utilizza il package `flutter_secure_storage` per cifrare i dati sfruttando l'**Android Keystore** (con AES-256) e l'**iOS Keychain** con isolamento Secure Enclave (`first_unlock_this_device`).
3. **Autenticazione Ibrida (`local_auth`)**: Supporta sensori biometrici (Face ID, Touch ID, impronta digitale) con fallback su Master PIN cifrato (hash iterativo a 5.000 round SHA-256 + salt a 256-bit) e protezione anti brute-force.
4. **Protezione OS & Privacy**:
   - **Privacy Shield**: Oscuramento immediato della schermata nel multitasking dell'OS tramite overlay con filtro blur.
   - **Auto-Lock**: Blocco automatico della sessione configurabile all'uscita o dopo inattività.
   - **Auto-Clearing Clipboard**: Cancellazione automatica dei dati sensibili copiati negli appunti dopo un timer (es. 30s).

---

## 📂 Architettura della Cartella `lib/`

La struttura del progetto segue il pattern **Clean Architecture / MVVM** con gestione dello stato reattiva tramite `provider`:

```
lib/
├── main.dart                      # Entry point, registrazione Provider, AppLifecycleObserver
├── core/                          # Costanti, servizi di basso livello e utility
│   ├── constants/
│   │   ├── app_colors.dart        # Palette cromatica cyber-dark (Obsidian, Indigo, Emerald)
│   │   └── app_theme.dart         # Configurazione Material 3 Dark Theme
│   ├── services/
│   │   ├── auth_service.dart      # Wrapper biometrico (local_auth) e logica hash/salt Master PIN
│   │   ├── secure_storage_service.dart # Wrapper flutter_secure_storage, CRUD e backup cifrato
│   │   └── clipboard_service.dart # Copia sicura con timer per svuotamento automatico appunti
│   └── utils/
│       └── password_generator.dart# Generatore crittografico, calcolo entropia e robustezza
├── models/                        # Modelli di dominio e serializzazione JSON
│   ├── vault_item.dart            # Modello elementi del vault (Login, Card, Note, Identità, API)
│   └── security_settings.dart     # Impostazioni di sicurezza (auto-lock, biometria, privacy)
├── providers/                     # State Management (ChangeNotifier)
│   ├── auth_provider.dart         # Stato autenticazione (setup, bloccato, sbloccato, lockout)
│   ├── vault_provider.dart        # Gestione elementi, filtri, ricerca, preferiti, audit score
│   └── settings_provider.dart     # Gestione e persistenza impostazioni di sicurezza
└── views/                         # Interfaccia grafica (UI / Schermate e Widget riutilizzabili)
    ├── auth/
    │   ├── lock_screen.dart       # Schermata di sblocco (Biometria / PIN Master)
    │   └── onboarding_screen.dart # Creazione Master PIN al primo avvio
    ├── vault/
    │   ├── vault_home_screen.dart # Dashboard principale, lista elementi, ricerca e filtri
    │   ├── vault_detail_screen.dart # Dettaglio con toggle visualizzazione e mockup carta
    │   └── vault_editor_screen.dart # Form creazione/modifica con generator integrato
    ├── generator/
    │   └── password_generator_screen.dart # Schermata utility per generare password complesse
    ├── security/
    │   └── security_audit_screen.dart # Analisi password deboli e riutilizzate
    ├── settings/
    │   └── settings_screen.dart   # Gestione PIN, backup cifrato e cancellazione dati
    └── widgets/
        ├── password_strength_bar.dart # Indicatore visivo della robustezza password
        ├── privacy_shield.dart    # Overlay protettivo per oscuramento multitasking
        └── vault_card.dart        # Card dell'elemento nella lista con quick copy
```

---

## 🔍 Dettaglio dei Componenti

### 1. `core/` (Logica Trasversale e Servizi)
- **`constants/`**:
  - `app_colors.dart`: Definisce le costanti colore della UI (sfondo `#0B0F19`, superfici `#131B2E`, accenti `#6366F1` e `#10B981`).
  - `app_theme.dart`: Centralizza il tema Material 3 scuro, stili dei bottoni, campi input, card e app bar.
- **`services/`**:
  - `secure_storage_service.dart`: Interfaccia sicura con `FlutterSecureStorage`. Gestisce l'indice degli ID, il salvataggio dei singoli record cifrati, l'esportazione di backup cifrati tramite password e l'importazione con verifica checksum SHA-256.
  - `auth_service.dart`: Interagisce con `local_auth` per la biometria, genera salt casuali crittografici e calcola l'hash iterativo del Master PIN per prevenire attacchi a dizionario.
  - `clipboard_service.dart`: Gestisce la copia negli appunti di sistema avviando un `Timer` per svuotare i dati dopo un tempo prestabilito (default 30s) se il contenuto corrisponde ancora a quello copiato.
- **`utils/`**:
  - `password_generator.dart`: Genera password ad alta entropia configurabili (maiuscole, minuscole, numeri, simboli, esclusione caratteri ambigui come `Il1O0`) e calcola la robustezza basandosi sull'entropia in bit.

### 2. `models/` (Dati e Strutture)
- **`vault_item.dart`**: Modello polimorfo `VaultItem` con supporto per:
  - Categorie: `login`, `card`, `note`, `identity`, `apiKey`.
  - Campi standard e lista di `CustomField` (campi personalizzati con flag `isSecret`).
  - Metodi `toJson()`, `fromJson()`, `serialize()` e `deserialize()`.
- **`security_settings.dart`**: Modello per memorizzare le preferenze dell'utente: timeout blocco (0s, 30s, 60s, 300s), abilitazione biometria, privacy shield, timeout clipboard e stato di lockout per tentativi falliti.

### 3. `providers/` (Gestione dello Stato)
- **`auth_provider.dart`**: Gestisce lo stato `AuthStatus` (`initial`, `setupRequired`, `locked`, `authenticated`), controlla i tentativi falliti e applica il cooldown temporale.
- **`vault_provider.dart`**: Mantiene in memoria la lista decifrata degli elementi del vault quando la sessione è autenticata. Fornisce computed getters per la ricerca, il filtro per categoria, i preferiti, l'elenco delle password deboli/riutilizzate e il calcolo del `securityScore` (0-100%).
- **`settings_provider.dart`**: Carica e aggiorna in tempo reale le impostazioni salvate nel secure storage.

### 4. `views/` (Interfaccia Utente)
- **`auth/`**: Gestione del primo avvio (`OnboardingScreen`) per la configurazione del Master PIN e sblocco ordinario (`LockScreen`) con prompt biometrico immediato.
- **`vault/`**:
  - `VaultHomeScreen`: Dashboard con barra di ricerca, chip per categoria, contatori e lista elementi.
  - `VaultDetailScreen`: Schermata di visualizzazione con pulsanti per mostrare/nascondere dati segreti, copia rapida e rendering a mockup grafico per carte di credito.
  - `VaultEditorScreen`: Form di inserimento/modifica con validazione e shortcut al generatore di password.
- **`generator/` & `security/`**:
  - `PasswordGeneratorScreen`: Utility per testare e generare password.
  - `SecurityAuditScreen`: Dashboard per visualizzare il livello di salute del vault e risolvere le vulnerabilità (password deboli o duplicate).
- **`settings/`**: Gestione cambio PIN, opzioni di sicurezza, esportazione/ripristino backup e wipe totale dei dati.
- **`widgets/`**: Componenti riutilizzabili (`PrivacyShield`, `VaultCard`, `PasswordStrengthBar`).

### 5. `main.dart`
- Inizializza i servizi e inietta i Provider tramite `MultiProvider` nel widget `CaveauRoot`.
- Implementa `WidgetsBindingObserver` per monitorare gli eventi di ciclo di vita dell'app (`paused`, `inactive`, `resumed`), attivando istantaneamente il `PrivacyShield` e calcolando il tempo trascorso per l'auto-lock.

---

## ⚠️ Regole di Sicurezza per Agenti AI

Quando modifichi o estendi questa applicazione:
1. **Non salvare mai dati sensibili in chiaro** o in storage non cifrati come `SharedPreferences` standard. Usa sempre `SecureStorageService`.
2. **Android Activity**: Mantieni `MainActivity` ereditata da `FlutterFragmentActivity` (necessario per il corretto funzionamento di `local_auth` su Android).
3. **Non rimuovere i permessi o configurazioni native**:
   - `android:allowBackup="false"` in `AndroidManifest.xml` (previene l'estrazione non autorizzata dei dati tramite backup di sistema).
   - `NSFaceIDUsageDescription` in `ios/Runner/Info.plist`.
4. **Mantieni la separazione tra UI e Crittografia**: La logica di hashing e derivazione chiavi deve rimanere isolata nei `services/`.
