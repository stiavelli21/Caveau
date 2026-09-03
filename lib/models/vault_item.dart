import 'dart:convert';
import 'package:uuid/uuid.dart';

/// Categories supported for vault items in Caveau.
enum VaultCategory {
  login,
  card,
  note,
  identity,
  apiKey;

  /// Default fallback English display name for this category.
  /// For localized UI rendering, use [AppLocalizations.categoryDisplayName].
  String get displayName {
    switch (this) {
      case VaultCategory.login:
        return 'Password & Account';
      case VaultCategory.card:
        return 'Payment Card';
      case VaultCategory.note:
        return 'Secure Note';
      case VaultCategory.identity:
        return 'Identity & Document';
      case VaultCategory.apiKey:
        return 'API Key / Token';
    }
  }

  /// Default fallback English short label for filter chips.
  /// For localized UI rendering, use [AppLocalizations.categoryShortName].
  String get shortName {
    switch (this) {
      case VaultCategory.login:
        return 'Login';
      case VaultCategory.card:
        return 'Cards';
      case VaultCategory.note:
        return 'Notes';
      case VaultCategory.identity:
        return 'Identity';
      case VaultCategory.apiKey:
        return 'API';
    }
  }
}

/// Dynamic user-defined custom key-value field attached to a [VaultItem].
class CustomField {
  /// Unique identifier (UUID v4) for the custom field.
  final String id;

  /// Human-readable label (e.g. "PIN", "Recovery Code", "Security Question").
  final String label;

  /// Text content/value stored in this field.
  final String value;

  /// When true, the value is masked in the UI by default and subject to auto-clearing.
  final bool isSecret;

  /// Creates a [CustomField] with an optional generated UUID.
  CustomField({
    String? id,
    required this.label,
    required this.value,
    this.isSecret = false,
  }) : id = id ?? const Uuid().v4();

  /// Converts this field to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'value': value,
    'isSecret': isSecret,
  };

  /// Constructs a [CustomField] instance from a JSON map with safe fallbacks.
  factory CustomField.fromJson(Map<String, dynamic> json) => CustomField(
    id: json['id'] as String?,
    label: json['label'] as String? ?? '',
    value: json['value'] as String? ?? '',
    isSecret: json['isSecret'] as bool? ?? false,
  );
}

/// Core domain model representing a single encrypted secret or credential stored in Caveau.
class VaultItem {
  /// Unique identifier (UUID v4) for this vault record.
  final String id;

  /// Title or service name (e.g. "Google", "GitHub", "Main Visa").
  final String title;

  /// Classification category defining the primary purpose of this record.
  final VaultCategory category;

  /// Whether the user pinned this item as a favorite.
  final bool isFavorite;

  /// Record creation timestamp.
  final DateTime createdAt;

  /// Record last modification timestamp.
  final DateTime updatedAt;
  
  // --- Category-specific fields: Login ---
  /// Account username or email.
  final String? username;

  /// Account password.
  final String? password;

  /// Service website or login URL.
  final String? websiteUrl;
  
  // --- Category-specific fields: Payment Card ---
  /// Name printed on the card.
  final String? cardHolder;

  /// 16-digit or custom payment card number.
  final String? cardNumber;

  /// Card expiration date (e.g. "12/28").
  final String? cardExpiry;

  /// Security code (CVV / CVC / CID).
  final String? cardCvv;

  /// Card ATM PIN.
  final String? cardPin;
  
  // --- Category-specific fields: Identity & Secure Note ---
  /// Encrypted multi-line text or markdown notes.
  final String? notes;

  /// Contact email address.
  final String? email;

  /// Contact telephone number.
  final String? phone;

  /// Government ID, passport number, or tax code.
  final String? idNumber;
  
  // --- Category-specific fields: API Key ---
  /// Private API token, bearer token, or secret key.
  final String? apiKeySecret;
  
  // --- Dynamic custom fields ---
  /// List of additional user-defined key-value fields.
  final List<CustomField> customFields;

  /// Creates a new [VaultItem] with automatic UUID and timestamps if omitted.
  VaultItem({
    String? id,
    required this.title,
    required this.category,
    this.isFavorite = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.username,
    this.password,
    this.websiteUrl,
    this.cardHolder,
    this.cardNumber,
    this.cardExpiry,
    this.cardCvv,
    this.cardPin,
    this.notes,
    this.email,
    this.phone,
    this.idNumber,
    this.apiKeySecret,
    this.customFields = const [],
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Creates a copy of this [VaultItem] with updated properties and a refreshed [updatedAt] timestamp.
  VaultItem copyWith({
    String? id,
    String? title,
    VaultCategory? category,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? username,
    String? password,
    String? websiteUrl,
    String? cardHolder,
    String? cardNumber,
    String? cardExpiry,
    String? cardCvv,
    String? cardPin,
    String? notes,
    String? email,
    String? phone,
    String? idNumber,
    String? apiKeySecret,
    List<CustomField>? customFields,
  }) {
    return VaultItem(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      username: username ?? this.username,
      password: password ?? this.password,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      cardHolder: cardHolder ?? this.cardHolder,
      cardNumber: cardNumber ?? this.cardNumber,
      cardExpiry: cardExpiry ?? this.cardExpiry,
      cardCvv: cardCvv ?? this.cardCvv,
      cardPin: cardPin ?? this.cardPin,
      notes: notes ?? this.notes,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      idNumber: idNumber ?? this.idNumber,
      apiKeySecret: apiKeySecret ?? this.apiKeySecret,
      customFields: customFields ?? this.customFields,
    );
  }

  /// Converts this [VaultItem] to a JSON-compatible map for storage and export.
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category.name,
    'isFavorite': isFavorite,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'username': username,
    'password': password,
    'websiteUrl': websiteUrl,
    'cardHolder': cardHolder,
    'cardNumber': cardNumber,
    'cardExpiry': cardExpiry,
    'cardCvv': cardCvv,
    'cardPin': cardPin,
    'notes': notes,
    'email': email,
    'phone': phone,
    'idNumber': idNumber,
    'apiKeySecret': apiKeySecret,
    'customFields': customFields.map((f) => f.toJson()).toList(),
  };

  /// Constructs a [VaultItem] instance from a JSON map with backward-compatible fallbacks.
  factory VaultItem.fromJson(Map<String, dynamic> json) {
    return VaultItem(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled',
      category: VaultCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => VaultCategory.login,
      ),
      isFavorite: json['isFavorite'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      username: json['username'] as String?,
      password: json['password'] as String?,
      websiteUrl: json['websiteUrl'] as String?,
      cardHolder: json['cardHolder'] as String?,
      cardNumber: json['cardNumber'] as String?,
      cardExpiry: json['cardExpiry'] as String?,
      cardCvv: json['cardCvv'] as String?,
      cardPin: json['cardPin'] as String?,
      notes: json['notes'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      idNumber: json['idNumber'] as String?,
      apiKeySecret: json['apiKeySecret'] as String?,
      customFields: (json['customFields'] as List<dynamic>?)
              ?.map((f) => CustomField.fromJson(f as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Serializes this [VaultItem] into a JSON string.
  String serialize() => jsonEncode(toJson());

  /// Deserializes a JSON string into a [VaultItem] instance.
  factory VaultItem.deserialize(String jsonString) =>
      VaultItem.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);

  /// Compares two title strings alphabetically according to "Option A + Interpretation 2":
  /// 1. Primary order: Case-insensitive alphabetical comparison (`toLowerCase()`).
  /// 2. Secondary order (tie-breaker when case-insensitively identical):
  ///    Character-by-character comparison where lowercase precedes uppercase
  ///    (e.g., 'a' < 'A', 'b' < 'B').
  static int compareTitles(String a, String b) {
    final lowerA = a.toLowerCase();
    final lowerB = b.toLowerCase();
    final primary = lowerA.compareTo(lowerB);
    if (primary != 0) {
      return primary;
    }

    // Secondary order (case-sensitive tie-breaker):
    // Compare character by character. If one is lowercase and the other is uppercase,
    // lowercase comes first ('a' before 'A').
    final minLen = a.length < b.length ? a.length : b.length;
    for (int i = 0; i < minLen; i++) {
      if (a[i] != b[i]) {
        final aLower = a[i] == a[i].toLowerCase();
        final bLower = b[i] == b[i].toLowerCase();
        if (aLower && !bLower) return -1;
        if (!aLower && bLower) return 1;
        return a.codeUnitAt(i).compareTo(b.codeUnitAt(i));
      }
    }

    return a.length.compareTo(b.length);
  }

  /// Compares two [VaultItem]s for display in Caveau (Option A + Interpretation 2):
  /// 1. Pinned Favorites: Items with [isFavorite] == true precede non-favorites.
  /// 2. Alphabetical order by [title] (case-insensitive primary, lowercase preceding uppercase secondary).
  /// 3. Fallback to modification timestamp [updatedAt] descending, then [id].
  static int compareItems(VaultItem a, VaultItem b) {
    // 1. Favorites pinned to top
    if (a.isFavorite != b.isFavorite) {
      return a.isFavorite ? -1 : 1;
    }

    // 2. Alphabetical by title (lowercase first)
    final titleComparison = compareTitles(a.title, b.title);
    if (titleComparison != 0) {
      return titleComparison;
    }

    // 3. Most recently updated first
    final dateComparison = b.updatedAt.compareTo(a.updatedAt);
    if (dateComparison != 0) {
      return dateComparison;
    }

    return a.id.compareTo(b.id);
  }
}
