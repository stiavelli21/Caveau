import 'dart:convert';

class SecuritySettings {
  final bool biometricsEnabled;
  final int autoLockSeconds; // 0 = immediato, 30, 60, 300
  final bool privacyScreenEnabled;
  final int clipboardClearSeconds; // 0 = mai, 15, 30, 60
  final int failedAttempts;
  final DateTime? lockoutUntil;
  final String languageCode; // 'it', 'en'

  const SecuritySettings({
    this.biometricsEnabled = true,
    this.autoLockSeconds = 30,
    this.privacyScreenEnabled = true,
    this.clipboardClearSeconds = 30,
    this.failedAttempts = 0,
    this.lockoutUntil,
    this.languageCode = 'it',
  });

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

  Map<String, dynamic> toJson() => {
    'biometricsEnabled': biometricsEnabled,
    'autoLockSeconds': autoLockSeconds,
    'privacyScreenEnabled': privacyScreenEnabled,
    'clipboardClearSeconds': clipboardClearSeconds,
    'failedAttempts': failedAttempts,
    'lockoutUntil': lockoutUntil?.toIso8601String(),
    'languageCode': languageCode,
  };

  factory SecuritySettings.fromJson(Map<String, dynamic> json) => SecuritySettings(
    biometricsEnabled: json['biometricsEnabled'] as bool? ?? true,
    autoLockSeconds: json['autoLockSeconds'] as int? ?? 30,
    privacyScreenEnabled: json['privacyScreenEnabled'] as bool? ?? true,
    clipboardClearSeconds: json['clipboardClearSeconds'] as int? ?? 30,
    failedAttempts: json['failedAttempts'] as int? ?? 0,
    lockoutUntil: json['lockoutUntil'] != null
        ? DateTime.tryParse(json['lockoutUntil'] as String)
        : null,
    languageCode: json['languageCode'] as String? ?? 'it',
  );

  String serialize() => jsonEncode(toJson());

  factory SecuritySettings.deserialize(String jsonString) =>
      SecuritySettings.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
}
