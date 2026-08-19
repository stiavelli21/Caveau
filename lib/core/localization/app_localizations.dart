import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../constants/app_brand_terms.dart';
import '../../models/vault_item.dart';
import '../utils/password_generator.dart';

/// Extension for convenient access to [AppLocalizations] from [BuildContext]
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Metadata model describing supported languages
class LanguageMetadata {
  final String code;
  final String nativeName;
  final String englishName;
  final String flag;

  const LanguageMetadata({
    required this.code,
    required this.nativeName,
    required this.englishName,
    required this.flag,
  });
}

/// Abstract localization interface for Caveau.
/// All translations (Italian, English, Spanish, French, German) implement this interface.
abstract class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizationsIt();
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('it'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('de'),
  ];

  static const List<LanguageMetadata> supportedLanguages = [
    LanguageMetadata(code: 'it', nativeName: 'Italiano', englishName: 'Italian', flag: '🇮🇹'),
    LanguageMetadata(code: 'en', nativeName: 'English', englishName: 'English', flag: '🇬🇧'),
    LanguageMetadata(code: 'es', nativeName: 'Español', englishName: 'Spanish', flag: '🇪🇸'),
    LanguageMetadata(code: 'fr', nativeName: 'Français', englishName: 'French', flag: '🇫🇷'),
    LanguageMetadata(code: 'de', nativeName: 'Deutsch', englishName: 'German', flag: '🇩🇪'),
  ];

  // --- Brand & General ---
  String get appName => AppBrandTerms.appName;
  String get languageName;
  String get languageCode => locale.languageCode;

  // --- Auth & Lock Screen ---
  String get vaultProtectedTitle;
  String get enterMasterPinPrompt;
  String get insertMasterPinHint;
  String get unlockVaultButton;
  String get unlockWithBiometricsButton;
  String get biometricPromptReason;
  String get biometricDisabledInSettings;
  String get biometricFailedOrCanceled;
  String get masterPinIncorrect;
  String pinAttemptsRemaining(int remaining);
  String lockoutTimeRemaining(int seconds);
  String get currentPinInvalid;

  // --- Onboarding Screen ---
  String get welcomeToCaveau;
  String get onboardingSubtitle;
  String get hardwareSecurityNotice;
  String get createMasterPinTitle;
  String get confirmMasterPinHint;
  String get minMasterPinError;
  String get pinsDoNotMatchError;
  String get enableBiometricSwitch;
  String get initializeVaultButton;

  // --- Home Screen ---
  String get searchHint;
  String get allCategoryFilter;
  String get favoritesFilter;
  String get emptyVaultTitle;
  String get emptyVaultSubtitle;
  String get noSearchResultsTitle;
  String get noSearchResultsSubtitle;
  String get addItemButton;
  String get newItemFab;
  String get whatToSaveTitle;
  String get lockNowTooltip;
  String get passwordGeneratorTooltip;
  String get securityAuditTooltip;
  String get settingsTooltip;

  // --- Categories ---
  String categoryDisplayName(VaultCategory category);
  String categoryShortName(VaultCategory category);
  String categoryDescription(VaultCategory category);

  // --- Vault Detail Screen ---
  String get itemDeletedFallback;
  String get itemNotFound;
  String get deleteItemTitle;
  String deleteItemConfirmMessage(String title);
  String get cancelButton;
  String get deleteButton;
  String get editButton;
  String get saveButton;
  String get closeButton;
  String get copyButton;
  String get generateButton;
  String get restoreButton;

  // Detail Fields
  String get usernameLabel;
  String get passwordLabel;
  String get websiteLabel;
  String get notesLabel;
  String get cardHolderLabel;
  String get cardNumberLabel;
  String get cardExpiryLabel;
  String get cardCvvLabel;
  String get cardPinLabel;
  String get emailLabel;
  String get phoneLabel;
  String get idNumberLabel;
  String get apiKeySecretLabel;
  String get customFieldsSection;
  String get securityInfoSection;
  String get createdLabel;
  String get lastUpdatedLabel;
  String get cardHolderCardMockup;
  String get cardExpiryCardMockup;
  String get copyCardNumber;
  String get copyPassword;
  String get copyNotes;
  String get copyIdentity;
  String get copyApiKey;
  String get noUsername;
  String get paymentCardSubtitle;
  String get encryptedNoteSubtitle;
  String get encryptedKeySubtitle;

  // Copy Feedback
  String fieldCopiedAutoClear(String fieldLabel, int seconds);
  String fieldCopied(String fieldLabel);
  String get passwordCopiedFeedback;
  String get cardNumberCopiedFeedback;
  String get noteTextCopiedFeedback;
  String get identityCopiedFeedback;
  String get apiKeyCopiedFeedback;
  String get backupCopiedFeedback;

  // --- Vault Editor Screen ---
  String get editItemTitle;
  String get newItemTitle;
  String get titleLabel;
  String get titleRequiredValidation;
  String get addCustomFieldButton;
  String get fieldNameLabel;
  String get fieldValueLabel;
  String get secretFieldCheckbox;
  String get optionalLabel;

  // --- Password Generator ---
  String get passwordGeneratorTitle;
  String get lengthSliderLabel;
  String get uppercaseOption;
  String get lowercaseOption;
  String get numbersOption;
  String get symbolsOption;
  String get excludeAmbiguousOption;
  String get excludeAmbiguousSubtitle;
  String get usePasswordButton;
  String passwordLengthLabel(int length);
  String passwordEntropyLabel(String entropy);

  // Password Strength
  String passwordStrengthLabel(PasswordStrength strength);
  String get securityLevelPrefix;

  // --- Security Audit ---
  String get securityAuditTitle;
  String securityScoreLabel(int score);
  String get auditDescription;
  String get totalItemsStat;
  String get weakPasswordsStat;
  String get reusedPasswordsStat;
  String get weakPasswordsSection;
  String get reusedPasswordsSection;
  String get allPasswordsHealthy;
  String get allPasswordsHealthySubtitle;
  String get weakPasswordTileLabel;
  String reusedPasswordTileLabel(int count);
  String get fixButton;

  // --- Settings Screen ---
  String get settingsTitle;
  String get sectionLanguage;
  String get sectionAuthAccess;
  String get sectionPrivacyClipboard;
  String get sectionBackupRestore;
  String get sectionDangerZone;

  String get languageOptionLabel;
  String get languageOptionSubtitle;
  String get biometricUnlockTileTitle;
  String get biometricUnlockTileSubtitle;
  String get changeMasterPinTileTitle;
  String get changeMasterPinTileSubtitle;
  String get autoLockTileTitle;
  String get privacyShieldTileTitle;
  String get privacyShieldTileSubtitle;
  String get clearClipboardTileTitle;
  String get exportBackupTileTitle;
  String get exportBackupTileSubtitle;
  String get restoreBackupTileTitle;
  String get restoreBackupTileSubtitle;
  String get wipeAllDataTileTitle;
  String get wipeAllDataTileSubtitle;

  // Dialogs & Pickers in Settings
  String get selectLanguageTitle;
  String get changePinDialogTitle;
  String get currentPinFieldLabel;
  String get newPinFieldLabel;
  String get confirmNewPinFieldLabel;
  String get pinMinCharsError;
  String get newPinsDoNotMatchError;
  String get pinUpdatedSuccess;
  String get exportBackupDialogTitle;
  String get exportBackupInstructions;
  String get backupPasswordFieldLabel;
  String get backupPasswordMinCharsError;
  String get backupGeneratedDialogTitle;
  String get backupCopyWarning;
  String get restoreBackupDialogTitle;
  String get pasteBackupDataLabel;
  String get fillAllFieldsError;
  String itemsRestoredSuccess(int count);
  String get restoreFailedError;
  String get wipeAllDataDialogTitle;
  String get wipeAllDataWarning1;
  String get wipeAllDataWarning2;
  String get wipeAllDataConfirmButton;

  // Auto-lock & Clipboard picker labels
  String formatAutoLock(int seconds);
  String formatClipboard(int seconds);
  String get autoLockPickerTitle;
  String get clipboardPickerTitle;
  String get autoLockImmediate;
  String get autoLock30s;
  String get autoLock1m;
  String get autoLock5m;
  String get clipboardDisabled;
  String get clipboard15s;
  String get clipboard30sRecommended;
  String get clipboard60s;

  // --- Privacy Shield Overlay ---
  String get privacyShieldTitle;
  String get privacyShieldSubtitle;
}

/// ============================================================================
/// ITALIAN LOCALIZATION (Default)
/// ============================================================================
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt() : super(const Locale('it'));

  @override
  String get languageName => 'Italiano';

  @override
  String get vaultProtectedTitle => '${AppBrandTerms.appName} Protetto';

  @override
  String get enterMasterPinPrompt => 'Inserisci il ${AppBrandTerms.pinMaster} per accedere';

  @override
  String get insertMasterPinHint => 'Inserisci ${AppBrandTerms.pinMaster}';

  @override
  String get unlockVaultButton => 'Sblocca Cassaforte';

  @override
  String get unlockWithBiometricsButton => 'Sblocca con Biometria / ${AppBrandTerms.faceId}';

  @override
  String get biometricPromptReason => 'Autenticati per accedere a ${AppBrandTerms.appName}';

  @override
  String get biometricDisabledInSettings => 'Sblocco biometrico disabilitato nelle impostazioni';

  @override
  String get biometricFailedOrCanceled => 'Autenticazione biometrica fallita o annullata';

  @override
  String get masterPinIncorrect => '${AppBrandTerms.pinMaster} non corretto';

  @override
  String pinAttemptsRemaining(int remaining) => '${AppBrandTerms.pinMaster} non corretto ($remaining tentativi rimasti)';

  @override
  String lockoutTimeRemaining(int seconds) => 'Troppi tentativi falliti. Riprova tra ${seconds}s';

  @override
  String get currentPinInvalid => '${AppBrandTerms.pinMaster} attuale non valido';

  @override
  String get welcomeToCaveau => 'Benvenuto in ${AppBrandTerms.appName}';

  @override
  String get onboardingSubtitle => 'La tua cassaforte crittografata locale per ${AppBrandTerms.password.toLowerCase()} e dati sensibili.';

  @override
  String get hardwareSecurityNotice => 'I tuoi dati vengono crittografati sul dispositivo (${AppBrandTerms.androidKeystore} / ${AppBrandTerms.iosKeychain}). Nessun dato lascia mai il telefono.';

  @override
  String get createMasterPinTitle => 'Crea il tuo ${AppBrandTerms.pinMaster}';

  @override
  String get confirmMasterPinHint => 'Conferma ${AppBrandTerms.pinMaster}';

  @override
  String get minMasterPinError => 'Il ${AppBrandTerms.pinMaster} deve contenere almeno 4 caratteri o cifre';

  @override
  String get pinsDoNotMatchError => 'I ${AppBrandTerms.pin} inseriti non corrispondono';

  @override
  String get enableBiometricSwitch => 'Abilita Sblocco Biometrico (${AppBrandTerms.faceId} / Impronta)';

  @override
  String get initializeVaultButton => 'Inizializza ${AppBrandTerms.appName} Sicuro';

  @override
  String get searchHint => 'Cerca nella cassaforte...';

  @override
  String get allCategoryFilter => 'Tutti';

  @override
  String get favoritesFilter => 'Preferiti';

  @override
  String get emptyVaultTitle => 'Il tuo ${AppBrandTerms.appName} è vuoto';

  @override
  String get emptyVaultSubtitle => 'Salva le tue ${AppBrandTerms.password.toLowerCase()}, carte e note in sicurezza';

  @override
  String get noSearchResultsTitle => 'Nessun risultato trovato';

  @override
  String get noSearchResultsSubtitle => 'Prova con un termine di ricerca diverso';

  @override
  String get addItemButton => 'Aggiungi';

  @override
  String get newItemFab => 'Nuovo Elemento';

  @override
  String get whatToSaveTitle => 'Cosa vuoi salvare?';

  @override
  String get lockNowTooltip => 'Blocca adesso';

  @override
  String get passwordGeneratorTooltip => 'Generatore ${AppBrandTerms.password}';

  @override
  String get securityAuditTooltip => 'Security Audit';

  @override
  String get settingsTooltip => 'Impostazioni';

  @override
  String categoryDisplayName(VaultCategory category) {
    switch (category) {
      case VaultCategory.login:
        return '${AppBrandTerms.password} & Account';
      case VaultCategory.card:
        return 'Carte di Pagamento';
      case VaultCategory.note:
        return 'Note Crittografate';
      case VaultCategory.identity:
        return 'Identità & Documenti';
      case VaultCategory.apiKey:
        return 'Chiave ${AppBrandTerms.apiKey} / Token';
    }
  }

  @override
  String categoryShortName(VaultCategory category) {
    switch (category) {
      case VaultCategory.login:
        return AppBrandTerms.password;
      case VaultCategory.card:
        return 'Carte';
      case VaultCategory.note:
        return 'Note';
      case VaultCategory.identity:
        return 'Identità';
      case VaultCategory.apiKey:
        return AppBrandTerms.api;
    }
  }

  @override
  String categoryDescription(VaultCategory category) {
    switch (category) {
      case VaultCategory.login:
        return 'Credenziali per siti web, app e servizi digitali';
      case VaultCategory.card:
        return 'Carte di credito, debito, ${AppBrandTerms.cvv} e ${AppBrandTerms.pin}';
      case VaultCategory.note:
        return 'Testi, ${AppBrandTerms.pin} o appunti crittografati';
      case VaultCategory.identity:
        return 'Documenti, ${AppBrandTerms.email}, codici fiscali e anagrafica';
      case VaultCategory.apiKey:
        return 'Token di accesso, chiavi private e segreti API';
    }
  }

  @override
  String get itemDeletedFallback => 'Elemento Eliminato';

  @override
  String get itemNotFound => 'Elemento non trovato';

  @override
  String get deleteItemTitle => 'Elimina Elemento';

  @override
  String deleteItemConfirmMessage(String title) =>
      'Sei sicuro di voler eliminare permanentemente "$title"?\n\nL\'operazione non potrà essere annullata.';

  @override
  String get cancelButton => 'Annulla';

  @override
  String get deleteButton => 'Elimina';

  @override
  String get editButton => 'Modifica';

  @override
  String get saveButton => 'Salva';

  @override
  String get closeButton => 'Chiudi';

  @override
  String get copyButton => 'Copia';

  @override
  String get generateButton => 'Genera';

  @override
  String get restoreButton => 'Ripristina';

  @override
  String get usernameLabel => 'Nome Utente / ${AppBrandTerms.email}';

  @override
  String get passwordLabel => AppBrandTerms.password;

  @override
  String get websiteLabel => 'Sito Web / ${AppBrandTerms.url}';

  @override
  String get notesLabel => 'Note';

  @override
  String get cardHolderLabel => 'Intestatario Carta';

  @override
  String get cardNumberLabel => 'Numero Carta';

  @override
  String get cardExpiryLabel => 'Scadenza';

  @override
  String get cardCvvLabel => '${AppBrandTerms.cvcOrCvv} di Sicurezza';

  @override
  String get cardPinLabel => '${AppBrandTerms.pin} Carta';

  @override
  String get emailLabel => AppBrandTerms.email;

  @override
  String get phoneLabel => 'Telefono';

  @override
  String get idNumberLabel => 'Codice Fiscale / Documento';

  @override
  String get apiKeySecretLabel => 'Chiave Segreta / Token';

  @override
  String get customFieldsSection => 'Campi Personalizzati';

  @override
  String get securityInfoSection => 'Informazioni di Sicurezza';

  @override
  String get createdLabel => 'Creato';

  @override
  String get lastUpdatedLabel => 'Ultima modifica';

  @override
  String get cardHolderCardMockup => 'INTESTATARIO';

  @override
  String get cardExpiryCardMockup => 'SCADENZA';

  @override
  String get copyCardNumber => 'Copia Numero Carta';

  @override
  String get copyPassword => 'Copia ${AppBrandTerms.password}';

  @override
  String get copyNotes => 'Copia Note';

  @override
  String get copyIdentity => 'Copia Documento / ${AppBrandTerms.email}';

  @override
  String get copyApiKey => 'Copia ${AppBrandTerms.apiKey}';

  @override
  String get noUsername => 'Nessun username';

  @override
  String get paymentCardSubtitle => 'Carta di pagamento';

  @override
  String get encryptedNoteSubtitle => 'Nota crittografata';

  @override
  String get encryptedKeySubtitle => 'Chiave di sicurezza crittografata';

  @override
  String fieldCopiedAutoClear(String fieldLabel, int seconds) =>
      '$fieldLabel copiato (auto-clear in ${seconds}s)';

  @override
  String fieldCopied(String fieldLabel) => '$fieldLabel copiato';

  @override
  String get passwordCopiedFeedback => '${AppBrandTerms.password} copiata';

  @override
  String get cardNumberCopiedFeedback => 'Numero carta copiato';

  @override
  String get noteTextCopiedFeedback => 'Testo nota copiato';

  @override
  String get identityCopiedFeedback => 'Dato identità copiato';

  @override
  String get apiKeyCopiedFeedback => '${AppBrandTerms.apiKey} copiata';

  @override
  String get backupCopiedFeedback => 'Backup cifrato copiato negli appunti';

  @override
  String get editItemTitle => 'Modifica Elemento';

  @override
  String get newItemTitle => 'Nuovo Elemento';

  @override
  String get titleLabel => 'Titolo';

  @override
  String get titleRequiredValidation => 'Inserisci un titolo';

  @override
  String get addCustomFieldButton => 'Aggiungi Campo Personalizzato';

  @override
  String get fieldNameLabel => 'Etichetta campo';

  @override
  String get fieldValueLabel => 'Valore';

  @override
  String get secretFieldCheckbox => 'Nascondi valore (Dato segreto)';

  @override
  String get optionalLabel => 'opzionale';

  @override
  String get passwordGeneratorTitle => 'Generatore ${AppBrandTerms.password}';

  @override
  String get lengthSliderLabel => 'Lunghezza ${AppBrandTerms.password}';

  @override
  String get uppercaseOption => 'Lettere Maiuscole (A-Z)';

  @override
  String get lowercaseOption => 'Lettere Minuscole (a-z)';

  @override
  String get numbersOption => 'Numeri (0-9)';

  @override
  String get symbolsOption => 'Simboli Speciali (!@#\$%^&*)';

  @override
  String get excludeAmbiguousOption => 'Escludi caratteri ambigui';

  @override
  String get excludeAmbiguousSubtitle => 'Evita caratteri simili come Il1O0';

  @override
  String get usePasswordButton => 'Usa questa ${AppBrandTerms.password}';

  @override
  String passwordLengthLabel(int length) => '$length caratteri';

  @override
  String passwordEntropyLabel(String entropy) => '$entropy bit entropia';

  @override
  String passwordStrengthLabel(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.veryWeak:
        return 'Molto Debole';
      case PasswordStrength.weak:
        return 'Debole';
      case PasswordStrength.medium:
        return 'Media';
      case PasswordStrength.strong:
        return 'Forte';
      case PasswordStrength.veryStrong:
        return 'Molto Forte';
    }
  }

  @override
  String get securityLevelPrefix => 'Sicurezza';

  @override
  String get securityAuditTitle => 'Security Audit';

  @override
  String securityScoreLabel(int score) {
    if (score >= 85) return 'Ottimo Stato di Sicurezza';
    if (score >= 60) return 'Sicurezza Moderata';
    return 'Attenzione: Sicurezza a Rischio';
  }

  @override
  String get auditDescription =>
      'Analisi basata su robustezza, entropia e riutilizzo delle ${AppBrandTerms.password.toLowerCase()} salvate.';

  @override
  String get totalItemsStat => 'Elementi Totali';

  @override
  String get weakPasswordsStat => '${AppBrandTerms.password} Deboli';

  @override
  String get reusedPasswordsStat => 'Riutilizzate';

  @override
  String get weakPasswordsSection => '${AppBrandTerms.password} Deboli o Troppo Brevi';

  @override
  String get reusedPasswordsSection => '${AppBrandTerms.password} Duplicate / Riutilizzate';

  @override
  String get allPasswordsHealthy => 'Tutte le ${AppBrandTerms.password.toLowerCase()} sono sicure!';

  @override
  String get allPasswordsHealthySubtitle =>
      'Nessuna vulnerabilità o riutilizzo rilevato nel tuo ${AppBrandTerms.appName}.';

  @override
  String get weakPasswordTileLabel => '${AppBrandTerms.password} debole';

  @override
  String reusedPasswordTileLabel(int count) => 'Condivisa in $count account';

  @override
  String get fixButton => 'Risolvi';

  @override
  String get settingsTitle => 'Impostazioni di Sicurezza';

  @override
  String get sectionLanguage => 'LINGUA / LANGUAGE';

  @override
  String get sectionAuthAccess => 'AUTENTICAZIONE & ACCESSO';

  @override
  String get sectionPrivacyClipboard => 'PRIVACY & APPUNTI';

  @override
  String get sectionBackupRestore => 'BACKUP & RIPRISTINO';

  @override
  String get sectionDangerZone => 'ZONA DI PERICOLO';

  @override
  String get languageOptionLabel => 'Lingua';

  @override
  String get languageOptionSubtitle => 'Seleziona la lingua per testi e interfaccia';

  @override
  String get biometricUnlockTileTitle => 'Sblocco Biometrico';

  @override
  String get biometricUnlockTileSubtitle =>
      'Richiedi ${AppBrandTerms.faceId} o impronta digitale per sbloccare ${AppBrandTerms.appName}';

  @override
  String get changeMasterPinTileTitle => 'Modifica ${AppBrandTerms.pinMaster}';

  @override
  String get changeMasterPinTileSubtitle => 'Aggiorna il codice principale di accesso';

  @override
  String get autoLockTileTitle => 'Blocco Automatico';

  @override
  String get privacyShieldTileTitle => 'Privacy Shield';

  @override
  String get privacyShieldTileSubtitle => 'Oscura la schermata nel multitasking dell\'OS';

  @override
  String get clearClipboardTileTitle => 'Svuota Appunti Automaticamente';

  @override
  String get exportBackupTileTitle => 'Esporta Backup Cifrato';

  @override
  String get exportBackupTileSubtitle => 'Salva una copia protetta da ${AppBrandTerms.password.toLowerCase()}';

  @override
  String get restoreBackupTileTitle => 'Ripristina Backup';

  @override
  String get restoreBackupTileSubtitle => 'Importa dati cifrati precedentemente salvati';

  @override
  String get wipeAllDataTileTitle => 'Cancella e Azzera ${AppBrandTerms.appName}';

  @override
  String get wipeAllDataTileSubtitle => 'Elimina definitivamente tutti i dati e le impostazioni';

  @override
  String get selectLanguageTitle => 'Seleziona Lingua';

  @override
  String get changePinDialogTitle => 'Modifica ${AppBrandTerms.pinMaster}';

  @override
  String get currentPinFieldLabel => '${AppBrandTerms.pinMaster} Attuale';

  @override
  String get newPinFieldLabel => 'Nuovo ${AppBrandTerms.pinMaster}';

  @override
  String get confirmNewPinFieldLabel => 'Conferma Nuovo ${AppBrandTerms.pinMaster}';

  @override
  String get pinMinCharsError => 'Il ${AppBrandTerms.pinMaster} deve contenere almeno 4 caratteri';

  @override
  String get newPinsDoNotMatchError => 'I nuovi ${AppBrandTerms.pin} non corrispondono';

  @override
  String get pinUpdatedSuccess => '${AppBrandTerms.pinMaster} aggiornato con successo';

  @override
  String get exportBackupDialogTitle => 'Esporta Backup Cifrato';

  @override
  String get exportBackupInstructions =>
      'Inserisci una ${AppBrandTerms.password.toLowerCase()} per cifrare il file di backup con ${AppBrandTerms.aes256}. Conserva questa ${AppBrandTerms.password.toLowerCase()} con cura.';

  @override
  String get backupPasswordFieldLabel => '${AppBrandTerms.password} di cifratura backup';

  @override
  String get backupPasswordMinCharsError => 'Inserisci una ${AppBrandTerms.password.toLowerCase()} di almeno 6 caratteri';

  @override
  String get backupGeneratedDialogTitle => 'Backup Cifrato Generato';

  @override
  String get backupCopyWarning =>
      'Copia e conserva questa stringa cifrata in un luogo sicuro. Senza la ${AppBrandTerms.password.toLowerCase()} impostata sarà impossibile decifrarla.';

  @override
  String get restoreBackupDialogTitle => 'Ripristina da Backup';

  @override
  String get pasteBackupDataLabel => 'Incolla la stringa del backup cifrato';

  @override
  String get fillAllFieldsError => 'Compila tutti i campi richiesti';

  @override
  String itemsRestoredSuccess(int count) => '$count elementi ripristinati con successo!';

  @override
  String get restoreFailedError => 'Ripristino fallito: dati non validi o ${AppBrandTerms.password.toLowerCase()} errata';

  @override
  String get wipeAllDataDialogTitle => 'Cancellazione Totale Dati';

  @override
  String get wipeAllDataWarning1 => 'ATTENZIONE: Questa azione cancellerà irrevocabilmente:';

  @override
  String get wipeAllDataWarning2 =>
      'Tutte le ${AppBrandTerms.password.toLowerCase()}, carte, note, ${AppBrandTerms.pinMaster} e impostazioni salvate.';

  @override
  String get wipeAllDataConfirmButton => 'Elimina Tutto Definitivamente';

  @override
  String formatAutoLock(int seconds) {
    if (seconds == 0) return 'Immediato';
    if (seconds < 60) return '${seconds}s';
    return '${seconds ~/ 60}m';
  }

  @override
  String formatClipboard(int seconds) {
    if (seconds == 0) return 'Mai';
    return '${seconds}s';
  }

  @override
  String get autoLockPickerTitle => 'Timeout Blocco Automatico';

  @override
  String get clipboardPickerTitle => 'Timeout Svuotamento Appunti';

  @override
  String get autoLockImmediate => 'Immediato (all\'uscita)';

  @override
  String get autoLock30s => 'Dopo 30 secondi';

  @override
  String get autoLock1m => 'Dopo 1 minuto';

  @override
  String get autoLock5m => 'Dopo 5 minuti';

  @override
  String get clipboardDisabled => 'Disabilitato (Non svuotare mai)';

  @override
  String get clipboard15s => '15 secondi';

  @override
  String get clipboard30sRecommended => '30 secondi (Consigliato)';

  @override
  String get clipboard60s => '60 secondi';

  @override
  String get privacyShieldTitle => '${AppBrandTerms.appName} Protetto';

  @override
  String get privacyShieldSubtitle => 'Schermata oscurata per la tua privacy';
}

/// ============================================================================
/// ENGLISH LOCALIZATION
/// ============================================================================
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn() : super(const Locale('en'));

  @override
  String get languageName => 'English';

  @override
  String get vaultProtectedTitle => '${AppBrandTerms.appName} Protected';

  @override
  String get enterMasterPinPrompt => 'Enter your ${AppBrandTerms.masterPin} to access';

  @override
  String get insertMasterPinHint => 'Enter ${AppBrandTerms.masterPin}';

  @override
  String get unlockVaultButton => 'Unlock Vault';

  @override
  String get unlockWithBiometricsButton => 'Unlock with Biometrics / ${AppBrandTerms.faceId}';

  @override
  String get biometricPromptReason => 'Authenticate to access ${AppBrandTerms.appName}';

  @override
  String get biometricDisabledInSettings => 'Biometric unlock is disabled in settings';

  @override
  String get biometricFailedOrCanceled => 'Biometric authentication failed or was cancelled';

  @override
  String get masterPinIncorrect => 'Incorrect ${AppBrandTerms.masterPin}';

  @override
  String pinAttemptsRemaining(int remaining) => 'Incorrect ${AppBrandTerms.masterPin} ($remaining attempts remaining)';

  @override
  String lockoutTimeRemaining(int seconds) => 'Too many failed attempts. Try again in ${seconds}s';

  @override
  String get currentPinInvalid => 'Invalid current ${AppBrandTerms.masterPin}';

  @override
  String get welcomeToCaveau => 'Welcome to ${AppBrandTerms.appName}';

  @override
  String get onboardingSubtitle => 'Your local encrypted vault for ${AppBrandTerms.password.toLowerCase()}s and confidential data.';

  @override
  String get hardwareSecurityNotice => 'Your data is hardware-encrypted on your device (${AppBrandTerms.androidKeystore} / ${AppBrandTerms.iosKeychain}). No data ever leaves your phone.';

  @override
  String get createMasterPinTitle => 'Create your ${AppBrandTerms.masterPin}';

  @override
  String get confirmMasterPinHint => 'Confirm ${AppBrandTerms.masterPin}';

  @override
  String get minMasterPinError => 'The ${AppBrandTerms.masterPin} must be at least 4 characters long';

  @override
  String get pinsDoNotMatchError => 'The entered ${AppBrandTerms.pin}s do not match';

  @override
  String get enableBiometricSwitch => 'Enable Biometric Unlock (${AppBrandTerms.faceId} / Fingerprint)';

  @override
  String get initializeVaultButton => 'Initialize Secure ${AppBrandTerms.appName}';

  @override
  String get searchHint => 'Search in vault...';

  @override
  String get allCategoryFilter => 'All';

  @override
  String get favoritesFilter => 'Favorites';

  @override
  String get emptyVaultTitle => 'Your ${AppBrandTerms.appName} is empty';

  @override
  String get emptyVaultSubtitle => 'Store your ${AppBrandTerms.password.toLowerCase()}s, cards, and secure notes';

  @override
  String get noSearchResultsTitle => 'No results found';

  @override
  String get noSearchResultsSubtitle => 'Try searching with a different keyword';

  @override
  String get addItemButton => 'Add';

  @override
  String get newItemFab => 'New Item';

  @override
  String get whatToSaveTitle => 'What do you want to save?';

  @override
  String get lockNowTooltip => 'Lock now';

  @override
  String get passwordGeneratorTooltip => '${AppBrandTerms.password} Generator';

  @override
  String get securityAuditTooltip => 'Security Audit';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String categoryDisplayName(VaultCategory category) {
    switch (category) {
      case VaultCategory.login:
        return '${AppBrandTerms.password}s & Accounts';
      case VaultCategory.card:
        return 'Payment Cards';
      case VaultCategory.note:
        return 'Encrypted Notes';
      case VaultCategory.identity:
        return 'Identities & Documents';
      case VaultCategory.apiKey:
        return '${AppBrandTerms.apiKey} / Tokens';
    }
  }

  @override
  String categoryShortName(VaultCategory category) {
    switch (category) {
      case VaultCategory.login:
        return '${AppBrandTerms.password}s';
      case VaultCategory.card:
        return 'Cards';
      case VaultCategory.note:
        return 'Notes';
      case VaultCategory.identity:
        return 'Identity';
      case VaultCategory.apiKey:
        return AppBrandTerms.api;
    }
  }

  @override
  String categoryDescription(VaultCategory category) {
    switch (category) {
      case VaultCategory.login:
        return 'Credentials for websites, apps, and online services';
      case VaultCategory.card:
        return 'Credit, debit cards, ${AppBrandTerms.cvv}, and ${AppBrandTerms.pin}';
      case VaultCategory.note:
        return 'Encrypted texts, ${AppBrandTerms.pin}s, or confidential memos';
      case VaultCategory.identity:
        return 'IDs, ${AppBrandTerms.email}s, tax codes, and personal details';
      case VaultCategory.apiKey:
        return 'API keys, private tokens, and developer secrets';
    }
  }

  @override
  String get itemDeletedFallback => 'Item Deleted';

  @override
  String get itemNotFound => 'Item not found';

  @override
  String get deleteItemTitle => 'Delete Item';

  @override
  String deleteItemConfirmMessage(String title) =>
      'Are you sure you want to permanently delete "$title"?\n\nThis action cannot be undone.';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get deleteButton => 'Delete';

  @override
  String get editButton => 'Edit';

  @override
  String get saveButton => 'Save';

  @override
  String get closeButton => 'Close';

  @override
  String get copyButton => 'Copy';

  @override
  String get generateButton => 'Generate';

  @override
  String get restoreButton => 'Restore';

  @override
  String get usernameLabel => 'Username / ${AppBrandTerms.email}';

  @override
  String get passwordLabel => AppBrandTerms.password;

  @override
  String get websiteLabel => 'Website / ${AppBrandTerms.url}';

  @override
  String get notesLabel => 'Notes';

  @override
  String get cardHolderLabel => 'Cardholder Name';

  @override
  String get cardNumberLabel => 'Card Number';

  @override
  String get cardExpiryLabel => 'Expiry Date';

  @override
  String get cardCvvLabel => 'Security ${AppBrandTerms.cvcOrCvv}';

  @override
  String get cardPinLabel => 'Card ${AppBrandTerms.pin}';

  @override
  String get emailLabel => AppBrandTerms.email;

  @override
  String get phoneLabel => 'Phone';

  @override
  String get idNumberLabel => 'ID / Document Number';

  @override
  String get apiKeySecretLabel => 'API Secret / Token';

  @override
  String get customFieldsSection => 'Custom Fields';

  @override
  String get securityInfoSection => 'Security Information';

  @override
  String get createdLabel => 'Created';

  @override
  String get lastUpdatedLabel => 'Last updated';

  @override
  String get cardHolderCardMockup => 'CARD HOLDER';

  @override
  String get cardExpiryCardMockup => 'EXPIRES';

  @override
  String get copyCardNumber => 'Copy Card Number';

  @override
  String get copyPassword => 'Copy ${AppBrandTerms.password}';

  @override
  String get copyNotes => 'Copy Notes';

  @override
  String get copyIdentity => 'Copy Document / ${AppBrandTerms.email}';

  @override
  String get copyApiKey => 'Copy ${AppBrandTerms.apiKey}';

  @override
  String get noUsername => 'No username';

  @override
  String get paymentCardSubtitle => 'Payment card';

  @override
  String get encryptedNoteSubtitle => 'Encrypted note';

  @override
  String get encryptedKeySubtitle => 'Encrypted security key';

  @override
  String fieldCopiedAutoClear(String fieldLabel, int seconds) =>
      '$fieldLabel copied (auto-clears in ${seconds}s)';

  @override
  String fieldCopied(String fieldLabel) => '$fieldLabel copied';

  @override
  String get passwordCopiedFeedback => '${AppBrandTerms.password} copied';

  @override
  String get cardNumberCopiedFeedback => 'Card number copied';

  @override
  String get noteTextCopiedFeedback => 'Note content copied';

  @override
  String get identityCopiedFeedback => 'Identity data copied';

  @override
  String get apiKeyCopiedFeedback => '${AppBrandTerms.apiKey} copied';

  @override
  String get backupCopiedFeedback => 'Encrypted backup copied to clipboard';

  @override
  String get editItemTitle => 'Edit Item';

  @override
  String get newItemTitle => 'New Item';

  @override
  String get titleLabel => 'Title';

  @override
  String get titleRequiredValidation => 'Please enter a title';

  @override
  String get addCustomFieldButton => 'Add Custom Field';

  @override
  String get fieldNameLabel => 'Field label';

  @override
  String get fieldValueLabel => 'Value';

  @override
  String get secretFieldCheckbox => 'Hide value (Secret data)';

  @override
  String get optionalLabel => 'optional';

  @override
  String get passwordGeneratorTitle => '${AppBrandTerms.password} Generator';

  @override
  String get lengthSliderLabel => '${AppBrandTerms.password} Length';

  @override
  String get uppercaseOption => 'Uppercase Letters (A-Z)';

  @override
  String get lowercaseOption => 'Lowercase Letters (a-z)';

  @override
  String get numbersOption => 'Numbers (0-9)';

  @override
  String get symbolsOption => 'Special Symbols (!@#\$%^&*)';

  @override
  String get excludeAmbiguousOption => 'Exclude Ambiguous Characters';

  @override
  String get excludeAmbiguousSubtitle => 'Avoids lookalike characters like Il1O0';

  @override
  String get usePasswordButton => 'Use this ${AppBrandTerms.password}';

  @override
  String passwordLengthLabel(int length) => '$length characters';

  @override
  String passwordEntropyLabel(String entropy) => '$entropy bits entropy';

  @override
  String passwordStrengthLabel(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.veryWeak:
        return 'Very Weak';
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.medium:
        return 'Medium';
      case PasswordStrength.strong:
        return 'Strong';
      case PasswordStrength.veryStrong:
        return 'Very Strong';
    }
  }

  @override
  String get securityLevelPrefix => 'Security';

  @override
  String get securityAuditTitle => 'Security Audit';

  @override
  String securityScoreLabel(int score) {
    if (score >= 85) return 'Excellent Security Health';
    if (score >= 60) return 'Moderate Security';
    return 'Warning: Security at Risk';
  }

  @override
  String get auditDescription =>
      'Analysis based on strength, entropy, and reuse of saved ${AppBrandTerms.password.toLowerCase()}s.';

  @override
  String get totalItemsStat => 'Total Items';

  @override
  String get weakPasswordsStat => 'Weak ${AppBrandTerms.password}s';

  @override
  String get reusedPasswordsStat => 'Reused';

  @override
  String get weakPasswordsSection => 'Weak or Too Short ${AppBrandTerms.password}s';

  @override
  String get reusedPasswordsSection => 'Duplicate / Reused ${AppBrandTerms.password}s';

  @override
  String get allPasswordsHealthy => 'All your ${AppBrandTerms.password.toLowerCase()}s are secure!';

  @override
  String get allPasswordsHealthySubtitle =>
      'No vulnerabilities or reused passwords found in your ${AppBrandTerms.appName}.';

  @override
  String get weakPasswordTileLabel => 'Weak ${AppBrandTerms.password.toLowerCase()}';

  @override
  String reusedPasswordTileLabel(int count) => 'Shared across $count accounts';

  @override
  String get fixButton => 'Fix';

  @override
  String get settingsTitle => 'Security Settings';

  @override
  String get sectionLanguage => 'LANGUAGE / LINGUA';

  @override
  String get sectionAuthAccess => 'AUTHENTICATION & ACCESS';

  @override
  String get sectionPrivacyClipboard => 'PRIVACY & CLIPBOARD';

  @override
  String get sectionBackupRestore => 'BACKUP & RESTORE';

  @override
  String get sectionDangerZone => 'DANGER ZONE';

  @override
  String get languageOptionLabel => 'Language';

  @override
  String get languageOptionSubtitle => 'Choose the language for text and interface';

  @override
  String get biometricUnlockTileTitle => 'Biometric Unlock';

  @override
  String get biometricUnlockTileSubtitle =>
      'Require ${AppBrandTerms.faceId} or fingerprint to unlock ${AppBrandTerms.appName}';

  @override
  String get changeMasterPinTileTitle => 'Change ${AppBrandTerms.masterPin}';

  @override
  String get changeMasterPinTileSubtitle => 'Update your primary security access code';

  @override
  String get autoLockTileTitle => 'Auto-Lock';

  @override
  String get privacyShieldTileTitle => 'Privacy Shield';

  @override
  String get privacyShieldTileSubtitle => 'Obscure screen in OS app switcher/multitasking';

  @override
  String get clearClipboardTileTitle => 'Auto-Clear Clipboard';

  @override
  String get exportBackupTileTitle => 'Export Encrypted Backup';

  @override
  String get exportBackupTileSubtitle => 'Save a ${AppBrandTerms.password.toLowerCase()}-protected copy of all data';

  @override
  String get restoreBackupTileTitle => 'Restore Backup';

  @override
  String get restoreBackupTileSubtitle => 'Import encrypted data from a previous backup';

  @override
  String get wipeAllDataTileTitle => 'Wipe and Reset ${AppBrandTerms.appName}';

  @override
  String get wipeAllDataTileSubtitle => 'Permanently delete all stored credentials and settings';

  @override
  String get selectLanguageTitle => 'Select Language';

  @override
  String get changePinDialogTitle => 'Change ${AppBrandTerms.masterPin}';

  @override
  String get currentPinFieldLabel => 'Current ${AppBrandTerms.masterPin}';

  @override
  String get newPinFieldLabel => 'New ${AppBrandTerms.masterPin}';

  @override
  String get confirmNewPinFieldLabel => 'Confirm New ${AppBrandTerms.masterPin}';

  @override
  String get pinMinCharsError => 'The ${AppBrandTerms.masterPin} must be at least 4 characters';

  @override
  String get newPinsDoNotMatchError => 'The new ${AppBrandTerms.pin}s do not match';

  @override
  String get pinUpdatedSuccess => '${AppBrandTerms.masterPin} updated successfully';

  @override
  String get exportBackupDialogTitle => 'Export Encrypted Backup';

  @override
  String get exportBackupInstructions =>
      'Enter a strong ${AppBrandTerms.password.toLowerCase()} to encrypt the backup file with ${AppBrandTerms.aes256}. Keep this ${AppBrandTerms.password.toLowerCase()} safe.';

  @override
  String get backupPasswordFieldLabel => 'Backup encryption ${AppBrandTerms.password.toLowerCase()}';

  @override
  String get backupPasswordMinCharsError => 'Enter a ${AppBrandTerms.password.toLowerCase()} with at least 6 characters';

  @override
  String get backupGeneratedDialogTitle => 'Encrypted Backup Generated';

  @override
  String get backupCopyWarning =>
      'Copy and store this encrypted string in a safe place. It cannot be recovered without your chosen ${AppBrandTerms.password.toLowerCase()}.';

  @override
  String get restoreBackupDialogTitle => 'Restore from Backup';

  @override
  String get pasteBackupDataLabel => 'Paste the encrypted backup data here';

  @override
  String get fillAllFieldsError => 'Please fill all required fields';

  @override
  String itemsRestoredSuccess(int count) => '$count items successfully restored!';

  @override
  String get restoreFailedError => 'Restore failed: invalid data or wrong ${AppBrandTerms.password.toLowerCase()}';

  @override
  String get wipeAllDataDialogTitle => 'Wipe All Data';

  @override
  String get wipeAllDataWarning1 => 'WARNING: This action is permanent and will delete:';

  @override
  String get wipeAllDataWarning2 =>
      'All stored ${AppBrandTerms.password.toLowerCase()}s, cards, notes, ${AppBrandTerms.masterPin}, and app settings.';

  @override
  String get wipeAllDataConfirmButton => 'Permanently Delete Everything';

  @override
  String formatAutoLock(int seconds) {
    if (seconds == 0) return 'Immediate';
    if (seconds < 60) return '${seconds}s';
    return '${seconds ~/ 60}m';
  }

  @override
  String formatClipboard(int seconds) {
    if (seconds == 0) return 'Never';
    return '${seconds}s';
  }

  @override
  String get autoLockPickerTitle => 'Auto-Lock Timeout';

  @override
  String get clipboardPickerTitle => 'Clipboard Auto-Clear Timeout';

  @override
  String get autoLockImmediate => 'Immediately on exit';

  @override
  String get autoLock30s => 'After 30 seconds';

  @override
  String get autoLock1m => 'After 1 minute';

  @override
  String get autoLock5m => 'After 5 minutes';

  @override
  String get clipboardDisabled => 'Disabled (Never clear)';

  @override
  String get clipboard15s => '15 seconds';

  @override
  String get clipboard30sRecommended => '30 seconds (Recommended)';

  @override
  String get clipboard60s => '60 seconds';

  @override
  String get privacyShieldTitle => '${AppBrandTerms.appName} Protected';

  @override
  String get privacyShieldSubtitle => 'Screen obscured for your privacy';
}

/// ============================================================================
/// SPANISH LOCALIZATION (Español)
/// ============================================================================
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs() : super(const Locale('es'));

  @override
  String get languageName => 'Español';

  @override
  String get vaultProtectedTitle => '${AppBrandTerms.appName} Protegido';

  @override
  String get enterMasterPinPrompt => 'Introduce tu ${AppBrandTerms.masterPin} para acceder';

  @override
  String get insertMasterPinHint => 'Introduce ${AppBrandTerms.masterPin}';

  @override
  String get unlockVaultButton => 'Desbloquear Bóveda';

  @override
  String get unlockWithBiometricsButton => 'Desbloquear con Biometría / ${AppBrandTerms.faceId}';

  @override
  String get biometricPromptReason => 'Autentícate para acceder a ${AppBrandTerms.appName}';

  @override
  String get biometricDisabledInSettings => 'El desbloqueo biométrico está desactivado';

  @override
  String get biometricFailedOrCanceled => 'Autenticación biométrica fallida o cancelada';

  @override
  String get masterPinIncorrect => '${AppBrandTerms.masterPin} incorrecto';

  @override
  String pinAttemptsRemaining(int remaining) => '${AppBrandTerms.masterPin} incorrecto ($remaining intentos restantes)';

  @override
  String lockoutTimeRemaining(int seconds) => 'Demasiados intentos fallidos. Inténtalo en ${seconds}s';

  @override
  String get currentPinInvalid => '${AppBrandTerms.masterPin} actual no válido';

  @override
  String get welcomeToCaveau => 'Bienvenido a ${AppBrandTerms.appName}';

  @override
  String get onboardingSubtitle => 'Tu bóveda cifrada local para contraseñas y datos confidenciales.';

  @override
  String get hardwareSecurityNotice => 'Tus datos están cifrados en el dispositivo (${AppBrandTerms.androidKeystore} / ${AppBrandTerms.iosKeychain}). Ningún dato sale del teléfono.';

  @override
  String get createMasterPinTitle => 'Crea tu ${AppBrandTerms.masterPin}';

  @override
  String get confirmMasterPinHint => 'Confirmar ${AppBrandTerms.masterPin}';

  @override
  String get minMasterPinError => 'El ${AppBrandTerms.masterPin} debe tener al menos 4 caracteres';

  @override
  String get pinsDoNotMatchError => 'Los ${AppBrandTerms.pin} introducidos no coinciden';

  @override
  String get enableBiometricSwitch => 'Activar Desbloqueo Biométrico (${AppBrandTerms.faceId} / Huella)';

  @override
  String get initializeVaultButton => 'Inicializar ${AppBrandTerms.appName} Seguro';

  @override
  String get searchHint => 'Buscar en la bóveda...';

  @override
  String get allCategoryFilter => 'Todos';

  @override
  String get favoritesFilter => 'Favoritos';

  @override
  String get emptyVaultTitle => 'Tu ${AppBrandTerms.appName} está vacío';

  @override
  String get emptyVaultSubtitle => 'Guarda tus contraseñas, tarjetas y notas con seguridad';

  @override
  String get noSearchResultsTitle => 'No se encontraron resultados';

  @override
  String get noSearchResultsSubtitle => 'Prueba con un término de búsqueda diferente';

  @override
  String get addItemButton => 'Añadir';

  @override
  String get newItemFab => 'Nuevo Elemento';

  @override
  String get whatToSaveTitle => '¿Qué deseas guardar?';

  @override
  String get lockNowTooltip => 'Bloquear ahora';

  @override
  String get passwordGeneratorTooltip => 'Generador de ${AppBrandTerms.password}';

  @override
  String get securityAuditTooltip => 'Auditoría de Seguridad';

  @override
  String get settingsTooltip => 'Ajustes';

  @override
  String categoryDisplayName(VaultCategory category) {
    switch (category) {
      case VaultCategory.login:
        return 'Contraseñas & Cuentas';
      case VaultCategory.card:
        return 'Tarjetas de Pago';
      case VaultCategory.note:
        return 'Notas Cifradas';
      case VaultCategory.identity:
        return 'Identidades & Documentos';
      case VaultCategory.apiKey:
        return 'Claves ${AppBrandTerms.apiKey} / Tokens';
    }
  }

  @override
  String categoryShortName(VaultCategory category) {
    switch (category) {
      case VaultCategory.login:
        return 'Contraseñas';
      case VaultCategory.card:
        return 'Tarjetas';
      case VaultCategory.note:
        return 'Notas';
      case VaultCategory.identity:
        return 'Identidad';
      case VaultCategory.apiKey:
        return AppBrandTerms.api;
    }
  }

  @override
  String categoryDescription(VaultCategory category) {
    switch (category) {
      case VaultCategory.login:
        return 'Credenciales de acceso para sitios web, apps y servicios';
      case VaultCategory.card:
        return 'Tarjetas de crédito, débito, ${AppBrandTerms.cvv} y ${AppBrandTerms.pin}';
      case VaultCategory.note:
        return 'Textos, códigos ${AppBrandTerms.pin} o notas confidenciales';
      case VaultCategory.identity:
        return 'Documentos de identidad, ${AppBrandTerms.email} y datos personales';
      case VaultCategory.apiKey:
        return 'Tokens de acceso, claves privadas y secretos API';
    }
  }

  @override
  String get itemDeletedFallback => 'Elemento Eliminado';

  @override
  String get itemNotFound => 'Elemento no encontrado';

  @override
  String get deleteItemTitle => 'Eliminar Elemento';

  @override
  String deleteItemConfirmMessage(String title) =>
      '¿Estás seguro de que deseas eliminar permanentemente "$title"?\n\nEsta acción no se puede deshacer.';

  @override
  String get cancelButton => 'Cancelar';

  @override
  String get deleteButton => 'Eliminar';

  @override
  String get editButton => 'Editar';

  @override
  String get saveButton => 'Guardar';

  @override
  String get closeButton => 'Cerrar';

  @override
  String get copyButton => 'Copiar';

  @override
  String get generateButton => 'Generar';

  @override
  String get restoreButton => 'Restaurar';

  @override
  String get usernameLabel => 'Nombre de Usuario / ${AppBrandTerms.email}';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get websiteLabel => 'Sitio Web / ${AppBrandTerms.url}';

  @override
  String get notesLabel => 'Notas';

  @override
  String get cardHolderLabel => 'Titular de la Tarjeta';

  @override
  String get cardNumberLabel => 'Número de Tarjeta';

  @override
  String get cardExpiryLabel => 'Fecha de Caducidad';

  @override
  String get cardCvvLabel => '${AppBrandTerms.cvcOrCvv} de Seguridad';

  @override
  String get cardPinLabel => '${AppBrandTerms.pin} de la Tarjeta';

  @override
  String get emailLabel => AppBrandTerms.email;

  @override
  String get phoneLabel => 'Teléfono';

  @override
  String get idNumberLabel => 'DNI / Número de Documento';

  @override
  String get apiKeySecretLabel => 'Clave Secreta / Token';

  @override
  String get customFieldsSection => 'Campos Personalizados';

  @override
  String get securityInfoSection => 'Información de Seguridad';

  @override
  String get createdLabel => 'Creado';

  @override
  String get lastUpdatedLabel => 'Última actualización';

  @override
  String get cardHolderCardMockup => 'TITULAR';

  @override
  String get cardExpiryCardMockup => 'CADUCIDAD';

  @override
  String get copyCardNumber => 'Copiar Número de Tarjeta';

  @override
  String get copyPassword => 'Copiar Contraseña';

  @override
  String get copyNotes => 'Copiar Notas';

  @override
  String get copyIdentity => 'Copiar Documento / ${AppBrandTerms.email}';

  @override
  String get copyApiKey => 'Copiar ${AppBrandTerms.apiKey}';

  @override
  String get noUsername => 'Sin usuario';

  @override
  String get paymentCardSubtitle => 'Tarjeta de pago';

  @override
  String get encryptedNoteSubtitle => 'Nota cifrada';

  @override
  String get encryptedKeySubtitle => 'Clave de seguridad cifrada';

  @override
  String fieldCopiedAutoClear(String fieldLabel, int seconds) =>
      '$fieldLabel copiado (limpieza en ${seconds}s)';

  @override
  String fieldCopied(String fieldLabel) => '$fieldLabel copiado';

  @override
  String get passwordCopiedFeedback => 'Contraseña copiada';

  @override
  String get cardNumberCopiedFeedback => 'Número de tarjeta copiado';

  @override
  String get noteTextCopiedFeedback => 'Texto de nota copiado';

  @override
  String get identityCopiedFeedback => 'Datos de identidad copiados';

  @override
  String get apiKeyCopiedFeedback => '${AppBrandTerms.apiKey} copiada';

  @override
  String get backupCopiedFeedback => 'Copia de seguridad cifrada copiada al portapapeles';

  @override
  String get editItemTitle => 'Editar Elemento';

  @override
  String get newItemTitle => 'Nuevo Elemento';

  @override
  String get titleLabel => 'Título';

  @override
  String get titleRequiredValidation => 'Introduce un título';

  @override
  String get addCustomFieldButton => 'Añadir Campo Personalizado';

  @override
  String get fieldNameLabel => 'Etiqueta del campo';

  @override
  String get fieldValueLabel => 'Valor';

  @override
  String get secretFieldCheckbox => 'Ocultar valor (Dato secreto)';

  @override
  String get optionalLabel => 'opcional';

  @override
  String get passwordGeneratorTitle => 'Generador de Contraseñas';

  @override
  String get lengthSliderLabel => 'Longitud de Contraseña';

  @override
  String get uppercaseOption => 'Letras Mayúsculas (A-Z)';

  @override
  String get lowercaseOption => 'Letras Minúsculas (a-z)';

  @override
  String get numbersOption => 'Números (0-9)';

  @override
  String get symbolsOption => 'Símbolos Especiales (!@#\$%^&*)';

  @override
  String get excludeAmbiguousOption => 'Excluir caracteres ambiguos';

  @override
  String get excludeAmbiguousSubtitle => 'Evita caracteres semejantes como Il1O0';

  @override
  String get usePasswordButton => 'Usar esta Contraseña';

  @override
  String passwordLengthLabel(int length) => '$length caracteres';

  @override
  String passwordEntropyLabel(String entropy) => '$entropy bits de entropía';

  @override
  String passwordStrengthLabel(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.veryWeak:
        return 'Muy Débil';
      case PasswordStrength.weak:
        return 'Débil';
      case PasswordStrength.medium:
        return 'Media';
      case PasswordStrength.strong:
        return 'Fuerte';
      case PasswordStrength.veryStrong:
        return 'Muy Fuerte';
    }
  }

  @override
  String get securityLevelPrefix => 'Seguridad';

  @override
  String get securityAuditTitle => 'Auditoría de Seguridad';

  @override
  String securityScoreLabel(int score) {
    if (score >= 85) return 'Excelente Estado de Seguridad';
    if (score >= 60) return 'Seguridad Moderada';
    return 'Atención: Seguridad en Riesgo';
  }

  @override
  String get auditDescription =>
      'Análisis basado en la robustez, entropía y reutilización de contraseñas guardadas.';

  @override
  String get totalItemsStat => 'Elementos Totales';

  @override
  String get weakPasswordsStat => 'Contraseñas Débiles';

  @override
  String get reusedPasswordsStat => 'Reutilizadas';

  @override
  String get weakPasswordsSection => 'Contraseñas Débiles o Cortas';

  @override
  String get reusedPasswordsSection => 'Contraseñas Duplicadas / Reutilizadas';

  @override
  String get allPasswordsHealthy => '¡Todas tus contraseñas son seguras!';

  @override
  String get allPasswordsHealthySubtitle =>
      'No se han detectado vulnerabilidades en tu ${AppBrandTerms.appName}.';

  @override
  String get weakPasswordTileLabel => 'Contraseña débil';

  @override
  String reusedPasswordTileLabel(int count) => 'Compartida en $count cuentas';

  @override
  String get fixButton => 'Corregir';

  @override
  String get settingsTitle => 'Ajustes de Seguridad';

  @override
  String get sectionLanguage => 'IDIOMA / LANGUAGE';

  @override
  String get sectionAuthAccess => 'AUTENTICACIÓN Y ACCESO';

  @override
  String get sectionPrivacyClipboard => 'PRIVACIDAD Y PORTAPAPELES';

  @override
  String get sectionBackupRestore => 'COPIA DE SEGURIDAD Y RESTAURACIÓN';

  @override
  String get sectionDangerZone => 'ZONA DE PELIGRO';

  @override
  String get languageOptionLabel => 'Idioma';

  @override
  String get languageOptionSubtitle => 'Selecciona el idioma para el texto y la interfaz';

  @override
  String get biometricUnlockTileTitle => 'Desbloqueo Biométrico';

  @override
  String get biometricUnlockTileSubtitle =>
      'Usa ${AppBrandTerms.faceId} o huella dactilar para acceder a ${AppBrandTerms.appName}';

  @override
  String get changeMasterPinTileTitle => 'Modificar ${AppBrandTerms.masterPin}';

  @override
  String get changeMasterPinTileSubtitle => 'Actualiza tu código de acceso principal';

  @override
  String get autoLockTileTitle => 'Bloqueo Automático';

  @override
  String get privacyShieldTileTitle => 'Escudo de Privacidad';

  @override
  String get privacyShieldTileSubtitle => 'Oculta la pantalla en el selector de apps del SO';

  @override
  String get clearClipboardTileTitle => 'Limpieza Automática del Portapapeles';

  @override
  String get exportBackupTileTitle => 'Exportar Copia Cifrada';

  @override
  String get exportBackupTileSubtitle => 'Guarda una copia protegida con contraseña';

  @override
  String get restoreBackupTileTitle => 'Restaurar Copia de Seguridad';

  @override
  String get restoreBackupTileSubtitle => 'Importa datos cifrados desde una copia previa';

  @override
  String get wipeAllDataTileTitle => 'Borrar y Restablecer ${AppBrandTerms.appName}';

  @override
  String get wipeAllDataTileSubtitle => 'Elimina permanentemente todos los datos y ajustes';

  @override
  String get selectLanguageTitle => 'Seleccionar Idioma';

  @override
  String get changePinDialogTitle => 'Modificar ${AppBrandTerms.masterPin}';

  @override
  String get currentPinFieldLabel => '${AppBrandTerms.masterPin} Actual';

  @override
  String get newPinFieldLabel => 'Nuevo ${AppBrandTerms.masterPin}';

  @override
  String get confirmNewPinFieldLabel => 'Confirmar Nuevo ${AppBrandTerms.masterPin}';

  @override
  String get pinMinCharsError => 'El ${AppBrandTerms.masterPin} debe tener al menos 4 caracteres';

  @override
  String get newPinsDoNotMatchError => 'Los nuevos ${AppBrandTerms.pin} no coinciden';

  @override
  String get pinUpdatedSuccess => '${AppBrandTerms.masterPin} actualizado con éxito';

  @override
  String get exportBackupDialogTitle => 'Exportar Copia Cifrada';

  @override
  String get exportBackupInstructions =>
      'Introduce una contraseña para cifrar el archivo con ${AppBrandTerms.aes256}. Conserva esta contraseña con cuidado.';

  @override
  String get backupPasswordFieldLabel => 'Contraseña de cifrado de la copia';

  @override
  String get backupPasswordMinCharsError => 'Introduce una contraseña de al menos 6 caracteres';

  @override
  String get backupGeneratedDialogTitle => 'Copia de Seguridad Cifrada Generada';

  @override
  String get backupCopyWarning =>
      'Copia y guarda esta cadena cifrada en un lugar seguro. Sin la contraseña será imposible descifrarla.';

  @override
  String get restoreBackupDialogTitle => 'Restaurar desde Copia de Seguridad';

  @override
  String get pasteBackupDataLabel => 'Pega aquí la cadena cifrada de la copia';

  @override
  String get fillAllFieldsError => 'Rellena todos los campos requeridos';

  @override
  String itemsRestoredSuccess(int count) => '¡$count elementos restaurados con éxito!';

  @override
  String get restoreFailedError => 'Restauración fallida: datos no válidos o contraseña incorrecta';

  @override
  String get wipeAllDataDialogTitle => 'Eliminación Total de Datos';

  @override
  String get wipeAllDataWarning1 => 'ATENCIÓN: Esta acción borrará de forma irreversible:';

  @override
  String get wipeAllDataWarning2 =>
      'Todas las contraseñas, tarjetas, notas, ${AppBrandTerms.masterPin} y ajustes guardados.';

  @override
  String get wipeAllDataConfirmButton => 'Eliminar Todo Definitivamente';

  @override
  String formatAutoLock(int seconds) {
    if (seconds == 0) return 'Inmediato';
    if (seconds < 60) return '${seconds}s';
    return '${seconds ~/ 60}m';
  }

  @override
  String formatClipboard(int seconds) {
    if (seconds == 0) return 'Nunca';
    return '${seconds}s';
  }

  @override
  String get autoLockPickerTitle => 'Tiempo de Bloqueo Automático';

  @override
  String get clipboardPickerTitle => 'Tiempo de Limpieza del Portapapeles';

  @override
  String get autoLockImmediate => 'Inmediato (al salir)';

  @override
  String get autoLock30s => 'Tras 30 segundos';

  @override
  String get autoLock1m => 'Tras 1 minuto';

  @override
  String get autoLock5m => 'Tras 5 minutos';

  @override
  String get clipboardDisabled => 'Desactivado (No limpiar)';

  @override
  String get clipboard15s => '15 segundos';

  @override
  String get clipboard30sRecommended => '30 segundos (Recomendado)';

  @override
  String get clipboard60s => '60 segundos';

  @override
  String get privacyShieldTitle => '${AppBrandTerms.appName} Protegido';

  @override
  String get privacyShieldSubtitle => 'Pantalla oculta por tu privacidad';
}

/// ============================================================================
/// FRENCH LOCALIZATION (Français)
/// ============================================================================
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr() : super(const Locale('fr'));

  @override
  String get languageName => 'Français';

  @override
  String get vaultProtectedTitle => '${AppBrandTerms.appName} Protégé';

  @override
  String get enterMasterPinPrompt => 'Saisissez votre ${AppBrandTerms.masterPin} pour accéder';

  @override
  String get insertMasterPinHint => 'Saisir ${AppBrandTerms.masterPin}';

  @override
  String get unlockVaultButton => 'Déverrouiller le Coffre';

  @override
  String get unlockWithBiometricsButton => 'Déverrouiller avec Biométrie / ${AppBrandTerms.faceId}';

  @override
  String get biometricPromptReason => 'Authentifiez-vous pour accéder à ${AppBrandTerms.appName}';

  @override
  String get biometricDisabledInSettings => 'Le déverrouillage biométrique est désactivé';

  @override
  String get biometricFailedOrCanceled => 'Authentification biométrique échouée ou annulée';

  @override
  String get masterPinIncorrect => '${AppBrandTerms.masterPin} incorrect';

  @override
  String pinAttemptsRemaining(int remaining) => '${AppBrandTerms.masterPin} incorrect ($remaining tentatives restantes)';

  @override
  String lockoutTimeRemaining(int seconds) => 'Trop de tentatives échouées. Réessayez dans ${seconds}s';

  @override
  String get currentPinInvalid => '${AppBrandTerms.masterPin} actuel non valide';

  @override
  String get welcomeToCaveau => 'Bienvenue sur ${AppBrandTerms.appName}';

  @override
  String get onboardingSubtitle => 'Votre coffre-fort chiffré local pour mots de passe et données sensibles.';

  @override
  String get hardwareSecurityNotice => 'Vos données sont chiffrées sur l\'appareil (${AppBrandTerms.androidKeystore} / ${AppBrandTerms.iosKeychain}). Aucune donnée ne quitte votre téléphone.';

  @override
  String get createMasterPinTitle => 'Créez votre ${AppBrandTerms.masterPin}';

  @override
  String get confirmMasterPinHint => 'Confirmer le ${AppBrandTerms.masterPin}';

  @override
  String get minMasterPinError => 'Le ${AppBrandTerms.masterPin} doit contenir au moins 4 caractères';

  @override
  String get pinsDoNotMatchError => 'Les ${AppBrandTerms.pin} saisis ne correspondent pas';

  @override
  String get enableBiometricSwitch => 'Activer le Déverrouillage Biométrique (${AppBrandTerms.faceId} / Empreinte)';

  @override
  String get initializeVaultButton => 'Initialiser ${AppBrandTerms.appName} Sécurisé';

  @override
  String get searchHint => 'Rechercher dans le coffre...';

  @override
  String get allCategoryFilter => 'Tous';

  @override
  String get favoritesFilter => 'Favoris';

  @override
  String get emptyVaultTitle => 'Votre ${AppBrandTerms.appName} est vide';

  @override
  String get emptyVaultSubtitle => 'Enregistrez vos mots de passe, cartes et notes en toute sécurité';

  @override
  String get noSearchResultsTitle => 'Aucun résultat trouvé';

  @override
  String get noSearchResultsSubtitle => 'Essayez avec un autre mot-clé';

  @override
  String get addItemButton => 'Ajouter';

  @override
  String get newItemFab => 'Nouvel Élément';

  @override
  String get whatToSaveTitle => 'Que souhaitez-vous enregistrer ?';

  @override
  String get lockNowTooltip => 'Verrouiller maintenant';

  @override
  String get passwordGeneratorTooltip => 'Générateur de Mots de Passe';

  @override
  String get securityAuditTooltip => 'Audit de Sécurité';

  @override
  String get settingsTooltip => 'Paramètres';

  @override
  String categoryDisplayName(VaultCategory category) {
    switch (category) {
      case VaultCategory.login:
        return 'Mots de Passe & Comptes';
      case VaultCategory.card:
        return 'Cartes Bancaires';
      case VaultCategory.note:
        return 'Notes Chiffrées';
      case VaultCategory.identity:
        return 'Identités & Documents';
      case VaultCategory.apiKey:
        return 'Clés ${AppBrandTerms.apiKey} / Jetons';
    }
  }

  @override
  String categoryShortName(VaultCategory category) {
    switch (category) {
      case VaultCategory.login:
        return 'Mots de Passe';
      case VaultCategory.card:
        return 'Cartes';
      case VaultCategory.note:
        return 'Notes';
      case VaultCategory.identity:
        return 'Identité';
      case VaultCategory.apiKey:
        return AppBrandTerms.api;
    }
  }

  @override
  String categoryDescription(VaultCategory category) {
    switch (category) {
      case VaultCategory.login:
        return 'Identifiants pour sites web, apps et services numériques';
      case VaultCategory.card:
        return 'Cartes de crédit, débit, ${AppBrandTerms.cvv} et code ${AppBrandTerms.pin}';
      case VaultCategory.note:
        return 'Textes, codes ${AppBrandTerms.pin} ou notes chiffrées';
      case VaultCategory.identity:
        return 'Pièces d\'identité, ${AppBrandTerms.email} et données personnelles';
      case VaultCategory.apiKey:
        return 'Clés d\'accès privées, jetons de sécurité et secrets API';
    }
  }

  @override
  String get itemDeletedFallback => 'Élément Supprimé';

  @override
  String get itemNotFound => 'Élément introuvable';

  @override
  String get deleteItemTitle => 'Supprimer l\'Élément';

  @override
  String deleteItemConfirmMessage(String title) =>
      'Êtes-vous sûr de vouloir supprimer définitivement "$title" ?\n\nCette action est irréversible.';

  @override
  String get cancelButton => 'Annuler';

  @override
  String get deleteButton => 'Supprimer';

  @override
  String get editButton => 'Modifier';

  @override
  String get saveButton => 'Enregistrer';

  @override
  String get closeButton => 'Fermer';

  @override
  String get copyButton => 'Copier';

  @override
  String get generateButton => 'Générer';

  @override
  String get restoreButton => 'Restaurer';

  @override
  String get usernameLabel => 'Identifiant / ${AppBrandTerms.email}';

  @override
  String get passwordLabel => 'Mot de Passe';

  @override
  String get websiteLabel => 'Site Web / ${AppBrandTerms.url}';

  @override
  String get notesLabel => 'Notes';

  @override
  String get cardHolderLabel => 'Titulaire de la Carte';

  @override
  String get cardNumberLabel => 'Numéro de Carte';

  @override
  String get cardExpiryLabel => 'Date d\'Expiration';

  @override
  String get cardCvvLabel => '${AppBrandTerms.cvcOrCvv} de Sécurité';

  @override
  String get cardPinLabel => '${AppBrandTerms.pin} de la Carte';

  @override
  String get emailLabel => AppBrandTerms.email;

  @override
  String get phoneLabel => 'Téléphone';

  @override
  String get idNumberLabel => 'Numéro de Pièce d\'Identité';

  @override
  String get apiKeySecretLabel => 'Clé Secrète / Jeton';

  @override
  String get customFieldsSection => 'Champs Personnalisés';

  @override
  String get securityInfoSection => 'Informations de Sécurité';

  @override
  String get createdLabel => 'Créé';

  @override
  String get lastUpdatedLabel => 'Dernière modification';

  @override
  String get cardHolderCardMockup => 'TITULAIRE';

  @override
  String get cardExpiryCardMockup => 'EXPIRATION';

  @override
  String get copyCardNumber => 'Copier le Numéro de Carte';

  @override
  String get copyPassword => 'Copier le Mot de Passe';

  @override
  String get copyNotes => 'Copier les Notes';

  @override
  String get copyIdentity => 'Copier le Document / ${AppBrandTerms.email}';

  @override
  String get copyApiKey => 'Copier la Clé ${AppBrandTerms.apiKey}';

  @override
  String get noUsername => 'Aucun identifiant';

  @override
  String get paymentCardSubtitle => 'Carte bancaire';

  @override
  String get encryptedNoteSubtitle => 'Note chiffrée';

  @override
  String get encryptedKeySubtitle => 'Clé de sécurité chiffrée';

  @override
  String fieldCopiedAutoClear(String fieldLabel, int seconds) =>
      '$fieldLabel copié (effacement dans ${seconds}s)';

  @override
  String fieldCopied(String fieldLabel) => '$fieldLabel copié';

  @override
  String get passwordCopiedFeedback => 'Mot de passe copié';

  @override
  String get cardNumberCopiedFeedback => 'Numéro de carte copié';

  @override
  String get noteTextCopiedFeedback => 'Texte de note copié';

  @override
  String get identityCopiedFeedback => 'Données d\'identité copiées';

  @override
  String get apiKeyCopiedFeedback => '${AppBrandTerms.apiKey} copiée';

  @override
  String get backupCopiedFeedback => 'Sauvegarde chiffrée copiée dans le presse-papiers';

  @override
  String get editItemTitle => 'Modifier l\'Élément';

  @override
  String get newItemTitle => 'Nouvel Élément';

  @override
  String get titleLabel => 'Titre';

  @override
  String get titleRequiredValidation => 'Veuillez saisir un titre';

  @override
  String get addCustomFieldButton => 'Ajouter un Champ Personnalisé';

  @override
  String get fieldNameLabel => 'Étiquette du champ';

  @override
  String get fieldValueLabel => 'Valeur';

  @override
  String get secretFieldCheckbox => 'Masquer la valeur (Donnée secrète)';

  @override
  String get optionalLabel => 'optionnel';

  @override
  String get passwordGeneratorTitle => 'Générateur de Mots de Passe';

  @override
  String get lengthSliderLabel => 'Longueur du Mot de Passe';

  @override
  String get uppercaseOption => 'Lettres Majuscules (A-Z)';

  @override
  String get lowercaseOption => 'Lettres Minuscules (a-z)';

  @override
  String get numbersOption => 'Chiffres (0-9)';

  @override
  String get symbolsOption => 'Symboles Spéciaux (!@#\$%^&*)';

  @override
  String get excludeAmbiguousOption => 'Exclure les caractères ambigus';

  @override
  String get excludeAmbiguousSubtitle => 'Évite les caractères similaires comme Il1O0';

  @override
  String get usePasswordButton => 'Utiliser ce Mot de Passe';

  @override
  String passwordLengthLabel(int length) => '$length caractères';

  @override
  String passwordEntropyLabel(String entropy) => '$entropy bits d\'entropie';

  @override
  String passwordStrengthLabel(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.veryWeak:
        return 'Très Faible';
      case PasswordStrength.weak:
        return 'Faible';
      case PasswordStrength.medium:
        return 'Moyen';
      case PasswordStrength.strong:
        return 'Fort';
      case PasswordStrength.veryStrong:
        return 'Très Fort';
    }
  }

  @override
  String get securityLevelPrefix => 'Sécurité';

  @override
  String get securityAuditTitle => 'Audit de Sécurité';

  @override
  String securityScoreLabel(int score) {
    if (score >= 85) return 'Excellent Niveau de Sécurité';
    if (score >= 60) return 'Sécurité Modérée';
    return 'Attention : Sécurité à Risque';
  }

  @override
  String get auditDescription =>
      'Analyse basée sur la robustesse, l\'entropie et la réutilisation des mots de passe.';

  @override
  String get totalItemsStat => 'Éléments Totaux';

  @override
  String get weakPasswordsStat => 'Mots de Passe Faibles';

  @override
  String get reusedPasswordsStat => 'Réutilisés';

  @override
  String get weakPasswordsSection => 'Mots de Passe Faibles ou Courts';

  @override
  String get reusedPasswordsSection => 'Mots de Passe Dupliqués / Réutilisés';

  @override
  String get allPasswordsHealthy => 'Tous vos mots de passe sont sûrs !';

  @override
  String get allPasswordsHealthySubtitle =>
      'Aucune vulnérabilité détectée dans votre ${AppBrandTerms.appName}.';

  @override
  String get weakPasswordTileLabel => 'Mot de passe faible';

  @override
  String reusedPasswordTileLabel(int count) => 'Partagé sur $count comptes';

  @override
  String get fixButton => 'Corriger';

  @override
  String get settingsTitle => 'Paramètres de Sécurité';

  @override
  String get sectionLanguage => 'LANGUE / LANGUAGE';

  @override
  String get sectionAuthAccess => 'AUTHENTIFICATION & ACCÈS';

  @override
  String get sectionPrivacyClipboard => 'CONFIDENTIALITÉ & PRESSE-PAPIERS';

  @override
  String get sectionBackupRestore => 'SAUVEGARDE & RESTAURATION';

  @override
  String get sectionDangerZone => 'ZONE DE DANGER';

  @override
  String get languageOptionLabel => 'Langue';

  @override
  String get languageOptionSubtitle => 'Sélectionnez la langue des textes et de l\'interface';

  @override
  String get biometricUnlockTileTitle => 'Déverrouillage Biométrique';

  @override
  String get biometricUnlockTileSubtitle =>
      'Exiger ${AppBrandTerms.faceId} ou empreinte pour déverrouiller ${AppBrandTerms.appName}';

  @override
  String get changeMasterPinTileTitle => 'Modifier le ${AppBrandTerms.masterPin}';

  @override
  String get changeMasterPinTileSubtitle => 'Mettre à jour le code d\'accès principal';

  @override
  String get autoLockTileTitle => 'Verrouillage Automatique';

  @override
  String get privacyShieldTileTitle => 'Bouclier de Confidentialité';

  @override
  String get privacyShieldTileSubtitle => 'Masque l\'écran dans le multitâche du système';

  @override
  String get clearClipboardTileTitle => 'Effacement Automatique du Presse-papiers';

  @override
  String get exportBackupTileTitle => 'Exporter une Sauvegarde Chiffrée';

  @override
  String get exportBackupTileSubtitle => 'Enregistrer une copie protégée par mot de passe';

  @override
  String get restoreBackupTileTitle => 'Restaurer une Sauvegarde';

  @override
  String get restoreBackupTileSubtitle => 'Importer des données chiffrées antérieures';

  @override
  String get wipeAllDataTileTitle => 'Effacer et Réinitialiser ${AppBrandTerms.appName}';

  @override
  String get wipeAllDataTileSubtitle => 'Supprimer définitivement toutes les données et réglages';

  @override
  String get selectLanguageTitle => 'Sélectionner la Langue';

  @override
  String get changePinDialogTitle => 'Modifier le ${AppBrandTerms.masterPin}';

  @override
  String get currentPinFieldLabel => '${AppBrandTerms.masterPin} Actuel';

  @override
  String get newPinFieldLabel => 'Nouveau ${AppBrandTerms.masterPin}';

  @override
  String get confirmNewPinFieldLabel => 'Confirmer le Nouveau ${AppBrandTerms.masterPin}';

  @override
  String get pinMinCharsError => 'Le ${AppBrandTerms.masterPin} doit comporter au moins 4 caractères';

  @override
  String get newPinsDoNotMatchError => 'Les nouveaux ${AppBrandTerms.pin} ne correspondent pas';

  @override
  String get pinUpdatedSuccess => '${AppBrandTerms.masterPin} mis à jour avec succès';

  @override
  String get exportBackupDialogTitle => 'Exporter une Sauvegarde Chiffrée';

  @override
  String get exportBackupInstructions =>
      'Saisissez un mot de passe pour chiffrer la sauvegarde en ${AppBrandTerms.aes256}. Conservez-le précieusement.';

  @override
  String get backupPasswordFieldLabel => 'Mot de passe de chiffrement';

  @override
  String get backupPasswordMinCharsError => 'Saisissez un mot de passe d\'au moins 6 caractères';

  @override
  String get backupGeneratedDialogTitle => 'Sauvegarde Chiffrée Générée';

  @override
  String get backupCopyWarning =>
      'Copiez et conservez cette chaîne chiffrée en lieu sûr. Sans le mot de passe, elle sera irrécupérable.';

  @override
  String get restoreBackupDialogTitle => 'Restaurer depuis une Sauvegarde';

  @override
  String get pasteBackupDataLabel => 'Collez la chaîne de sauvegarde chiffrée';

  @override
  String get fillAllFieldsError => 'Veuillez remplir tous les champs requis';

  @override
  String itemsRestoredSuccess(int count) => '$count éléments restaurés avec succès !';

  @override
  String get restoreFailedError => 'Échec de la restauration : données invalides ou mot de passe incorrect';

  @override
  String get wipeAllDataDialogTitle => 'Suppression Totale des Données';

  @override
  String get wipeAllDataWarning1 => 'ATTENTION : Cette action supprimera définitivement :';

  @override
  String get wipeAllDataWarning2 =>
      'Tous les mots de passe, cartes, notes, ${AppBrandTerms.masterPin} et paramètres sauvegardés.';

  @override
  String get wipeAllDataConfirmButton => 'Tout Supprimer Définitivement';

  @override
  String formatAutoLock(int seconds) {
    if (seconds == 0) return 'Immédiat';
    if (seconds < 60) return '${seconds}s';
    return '${seconds ~/ 60}m';
  }

  @override
  String formatClipboard(int seconds) {
    if (seconds == 0) return 'Jamais';
    return '${seconds}s';
  }

  @override
  String get autoLockPickerTitle => 'Délai de Verrouillage Automatique';

  @override
  String get clipboardPickerTitle => 'Délai d\'Effacement du Presse-papiers';

  @override
  String get autoLockImmediate => 'Immédiat (à la sortie)';

  @override
  String get autoLock30s => 'Après 30 secondes';

  @override
  String get autoLock1m => 'Après 1 minute';

  @override
  String get autoLock5m => 'Après 5 minutes';

  @override
  String get clipboardDisabled => 'Désactivé (Ne jamais effacer)';

  @override
  String get clipboard15s => '15 secondes';

  @override
  String get clipboard30sRecommended => '30 secondes (Recommandé)';

  @override
  String get clipboard60s => '60 secondes';

  @override
  String get privacyShieldTitle => '${AppBrandTerms.appName} Protégé';

  @override
  String get privacyShieldSubtitle => 'Écran masqué pour votre confidentialité';
}

/// ============================================================================
/// GERMAN LOCALIZATION (Deutsch)
/// ============================================================================
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe() : super(const Locale('de'));

  @override
  String get languageName => 'Deutsch';

  @override
  String get vaultProtectedTitle => '${AppBrandTerms.appName} Geschützt';

  @override
  String get enterMasterPinPrompt => 'Geben Sie Ihre ${AppBrandTerms.masterPin} ein';

  @override
  String get insertMasterPinHint => '${AppBrandTerms.masterPin} eingeben';

  @override
  String get unlockVaultButton => 'Tresor Entsperren';

  @override
  String get unlockWithBiometricsButton => 'Mit Biometrie / ${AppBrandTerms.faceId} entsperren';

  @override
  String get biometricPromptReason => 'Authentifizieren Sie sich für ${AppBrandTerms.appName}';

  @override
  String get biometricDisabledInSettings => 'Biometrische Entsperrung ist deaktiviert';

  @override
  String get biometricFailedOrCanceled => 'Biometrische Authentifizierung fehlgeschlagen oder abgebrochen';

  @override
  String get masterPinIncorrect => '${AppBrandTerms.masterPin} ist falsch';

  @override
  String pinAttemptsRemaining(int remaining) => '${AppBrandTerms.masterPin} falsch ($remaining Versuche verbleibend)';

  @override
  String lockoutTimeRemaining(int seconds) => 'Zu viele Fehlversuche. Versuchen Sie es in ${seconds}s erneut';

  @override
  String get currentPinInvalid => 'Aktuelle ${AppBrandTerms.masterPin} ungültig';

  @override
  String get welcomeToCaveau => 'Willkommen bei ${AppBrandTerms.appName}';

  @override
  String get onboardingSubtitle => 'Ihr lokaler, verschlüsselter Tresor für Passwörter und vertrauliche Daten.';

  @override
  String get hardwareSecurityNotice => 'Ihre Daten werden auf dem Gerät verschlüsselt (${AppBrandTerms.androidKeystore} / ${AppBrandTerms.iosKeychain}). Keine Daten verlassen das Telefon.';

  @override
  String get createMasterPinTitle => 'Erstellen Sie Ihre ${AppBrandTerms.masterPin}';

  @override
  String get confirmMasterPinHint => '${AppBrandTerms.masterPin} bestätigen';

  @override
  String get minMasterPinError => 'Die ${AppBrandTerms.masterPin} muss mindestens 4 Zeichen lang sein';

  @override
  String get pinsDoNotMatchError => 'Die eingegebenen ${AppBrandTerms.pin}-Codes stimmen nicht überein';

  @override
  String get enableBiometricSwitch => 'Biometrische Entsperrung aktivieren (${AppBrandTerms.faceId} / Fingerabdruck)';

  @override
  String get initializeVaultButton => 'Sicheren ${AppBrandTerms.appName} Initialisieren';

  @override
  String get searchHint => 'Im Tresor suchen...';

  @override
  String get allCategoryFilter => 'Alle';

  @override
  String get favoritesFilter => 'Favoriten';

  @override
  String get emptyVaultTitle => 'Ihr ${AppBrandTerms.appName} ist leer';

  @override
  String get emptyVaultSubtitle => 'Speichern Sie Ihre Passwörter, Karten und Notizen sicher';

  @override
  String get noSearchResultsTitle => 'Keine Ergebnisse gefunden';

  @override
  String get noSearchResultsSubtitle => 'Versuchen Sie einen anderen Suchbegriff';

  @override
  String get addItemButton => 'Hinzufügen';

  @override
  String get newItemFab => 'Neuer Eintrag';

  @override
  String get whatToSaveTitle => 'Was möchten Sie speichern?';

  @override
  String get lockNowTooltip => 'Jetzt sperren';

  @override
  String get passwordGeneratorTooltip => 'Passwort-Generator';

  @override
  String get securityAuditTooltip => 'Sicherheitsprüfung';

  @override
  String get settingsTooltip => 'Einstellungen';

  @override
  String categoryDisplayName(VaultCategory category) {
    switch (category) {
      case VaultCategory.login:
        return 'Passwörter & Konten';
      case VaultCategory.card:
        return 'Zahlungskarten';
      case VaultCategory.note:
        return 'Verschlüsselte Notizen';
      case VaultCategory.identity:
        return 'Identitäten & Dokumente';
      case VaultCategory.apiKey:
        return '${AppBrandTerms.apiKey}-Schlüssel / Token';
    }
  }

  @override
  String categoryShortName(VaultCategory category) {
    switch (category) {
      case VaultCategory.login:
        return 'Passwörter';
      case VaultCategory.card:
        return 'Karten';
      case VaultCategory.note:
        return 'Notizen';
      case VaultCategory.identity:
        return 'Identität';
      case VaultCategory.apiKey:
        return AppBrandTerms.api;
    }
  }

  @override
  String categoryDescription(VaultCategory category) {
    switch (category) {
      case VaultCategory.login:
        return 'Anmeldedaten für Webseiten, Apps und digitale Dienste';
      case VaultCategory.card:
        return 'Kredit-, Debitkarten, ${AppBrandTerms.cvv} und ${AppBrandTerms.pin}';
      case VaultCategory.note:
        return 'Texte, ${AppBrandTerms.pin}-Codes oder vertrauliche Notizen';
      case VaultCategory.identity:
        return 'Ausweise, ${AppBrandTerms.email}-Adressen und persönliche Daten';
      case VaultCategory.apiKey:
        return 'Zugriffstoken, private Schlüssel und API-Geheimnisse';
    }
  }

  @override
  String get itemDeletedFallback => 'Eintrag Gelöscht';

  @override
  String get itemNotFound => 'Eintrag nicht gefunden';

  @override
  String get deleteItemTitle => 'Eintrag Löschen';

  @override
  String deleteItemConfirmMessage(String title) =>
      'Sind Sie sicher, dass Sie "$title" dauerhaft löschen möchten?\n\nDiese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get cancelButton => 'Abbrechen';

  @override
  String get deleteButton => 'Löschen';

  @override
  String get editButton => 'Bearbeiten';

  @override
  String get saveButton => 'Speichern';

  @override
  String get closeButton => 'Schließen';

  @override
  String get copyButton => 'Kopieren';

  @override
  String get generateButton => 'Generieren';

  @override
  String get restoreButton => 'Wiederherstellen';

  @override
  String get usernameLabel => 'Benutzername / ${AppBrandTerms.email}';

  @override
  String get passwordLabel => 'Passwort';

  @override
  String get websiteLabel => 'Webseite / ${AppBrandTerms.url}';

  @override
  String get notesLabel => 'Notizen';

  @override
  String get cardHolderLabel => 'Karteninhaber';

  @override
  String get cardNumberLabel => 'Kartennummer';

  @override
  String get cardExpiryLabel => 'Ablaufdatum';

  @override
  String get cardCvvLabel => 'Sicherheits-${AppBrandTerms.cvcOrCvv}';

  @override
  String get cardPinLabel => 'Karten-${AppBrandTerms.pin}';

  @override
  String get emailLabel => AppBrandTerms.email;

  @override
  String get phoneLabel => 'Telefon';

  @override
  String get idNumberLabel => 'Ausweisnummer / Dokument';

  @override
  String get apiKeySecretLabel => 'Geheimer Schlüssel / Token';

  @override
  String get customFieldsSection => 'Benutzerdefinierte Felder';

  @override
  String get securityInfoSection => 'Sicherheitsinformationen';

  @override
  String get createdLabel => 'Erstellt';

  @override
  String get lastUpdatedLabel => 'Zuletzt geändert';

  @override
  String get cardHolderCardMockup => 'KARTENINHABER';

  @override
  String get cardExpiryCardMockup => 'GÜLTIG BIS';

  @override
  String get copyCardNumber => 'Kartennummer Kopieren';

  @override
  String get copyPassword => 'Passwort Kopieren';

  @override
  String get copyNotes => 'Notizen Kopieren';

  @override
  String get copyIdentity => 'Ausweis / ${AppBrandTerms.email} Kopieren';

  @override
  String get copyApiKey => '${AppBrandTerms.apiKey} Kopieren';

  @override
  String get noUsername => 'Kein Benutzername';

  @override
  String get paymentCardSubtitle => 'Zahlungskarte';

  @override
  String get encryptedNoteSubtitle => 'Verschlüsselte Notiz';

  @override
  String get encryptedKeySubtitle => 'Verschlüsselter Sicherheitsschlüssel';

  @override
  String fieldCopiedAutoClear(String fieldLabel, int seconds) =>
      '$fieldLabel kopiert (löschen in ${seconds}s)';

  @override
  String fieldCopied(String fieldLabel) => '$fieldLabel kopiert';

  @override
  String get passwordCopiedFeedback => 'Passwort kopiert';

  @override
  String get cardNumberCopiedFeedback => 'Kartennummer kopiert';

  @override
  String get noteTextCopiedFeedback => 'Notiztext kopiert';

  @override
  String get identityCopiedFeedback => 'Identitätsdaten kopiert';

  @override
  String get apiKeyCopiedFeedback => '${AppBrandTerms.apiKey} kopiert';

  @override
  String get backupCopiedFeedback => 'Verschlüsseltes Backup in die Zwischenablage kopiert';

  @override
  String get editItemTitle => 'Eintrag Bearbeiten';

  @override
  String get newItemTitle => 'Neuer Eintrag';

  @override
  String get titleLabel => 'Titel';

  @override
  String get titleRequiredValidation => 'Bitte geben Sie einen Titel ein';

  @override
  String get addCustomFieldButton => 'Benutzerdefiniertes Feld Hinzufügen';

  @override
  String get fieldNameLabel => 'Feldbezeichnung';

  @override
  String get fieldValueLabel => 'Wert';

  @override
  String get secretFieldCheckbox => 'Wert verbergen (Geheimes Datum)';

  @override
  String get optionalLabel => 'optional';

  @override
  String get passwordGeneratorTitle => 'Passwort-Generator';

  @override
  String get lengthSliderLabel => 'Passwortlänge';

  @override
  String get uppercaseOption => 'Großbuchstaben (A-Z)';

  @override
  String get lowercaseOption => 'Kleinbuchstaben (a-z)';

  @override
  String get numbersOption => 'Zahlen (0-9)';

  @override
  String get symbolsOption => 'Sonderzeichen (!@#\$%^&*)';

  @override
  String get excludeAmbiguousOption => 'Ähnliche Zeichen ausschließen';

  @override
  String get excludeAmbiguousSubtitle => 'Vermeidet Verwechslungen wie Il1O0';

  @override
  String get usePasswordButton => 'Dieses Passwort Verwenden';

  @override
  String passwordLengthLabel(int length) => '$length Zeichen';

  @override
  String passwordEntropyLabel(String entropy) => '$entropy Bits Entropie';

  @override
  String passwordStrengthLabel(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.veryWeak:
        return 'Sehr Schwach';
      case PasswordStrength.weak:
        return 'Schwach';
      case PasswordStrength.medium:
        return 'Mittel';
      case PasswordStrength.strong:
        return 'Stark';
      case PasswordStrength.veryStrong:
        return 'Sehr Stark';
    }
  }

  @override
  String get securityLevelPrefix => 'Sicherheit';

  @override
  String get securityAuditTitle => 'Sicherheitsprüfung';

  @override
  String securityScoreLabel(int score) {
    if (score >= 85) return 'Hervorragender Sicherheitszustand';
    if (score >= 60) return 'Mäßige Sicherheit';
    return 'Warnung: Sicherheitsrisiko erkannt';
  }

  @override
  String get auditDescription =>
      'Analyse basierend auf Stärke, Entropie und Wiederverwendung gespeicherter Passwörter.';

  @override
  String get totalItemsStat => 'Gesamteinträge';

  @override
  String get weakPasswordsStat => 'Schwache Passwörter';

  @override
  String get reusedPasswordsStat => 'Wiederverwendet';

  @override
  String get weakPasswordsSection => 'Schwache oder zu kurze Passwörter';

  @override
  String get reusedPasswordsSection => 'Doppelte / Wiederverwendete Passwörter';

  @override
  String get allPasswordsHealthy => 'Alle Ihre Passwörter sind sicher!';

  @override
  String get allPasswordsHealthySubtitle =>
      'Keine Schwachstellen in Ihrem ${AppBrandTerms.appName} gefunden.';

  @override
  String get weakPasswordTileLabel => 'Schwaches Passwort';

  @override
  String reusedPasswordTileLabel(int count) => 'In $count Konten verwendet';

  @override
  String get fixButton => 'Beheben';

  @override
  String get settingsTitle => 'Sicherheitseinstellungen';

  @override
  String get sectionLanguage => 'SPRACHE / LANGUAGE';

  @override
  String get sectionAuthAccess => 'AUTHENTIFIZIERUNG & ZUGANG';

  @override
  String get sectionPrivacyClipboard => 'DATENSCHUTZ & ZWISCHENABLAGE';

  @override
  String get sectionBackupRestore => 'SICHERUNG & WIEDERHERSTELLUNG';

  @override
  String get sectionDangerZone => 'GEFAHRENZONE';

  @override
  String get languageOptionLabel => 'Sprache';

  @override
  String get languageOptionSubtitle => 'Wählen Sie die Sprache für Texte und Benutzeroberfläche';

  @override
  String get biometricUnlockTileTitle => 'Biometrische Entsperrung';

  @override
  String get biometricUnlockTileSubtitle =>
      '${AppBrandTerms.faceId} oder Fingerabdruck anfordern, um ${AppBrandTerms.appName} zu entsperren';

  @override
  String get changeMasterPinTileTitle => '${AppBrandTerms.masterPin} Ändern';

  @override
  String get changeMasterPinTileSubtitle => 'Hauptzugangscode aktualisieren';

  @override
  String get autoLockTileTitle => 'Automatische Sperre';

  @override
  String get privacyShieldTileTitle => 'Datenschutz-Schild';

  @override
  String get privacyShieldTileSubtitle => 'Verdeckt den Bildschirm in der App-Übersicht des Systems';

  @override
  String get clearClipboardTileTitle => 'Zwischenablage Automatisch Leeren';

  @override
  String get exportBackupTileTitle => 'Verschlüsseltes Backup Exportieren';

  @override
  String get exportBackupTileSubtitle => 'Passwortgeschützte Kopie aller Daten speichern';

  @override
  String get restoreBackupTileTitle => 'Backup Wiederherstellen';

  @override
  String get restoreBackupTileSubtitle => 'Verschlüsselte Daten aus einem früheren Backup importieren';

  @override
  String get wipeAllDataTileTitle => '${AppBrandTerms.appName} Löschen und Zurücksetzen';

  @override
  String get wipeAllDataTileSubtitle => 'Alle gespeicherten Zugangsdaten und Einstellungen dauerhaft löschen';

  @override
  String get selectLanguageTitle => 'Sprache Auswählen';

  @override
  String get changePinDialogTitle => '${AppBrandTerms.masterPin} Ändern';

  @override
  String get currentPinFieldLabel => 'Aktuelle ${AppBrandTerms.masterPin}';

  @override
  String get newPinFieldLabel => 'Neue ${AppBrandTerms.masterPin}';

  @override
  String get confirmNewPinFieldLabel => 'Neue ${AppBrandTerms.masterPin} Bestätigen';

  @override
  String get pinMinCharsError => 'Die ${AppBrandTerms.masterPin} muss mindestens 4 Zeichen lang sein';

  @override
  String get newPinsDoNotMatchError => 'Die neuen ${AppBrandTerms.pin}-Codes stimmen nicht überein';

  @override
  String get pinUpdatedSuccess => '${AppBrandTerms.masterPin} erfolgreich aktualisiert';

  @override
  String get exportBackupDialogTitle => 'Verschlüsseltes Backup Exportieren';

  @override
  String get exportBackupInstructions =>
      'Geben Sie ein Passwort ein, um die Backup-Datei mit ${AppBrandTerms.aes256} zu verschlüsseln. Bewahren Sie dieses Passwort sicher auf.';

  @override
  String get backupPasswordFieldLabel => 'Backup-Verschlüsselungspasswort';

  @override
  String get backupPasswordMinCharsError => 'Geben Sie ein Passwort mit mindestens 6 Zeichen ein';

  @override
  String get backupGeneratedDialogTitle => 'Verschlüsseltes Backup Erstellt';

  @override
  String get backupCopyWarning =>
      'Kopieren und speichern Sie diese verschlüsselte Zeichenkette an einem sicheren Ort. Ohne das Passwort kann sie nicht entschlüsselt werden.';

  @override
  String get restoreBackupDialogTitle => 'Aus Backup Wiederherstellen';

  @override
  String get pasteBackupDataLabel => 'Verschlüsselte Backup-Zeichenkette hier einfügen';

  @override
  String get fillAllFieldsError => 'Bitte füllen Sie alle erforderlichen Felder aus';

  @override
  String itemsRestoredSuccess(int count) => '$count Einträge erfolgreich wiederhergestellt!';

  @override
  String get restoreFailedError => 'Wiederherstellung fehlgeschlagen: Ungültige Daten oder falsches Passwort';

  @override
  String get wipeAllDataDialogTitle => 'Vollständige Datenlöschung';

  @override
  String get wipeAllDataWarning1 => 'ACHTUNG: Diese Aktion löscht unwiderruflich:';

  @override
  String get wipeAllDataWarning2 =>
      'Alle Passwörter, Karten, Notizen, ${AppBrandTerms.masterPin} und gespeicherten Einstellungen.';

  @override
  String get wipeAllDataConfirmButton => 'Alles Dauerhaft Löschen';

  @override
  String formatAutoLock(int seconds) {
    if (seconds == 0) return 'Sofort';
    if (seconds < 60) return '${seconds}s';
    return '${seconds ~/ 60}m';
  }

  @override
  String formatClipboard(int seconds) {
    if (seconds == 0) return 'Nie';
    return '${seconds}s';
  }

  @override
  String get autoLockPickerTitle => 'Automatisches Sperrintervall';

  @override
  String get clipboardPickerTitle => 'Zwischenablage-Löschintervall';

  @override
  String get autoLockImmediate => 'Sofort beim Verlassen';

  @override
  String get autoLock30s => 'Nach 30 Sekunden';

  @override
  String get autoLock1m => 'Nach 1 Minute';

  @override
  String get autoLock5m => 'Nach 5 Minuten';

  @override
  String get clipboardDisabled => 'Deaktiviert (Nie löschen)';

  @override
  String get clipboard15s => '15 Sekunden';

  @override
  String get clipboard30sRecommended => '30 Sekunden (Empfohlen)';

  @override
  String get clipboard60s => '60 Sekunden';

  @override
  String get privacyShieldTitle => '${AppBrandTerms.appName} Geschützt';

  @override
  String get privacyShieldSubtitle => 'Bildschirm zum Schutz Ihrer Privatsphäre verdeckt';
}

/// ============================================================================
/// DELEGATE IMPLEMENTATION
/// ============================================================================
class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['it', 'en', 'es', 'fr', 'de'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    switch (locale.languageCode) {
      case 'es':
        return SynchronousFuture<AppLocalizations>(AppLocalizationsEs());
      case 'fr':
        return SynchronousFuture<AppLocalizations>(AppLocalizationsFr());
      case 'de':
        return SynchronousFuture<AppLocalizations>(AppLocalizationsDe());
      case 'en':
        return SynchronousFuture<AppLocalizations>(AppLocalizationsEn());
      case 'it':
      default:
        return SynchronousFuture<AppLocalizations>(AppLocalizationsIt());
    }
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
