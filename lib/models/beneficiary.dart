import 'dart:convert';

/// Mfumo wa Mrithi wa Akaunti ya Akiba (Beneficiary / Next of Kin)
class Beneficiary {
  Beneficiary({
    required this.name,
    required this.relationship,
    required this.phone,
    this.nida = '',
    this.allocationPercentage = 100,
    this.notes = '',
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  final String name;
  final String
  relationship; // e.g. 'Mke / Mume', 'Mtoto', 'Mzazi', 'Ndugu', 'Mlezi'
  final String phone;
  final String nida;
  final int allocationPercentage; // default 100%
  final String notes;
  final DateTime updatedAt;

  bool get isValid =>
      name.trim().isNotEmpty &&
      RegExp(r'^(0\d{9}|255\d{9}|\+255\d{9})$').hasMatch(phone.trim()) &&
      allocationPercentage >= 1 &&
      allocationPercentage <= 100;

  Map<String, dynamic> toMap() => {
    'name': name,
    'relationship': relationship,
    'phone': phone,
    'nida': nida,
    'allocationPercentage': allocationPercentage,
    'notes': notes,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Beneficiary.fromMap(Map<String, dynamic> map) {
    return Beneficiary(
      name: map['name'] as String? ?? '',
      relationship: map['relationship'] as String? ?? 'Ndugu',
      phone: map['phone'] as String? ?? '',
      nida: map['nida'] as String? ?? '',
      allocationPercentage:
          (map['allocationPercentage'] as num?)?.toInt() ?? 100,
      notes: map['notes'] as String? ?? '',
      updatedAt:
          DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory Beneficiary.fromJson(String source) =>
      Beneficiary.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
