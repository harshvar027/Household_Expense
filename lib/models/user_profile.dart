class UserProfile {
  final String name;
  final String email;
  final String phone;
  final String householdName;
  final String region;
  final String currency;
  final String? primaryBankId;

  const UserProfile({
    required this.name,
    required this.email,
    required this.phone,
    this.householdName = '',
    this.region = 'india',
    this.currency = 'INR',
    this.primaryBankId,
  });

  String get firstName {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? name : parts.first;
  }

  String get displayLabel =>
      householdName.trim().isNotEmpty ? householdName.trim() : name.trim();

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'phone': phone,
        'householdName': householdName,
        'region': region,
        'currency': currency,
        'primaryBankId': primaryBankId ?? '',
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        householdName: json['householdName'] as String? ?? '',
        region: _readRegion(json),
        currency: json['currency'] as String? ?? 'INR',
        primaryBankId: _readBankId(json['primaryBankId']),
      );

  static String _readRegion(Map<String, dynamic> json) {
    final raw = json['region'] as String?;
    if (raw != null && raw.trim().isNotEmpty) return raw.trim();
    final currency = (json['currency'] as String? ?? 'INR').toUpperCase();
    switch (currency) {
      case 'USD':
        return 'unitedStates';
      case 'GBP':
        return 'unitedKingdom';
      case 'EUR':
        return 'europe';
      case 'INR':
        return 'india';
      default:
        return 'international';
    }
  }

  static String? _readBankId(Object? raw) {
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? householdName,
    String? region,
    String? currency,
    String? primaryBankId,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      householdName: householdName ?? this.householdName,
      region: region ?? this.region,
      currency: currency ?? this.currency,
      primaryBankId: primaryBankId ?? this.primaryBankId,
    );
  }
}
