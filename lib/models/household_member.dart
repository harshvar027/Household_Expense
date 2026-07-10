class HouseholdMember {
  final int? id;
  final String name;
  final String role;
  final String color;

  HouseholdMember({
    this.id,
    required this.name,
    this.role = 'Member',
    this.color = '#64B5F6',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'role': role,
        'color': color,
      };

  factory HouseholdMember.fromMap(Map<String, dynamic> map) => HouseholdMember(
        id: map['id'] as int?,
        name: map['name'] as String,
        role: map['role'] as String? ?? 'Member',
        color: map['color'] as String? ?? '#64B5F6',
      );
}
