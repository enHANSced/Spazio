import 'package:equatable/equatable.dart';

/// Modelo de usuario
class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? phone;
  final String? avatar;
  final bool isVerified;
  final bool isActive;
  final String? businessName;
  final String? businessDescription;
  final String? businessPhone;
  final String? businessEmail;
  final String? businessAddress;
  final String? website;
  final String? facebook;
  final String? instagram;
  final String? twitter;
  final String? linkedin;
  // Campos de información bancaria (solo para owners)
  final String? bankName;
  final String? bankAccountType;
  final String? bankAccountNumber;
  final String? bankAccountHolder;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.phone,
    this.avatar,
    this.isVerified = false,
    this.isActive = true,
    this.businessName,
    this.businessDescription,
    this.businessPhone,
    this.businessEmail,
    this.businessAddress,
    this.website,
    this.facebook,
    this.instagram,
    this.twitter,
    this.linkedin,
    this.bankName,
    this.bankAccountType,
    this.bankAccountNumber,
    this.bankAccountHolder,
    this.createdAt,
    this.updatedAt,
  });
  
  /// Crea un usuario desde JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: json['role'] as String? ?? 'user',
      phone: json['phone'] as String?,
      avatar: json['avatar'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      businessName: json['businessName'] as String?,
      businessDescription: json['businessDescription'] as String?,
      businessPhone: json['businessPhone'] as String?,
      businessEmail: json['businessEmail'] as String?,
      businessAddress: json['businessAddress'] as String?,
      website: json['website'] as String?,
      facebook: json['facebook'] as String?,
      instagram: json['instagram'] as String?,
      twitter: json['twitter'] as String?,
      linkedin: json['linkedin'] as String?,
      bankName: json['bankName'] as String?,
      bankAccountType: json['bankAccountType'] as String?,
      bankAccountNumber: json['bankAccountNumber'] as String?,
      bankAccountHolder: json['bankAccountHolder'] as String?,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String) 
          : null,
    );
  }
  
  /// Convierte el usuario a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'phone': phone,
      'avatar': avatar,
      'isVerified': isVerified,
      'isActive': isActive,
      'businessName': businessName,
      'businessDescription': businessDescription,
      'businessPhone': businessPhone,
      'businessEmail': businessEmail,
      'businessAddress': businessAddress,
      'website': website,
      'facebook': facebook,
      'instagram': instagram,
      'twitter': twitter,
      'linkedin': linkedin,
      'bankName': bankName,
      'bankAccountType': bankAccountType,
      'bankAccountNumber': bankAccountNumber,
      'bankAccountHolder': bankAccountHolder,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
  
  /// Verifica si el usuario es un usuario común (puede reservar)
  bool get isUser => role == 'user';
  
  /// Verifica si el usuario es propietario
  bool get isOwner => role == 'owner';
  
  /// Verifica si el usuario es administrador
  bool get isAdmin => role == 'admin';
  
  /// Verifica si el usuario puede crear reservas
  bool get canBook => role == 'user';
  
  /// Verifica si es un propietario verificado
  bool get isVerifiedOwner => isOwner && isVerified;
  
  /// Crea una copia del usuario con algunos campos modificados
  User copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    String? phone,
    String? avatar,
    bool? isVerified,
    bool? isActive,
    String? businessName,
    String? businessDescription,
    String? businessPhone,
    String? businessEmail,
    String? businessAddress,
    String? website,
    String? facebook,
    String? instagram,
    String? twitter,
    String? linkedin,
    String? bankName,
    String? bankAccountType,
    String? bankAccountNumber,
    String? bankAccountHolder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      businessName: businessName ?? this.businessName,
      businessDescription: businessDescription ?? this.businessDescription,
      businessPhone: businessPhone ?? this.businessPhone,
      businessEmail: businessEmail ?? this.businessEmail,
      businessAddress: businessAddress ?? this.businessAddress,
      website: website ?? this.website,
      facebook: facebook ?? this.facebook,
      instagram: instagram ?? this.instagram,
      twitter: twitter ?? this.twitter,
      linkedin: linkedin ?? this.linkedin,
      bankName: bankName ?? this.bankName,
      bankAccountType: bankAccountType ?? this.bankAccountType,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankAccountHolder: bankAccountHolder ?? this.bankAccountHolder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  /// Verifica si el owner tiene información bancaria configurada
  bool get hasBankInfo => bankName != null && bankAccountNumber != null;
  
  /// Formatea el tipo de cuenta bancaria para mostrar
  String get formattedBankAccountType {
    switch (bankAccountType) {
      case 'ahorro_lempiras':
        return 'Ahorro (Lempiras)';
      case 'ahorro_dolares':
        return 'Ahorro (Dólares)';
      case 'corriente_lempiras':
        return 'Corriente (Lempiras)';
      case 'corriente_dolares':
        return 'Corriente (Dólares)';
      default:
        return bankAccountType ?? '';
    }
  }
  
  @override
  List<Object?> get props => [
    id, email, name, role, phone, avatar, isVerified, isActive,
    businessName, businessDescription, businessPhone, businessEmail,
    businessAddress, website, facebook, instagram, twitter, linkedin,
    bankName, bankAccountType, bankAccountNumber, bankAccountHolder,
    createdAt, updatedAt,
  ];
}
