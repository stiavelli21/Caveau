// ============================================================================
// SPECIAL & IMMUTABLE BRAND / TECHNICAL TERMS
// ============================================================================
// 
// NOTE FOR DEVELOPERS:
// The following terms represent the application name, technical acronyms,
// security standards, or universal terminology (e.g., "Password", "PIN")
// that MUST REMAIN CONSTANT across all languages (Italian, English, Spanish,
// French, German, and any future languages added to the app).
//
// Do NOT translate or modify these constants in order to preserve brand integrity
// and industry-standard security terminology across all localizations.
// ============================================================================

/// Centralized repository of immutable brand terms and technical standards.
class AppBrandTerms {
  // Private constructor to prevent direct instantiation of this utility class.
  AppBrandTerms._();

  /// Official application brand name.
  static const String appName = 'Caveau';

  /// Universal authentication and security terms.
  static const String password = 'Password';
  static const String pin = 'PIN';
  static const String masterPin = 'Master PIN';
  static const String pinMaster = 'PIN Master';

  /// Cryptographic standards and algorithm identifiers.
  static const String sha256 = 'SHA-256';
  static const String aes256 = 'AES-256';

  /// System hardware and biometric authentication modules.
  static const String faceId = 'Face ID';
  static const String touchId = 'Touch ID';
  static const String androidKeystore = 'Android Keystore';
  static const String iosKeychain = 'iOS Keychain';

  /// Industry standard acronyms, formats, and banking terms.
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

  /// Open-source platform and community references.
  static const String github = 'GitHub';

  /// Official web links and documentation URLs.
  static const String privacyPolicyUrl = 'https://www.stiavelli.net/caveau/privacy-policy.html';
  static const String privacyPolicyHost = 'www.stiavelli.net/caveau/privacy-policy.html';
  static const String githubRepoUrl = 'https://github.com/stiavelli21/Caveau';
  static const String githubRepoDisplay = 'github.com/stiavelli21/Caveau';
  static const String developerWebsiteUrl = 'https://www.stiavelli.net';
}
