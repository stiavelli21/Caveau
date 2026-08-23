import 'dart:convert';

/// Immutable model representing user security preferences and session configuration.
class SecuritySettings {
  /// Whether biometric unlock (Face ID, Touch ID, fingerprint) is enabled.
  final bool biometricsEnabled;

  /// Duration of background inactivity before the app locks itself (in seconds).
  /// Values: 0 = immediate, 30, 60, 300.
  final int autoLockSeconds;

  /// Whether the privacy shield blur overlay is activated when the app enters background/multitasking.
  final bool privacyScreenEnabled;

  /// Duration after which copied sensitive data is automatically cleared from the clipboard (in seconds).
  /// Values: 0 = never / disabled, 15, 30, 60.
  final int clipboardClearSeconds;

  /// Counter of consecutive failed Master PIN authentication attempts.
  final int failedAttempts;

  /// Timestamp until which Master PIN unlock is temporarily blocked (anti-brute-force lockout).
  final DateTime? lockoutUntil;

  /// ISO 639-1 language code selected for the UI ('it', 'en', 'es', 'fr', 'de').
  final String languageCode;

  /// Creates a [SecuritySettings] instance with sensible defaults.
  const SecuritySettings({
    this.biometricsEnabled = true,
    this.autoLockSeconds = 30,
    this.privacyScreenEnabled = false,
    this.clipboardClearSeconds = 30,
    this.failedAttempts = 0,
    this.lockoutUntil,
    this.languageCode = 'it',
  });

  /// Creates a copy of this [SecuritySettings] instance with optional modified properties.
  SecuritySettings copyWith({
    bool? biometricsEnabled,
    int? autoLockSeconds,
    bool? privacyScreenEnabled,
    int? clipboardClearSeconds,
    int? failedAttempts,
    DateTime? lockoutUntil,
    String? languageCode,
  }) {
    return SecuritySettings(
      biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
      autoLockSeconds: autoLockSeconds ?? this.autoLockSeconds,
      privacyScreenEnabled: privacyScreenEnabled ?? this.privacyScreenEnabled,
      clipboardClearSeconds: clipboardClearSeconds ?? this.clipboardClearSeconds,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockoutUntil: lockoutUntil,
      languageCode: languageCode ?? this.languageCode,
    );
  }

  /// Converts this configuration to a JSON-compatible map for persistence.
  Map<String, dynamic> toJson() => {
    'biometricsEnabled': biometricsEnabled,
    'autoLockSeconds': autoLockSeconds,
    'privacyScreenEnabled': privacyScreenEnabled,
    'clipboardClearSeconds': clipboardClearSeconds,
    'failedAttempts': failedAttempts,
    'lockoutUntil': lockoutUntil?.toIso8601String(),
    'languageCode': languageCode,
  };

  /// Constructs a [SecuritySettings] instance from a JSON map with safe fallbacks.
  factory SecuritySettings.fromJson(Map<String, dynamic> json) => SecuritySettings(
    biometricsEnabled: json['biometricsEnabled'] as bool? ?? true,
    autoLockSeconds: json['autoLockSeconds'] as int? ?? 30,
    privacyScreenEnabled: json['privacyScreenEnabled'] as bool? ?? false,
    clipboardClearSeconds: json['clipboardClearSeconds'] as int? ?? 30,
    failedAttempts: json['failedAttempts'] as int? ?? 0,
    lockoutUntil: json['lockoutUntil'] != null
        ? DateTime.tryParse(json['lockoutUntil'] as String)
        : null,
    languageCode: json['languageCode'] as String? ?? 'it',
  );

  /// Serializes the settings object into a JSON string for secure storage.
  String serialize() => jsonEncode(toJson());

  /// Deserializes a JSON string into a [SecuritySettings] instance.
  factory SecuritySettings.deserialize(String jsonString) =>
      SecuritySettings.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
}
