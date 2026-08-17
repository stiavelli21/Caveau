import 'dart:convert';
import 'package:uuid/uuid.dart';

enum VaultCategory {
  login,
  card,
  note,
  identity,
  apiKey;

  String get displayName {
    switch (this) {
      case VaultCategory.login:
        return 'Password & Account';
      case VaultCategory.card:
        return 'Carta di Pagamento';
      case VaultCategory.note:
        return 'Nota Sicura';
      case VaultCategory.identity:
        return 'Dati Identità';
      case VaultCategory.apiKey:
        return 'Chiave API / Token';
    }
  }

  String get shortName {
    switch (this) {
      case VaultCategory.login:
        return 'Login';
      case VaultCategory.card:
        return 'Carte';
      case VaultCategory.note:
        return 'Note';
      case VaultCategory.identity:
        return 'Identità';
      case VaultCategory.apiKey:
        return 'API';
    }
  }
}

class CustomField {
  final String id;
  final String label;
  final String value;
  final bool isSecret;

  CustomField({
    String? id,
    required this.label,
    required this.value,
    this.isSecret = false,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'value': value,
    'isSecret': isSecret,
  };

  factory CustomField.fromJson(Map<String, dynamic> json) => CustomField(
    id: json['id'] as String?,
    label: json['label'] as String? ?? '',
    value: json['value'] as String? ?? '',
    isSecret: json['isSecret'] as bool? ?? false,
  );
}

class VaultItem {
  final String id;
  final String title;
  final VaultCategory category;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Login fields
  final String? username;
  final String? password;
  final String? websiteUrl;
  
  // Card fields
  final String? cardHolder;
  final String? cardNumber;
  final String? cardExpiry;
  final String? cardCvv;
  final String? cardPin;
  
  // Identity & Note fields
  final String? notes;
  final String? email;
  final String? phone;
  final String? idNumber;
  
  // API Key fields
  final String? apiKeySecret;
  
  // Custom fields
  final List<CustomField> customFields;

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

  factory VaultItem.fromJson(Map<String, dynamic> json) {
    return VaultItem(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Senza Titolo',
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

  String serialize() => jsonEncode(toJson());

  factory VaultItem.deserialize(String jsonString) =>
      VaultItem.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
}
