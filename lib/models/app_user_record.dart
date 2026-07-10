import 'user_profile.dart';

/// Local household account stored in the encrypted SQLite database.
class AppUserRecord {
  final String name;
  final String email;
  final String phone;
  final String householdName;
  final String region;
  final String currency;
  final String? primaryBankId;
  final String authMethod; // 'pin' | 'password'
  final String secretHash;
  final bool biometricEnabled;
  final String createdAt;
  final String updatedAt;

  const AppUserRecord({
    required this.name,
    required this.email,
    required this.phone,
    this.householdName = '',
    this.region = 'india',
    this.currency = 'INR',
    this.primaryBankId,
    this.authMethod = 'pin',
    required this.secretHash,
    this.biometricEnabled = false,
    required this.createdAt,
    required this.updatedAt,
  });

  UserProfile toProfile() => UserProfile(
        name: name,
        email: email,
        phone: phone,
        householdName: householdName,
        region: region,
        currency: currency,
        primaryBankId: primaryBankId,
      );

  factory AppUserRecord.fromProfile({
    required UserProfile profile,
    required String secretHash,
    String authMethod = 'pin',
    bool biometricEnabled = false,
    String? createdAt,
    String? updatedAt,
  }) {
    final now = DateTime.now().toIso8601String();
    return AppUserRecord(
      name: profile.name,
      email: profile.email,
      phone: profile.phone,
      householdName: profile.householdName,
      region: profile.region,
      currency: profile.currency,
      primaryBankId: profile.primaryBankId,
      authMethod: authMethod,
      secretHash: secretHash,
      biometricEnabled: biometricEnabled,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': 1,
        'name': name,
        'email': email,
        'phone': phone,
        'householdName': householdName,
        'region': region,
        'currency': currency,
        'primaryBankId': primaryBankId ?? '',
        'authMethod': authMethod,
        'secretHash': secretHash,
        'biometricEnabled': biometricEnabled ? 1 : 0,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory AppUserRecord.fromMap(Map<String, dynamic> map) {
    final bank = (map['primaryBankId'] as String?)?.trim();
    return AppUserRecord(
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      householdName: map['householdName'] as String? ?? '',
      region: map['region'] as String? ?? 'india',
      currency: map['currency'] as String? ?? 'INR',
      primaryBankId: (bank == null || bank.isEmpty) ? null : bank,
      authMethod: map['authMethod'] as String? ?? 'pin',
      secretHash: map['secretHash'] as String? ?? '',
      biometricEnabled: (map['biometricEnabled'] as int? ?? 0) == 1,
      createdAt: map['createdAt'] as String? ?? '',
      updatedAt: map['updatedAt'] as String? ?? '',
    );
  }

  AppUserRecord copyWith({
    String? name,
    String? email,
    String? phone,
    String? householdName,
    String? region,
    String? currency,
    String? primaryBankId,
    String? authMethod,
    String? secretHash,
    bool? biometricEnabled,
    String? createdAt,
    String? updatedAt,
  }) {
    return AppUserRecord(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      householdName: householdName ?? this.householdName,
      region: region ?? this.region,
      currency: currency ?? this.currency,
      primaryBankId: primaryBankId ?? this.primaryBankId,
      authMethod: authMethod ?? this.authMethod,
      secretHash: secretHash ?? this.secretHash,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
