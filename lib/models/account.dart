class Account {
  final int? id;
  final String name;
  final String type;
  final bool isDefault;
  final String? bankId;

  Account({
    this.id,
    required this.name,
    this.type = 'Savings',
    this.isDefault = false,
    this.bankId,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type,
        'isDefault': isDefault ? 1 : 0,
        'bankId': bankId ?? '',
      };

  factory Account.fromMap(Map<String, dynamic> map) => Account(
        id: map['id'] as int?,
        name: map['name'] as String,
        type: map['type'] as String? ?? 'Savings',
        isDefault: (map['isDefault'] as int? ?? 0) == 1,
        bankId: _readBankId(map['bankId']),
      );

  static String? _readBankId(Object? raw) {
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  Account copyWith({
    int? id,
    String? name,
    String? type,
    bool? isDefault,
    String? bankId,
  }) =>
      Account(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        isDefault: isDefault ?? this.isDefault,
        bankId: bankId ?? this.bankId,
      );
}
