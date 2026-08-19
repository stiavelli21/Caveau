/// ============================================================================
/// SPECIAL & IMMUTABLE BRAND / TECHNICAL TERMS
/// ============================================================================
/// 
/// ATTENZIONE / NOTE FOR DEVELOPERS:
/// I seguenti termini rappresentano il nome dell'applicazione, acronimi tecnici,
/// standard di sicurezza o parole già universali/in inglese (es. "Password", "PIN")
/// che devono RIMANERE COSTANTI in tutte le lingue (Italiano, Inglese e tutte le
/// future lingue aggiunte all'app).
///
/// Non tradurre o alterare queste costanti per preservare l'integrità del brand
/// e della terminologia di sicurezza standard.
/// ============================================================================

class AppBrandTerms {
  AppBrandTerms._();

  /// Nome dell'applicazione
  static const String appName = 'Caveau';

  /// Termini di autenticazione e sicurezza universali
  static const String password = 'Password';
  static const String pin = 'PIN';
  static const String masterPin = 'Master PIN';
  static const String pinMaster = 'PIN Master';

  /// Standard e algoritmi crittografici
  static const String sha256 = 'SHA-256';
  static const String aes256 = 'AES-256';

  /// Moduli hardware e biometrici di sistema
  static const String faceId = 'Face ID';
  static const String touchId = 'Touch ID';
  static const String androidKeystore = 'Android Keystore';
  static const String iosKeychain = 'iOS Keychain';

  /// Acronimi e formati standard
  static const String apiKey = 'API Key';
  static const String api = 'API';
  static const String otp = 'OTP';
  static const String totp = 'TOTP';
  static const String cvv = 'CVV';
  static const String cvc = 'CVC';
  static const String cvcOrCvv = 'CVV / CVC';
  static const String url = 'URL';
  static const String email = 'Email';
  static const String id = 'ID';
  static const String iban = 'IBAN';
  static const String swiftBic = 'SWIFT / BIC';
}
