import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_state.dart';

/// Hali na taarifa za mwanachama wa kikundi.
class GroupMember {
  GroupMember({
    required this.name,
    required this.phone,
    required this.role,
    this.contributed = 0.0,
    this.lastContributedAt,
  });

  final String name;
  final String phone;
  final String role; // 'Mwenyekiti', 'Mweka Hazina', 'Mwanachama'
  double contributed;
  DateTime? lastContributedAt;

  bool get isValid =>
      name.trim().isNotEmpty &&
      RegExp(r'^(0\d{9}|255\d{9}|\+255\d{9})$').hasMatch(phone.trim()) &&
      contributed >= 0;

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'role': role,
        'contributed': contributed,
        'lastContributedAt': lastContributedAt?.toIso8601String(),
      };

  factory GroupMember.fromMap(Map<String, dynamic> map) => GroupMember(
        name: map['name'] as String? ?? 'Mwanachama',
        phone: map['phone'] as String? ?? '',
        role: map['role'] as String? ?? 'Mwanachama',
        contributed: (map['contributed'] as num?)?.toDouble() ?? 0.0,
        lastContributedAt: parseDate(map['lastContributedAt'] as String?),
      );
}

/// Mfano wa Kikundi cha Akiba (VICOBA / Chama).
class SavingsGroup {
  SavingsGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.targetPerMember,
    required this.contributionFrequency,
    required this.code,
    required this.members,
    required this.rules,
    required this.history,
    required this.createdAt,
  });

  final String id;
  String name;
  String description;
  double targetPerMember;
  String contributionFrequency; // 'Kila Wiki', 'Kila Mwezi'
  String code;
  List<GroupMember> members;
  String rules;
  List<Map<String, dynamic>> history;
  DateTime createdAt;

  double get totalSaved => members.fold(0.0, (sum, m) => sum + m.contributed);
  double get totalTarget => targetPerMember * (members.isEmpty ? 1 : members.length);
  double get progress => totalTarget > 0 ? (totalSaved / totalTarget).clamp(0.0, 1.0) : 0.0;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'targetPerMember': targetPerMember,
        'contributionFrequency': contributionFrequency,
        'code': code,
        'members': members.map((m) => m.toMap()).toList(),
        'rules': rules,
        'history': history,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SavingsGroup.fromMap(Map<String, dynamic> map) => SavingsGroup(
        id: map['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: map['name'] as String? ?? 'Kikundi cha Akiba',
        description: map['description'] as String? ?? '',
        targetPerMember: (map['targetPerMember'] as num?)?.toDouble() ?? 0.0,
        contributionFrequency: map['contributionFrequency'] as String? ?? 'Kila Mwezi',
        code: map['code'] as String? ?? 'VICOBA-101',
        members: (map['members'] as List<dynamic>? ?? [])
            .map((m) => GroupMember.fromMap(Map<String, dynamic>.from(m as Map)))
            .toList(),
        rules: map['rules'] as String? ?? 'Michango itolewe kwa wakati.',
        history: (map['history'] as List<dynamic>? ?? [])
            .map((h) => Map<String, dynamic>.from(h as Map))
            .toList(),
        createdAt: parseDate(map['createdAt'] as String?) ?? DateTime.now(),
      );
}

/// Orodha ya vikundi vya mtumiaji.
List<SavingsGroup> savingsGroups = [];

/// Pakia vikundi kutoka SharedPreferences.
Future<void> loadGroupsData() async {
  final prefs = await SharedPreferences.getInstance();
  final list = prefs.getStringList('savingsGroups') ?? [];
  savingsGroups = [];

  for (final raw in list) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      savingsGroups.add(SavingsGroup.fromMap(map));
    } catch (_) {}
  }

  // Kama hakuna kikundi, ongeza mfano wa awali wa VICOBA ya Mwanzo
  if (savingsGroups.isEmpty && fullName.isNotEmpty) {
    savingsGroups.add(
      SavingsGroup(
        id: 'vicoba-sample-1',
        name: 'VICOBA ya Maendeleo 🌟',
        description: 'Kikundi cha kusaidiana kibiashara na dharura.',
        targetPerMember: 200000.0,
        contributionFrequency: 'Kila Mwezi',
        code: 'VICOBA-882',
        members: [
          GroupMember(name: fullName, phone: phone, role: 'Mwenyekiti', contributed: 50000.0, lastContributedAt: DateTime.now()),
          GroupMember(name: 'Baraka Juma', phone: '0754123456', role: 'Katibu', contributed: 50000.0, lastContributedAt: DateTime.now()),
          GroupMember(name: 'Neema Mwangi', phone: '0712987654', role: 'Mweka Hazina', contributed: 40000.0, lastContributedAt: DateTime.now()),
        ],
        rules: '1. Mchango ni kila tarehe 1 ya mwezi.\n2. Tozo ya kuchelewa ni TSh 5,000.\n3. Mkopo hutolewa kwa riba ya 5%.',
        history: [
          {'member': fullName, 'amount': 50000.0, 'date': DateTime.now().toIso8601String(), 'type': 'deposit'},
          {'member': 'Baraka Juma', 'amount': 50000.0, 'date': DateTime.now().toIso8601String(), 'type': 'deposit'},
          {'member': 'Neema Mwangi', 'amount': 40000.0, 'date': DateTime.now().toIso8601String(), 'type': 'deposit'},
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
    );
    await saveGroupsData();
  }
}

/// Hifadhi vikundi kwenye SharedPreferences.
Future<void> saveGroupsData() async {
  final prefs = await SharedPreferences.getInstance();
  final list = savingsGroups.map((g) => jsonEncode(g.toMap())).toList();
  await prefs.setStringList('savingsGroups', list);
}

/// Unda kikundi kipya chenye viongozi 3 (Mwenyekiti, Katibu, Mweka Hazina) na Wawakilishi 2.
Future<SavingsGroup> createNewGroup({
  required String name,
  required String description,
  required double targetPerMember,
  required String contributionFrequency,
  required String rules,
  String chairpersonName = '',
  String chairpersonPhone = '',
  String secretaryName = '',
  String secretaryPhone = '',
  String treasurerName = '',
  String treasurerPhone = '',
  String rep1Name = '',
  String rep1Phone = '',
  String rep2Name = '',
  String rep2Phone = '',
  List<GroupMember>? initialMembers,
}) async {
  if (name.trim().isEmpty) throw ArgumentError('Jina la kikundi linahitajika.');
  if (targetPerMember <= 0) throw ArgumentError('Mchango wa mwanachama lazima uwe zaidi ya sifuri.');
  if (membersListIsInvalid(initialMembers)) {
    throw ArgumentError('Taarifa za mwanachama wa kikundi si sahihi.');
  }
  final rndCode =
      'VICOBA-${100 + (DateTime.now().millisecondsSinceEpoch % 900)}';

  final List<GroupMember> membersList = [];

  if (initialMembers != null && initialMembers.isNotEmpty) {
    membersList.addAll(initialMembers);
  } else {
    // 1. Mwenyekiti (Kiongozi Mkuu 1)
    final chairName = chairpersonName.trim().isNotEmpty
        ? chairpersonName.trim()
        : (fullName.isEmpty ? 'Mwenyekiti' : fullName);
    final chairPhone =
        chairpersonPhone.trim().isNotEmpty ? chairpersonPhone.trim() : phone;
    membersList.add(
      GroupMember(
        name: chairName,
        phone: chairPhone,
        role: '👑 Mwenyekiti',
      ),
    );

    // 2. Katibu (Kiongozi Mkuu 2)
    if (secretaryName.trim().isNotEmpty) {
      membersList.add(
        GroupMember(
          name: secretaryName.trim(),
          phone: secretaryPhone.trim(),
          role: '✍️ Katibu',
        ),
      );
    }

    // 3. Mweka Hazina (Kiongozi Mkuu 3)
    if (treasurerName.trim().isNotEmpty) {
      membersList.add(
        GroupMember(
          name: treasurerName.trim(),
          phone: treasurerPhone.trim(),
          role: '💰 Mweka Hazina',
        ),
      );
    }

    // 4. Mwakilishi wa 1
    if (rep1Name.trim().isNotEmpty) {
      membersList.add(
        GroupMember(
          name: rep1Name.trim(),
          phone: rep1Phone.trim(),
          role: '🛡️ Mwakilishi 1',
        ),
      );
    }

    // 5. Mwakilishi wa 2
    if (rep2Name.trim().isNotEmpty) {
      membersList.add(
        GroupMember(
          name: rep2Name.trim(),
          phone: rep2Phone.trim(),
          role: '🛡️ Mwakilishi 2',
        ),
      );
    }
  }

  final group = SavingsGroup(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    name: name,
    description: description,
    targetPerMember: targetPerMember,
    contributionFrequency: contributionFrequency,
    code: rndCode,
    members: membersList,
    rules: rules.isEmpty
        ? 'Michango itolewe kwa wakati kulingana na ratiba.'
        : rules,
    history: [],
    createdAt: DateTime.now(),
  );

  savingsGroups.add(group);
  await saveGroupsData();
  return group;
}

bool membersListIsInvalid(List<GroupMember>? members) =>
  members != null && (members.isEmpty || members.any((member) => !member.isValid));

/// Jiunge na kikundi kwa kutumia msimbo wa mwaliko (Code).
Future<SavingsGroup?> joinGroupByCode(String code) async {
  final clean = code.trim().toUpperCase();
  // Tafuta kwenye orodha iliyopo au tengeneza kikundi kilichounganishwa
  final existing = savingsGroups.where((g) => g.code.toUpperCase() == clean).firstOrNull;
  if (existing != null) {
    // Angalia kama mtumiaji tayari yupo
    final alreadyMember = existing.members.any((m) => m.name == fullName || m.phone == phone);
    if (alreadyMember) return existing;
    if (!alreadyMember) {
      existing.members.add(
        GroupMember(
          name: fullName.isEmpty ? 'Mwanachama Mpya' : fullName,
          phone: phone,
          role: 'Mwanachama',
          contributed: 0.0,
        ),
      );
      await saveGroupsData();
    }
    return existing;
  }

  // Kama hakikupatikana ndani, tengeneza kikundi cha mfano cha mwaliko
  final newJoined = SavingsGroup(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    name: 'Kikundi cha Mwaliko ($clean)',
    description: 'Kikundi ulichojiunga nacho kwa msimbo wa mwaliko.',
    targetPerMember: 150000.0,
    contributionFrequency: 'Kila Mwezi',
    code: clean,
    members: [
      GroupMember(name: 'Mwanzilishi', phone: '0754000111', role: 'Mwenyekiti', contributed: 50000.0),
      GroupMember(name: fullName.isEmpty ? 'Mimi' : fullName, phone: phone, role: 'Mwanachama', contributed: 0.0),
    ],
    rules: 'Michango itolewe kulingana na makubaliano ya wanakikundi.',
    history: [],
    createdAt: DateTime.now(),
  );
  savingsGroups.add(newJoined);
  await saveGroupsData();
  return newJoined;
}

/// Weka mchango kwenye kikundi.
Future<void> contributeToGroup({
  required String groupId,
  required double amount,
  String memberName = '',
}) async {
  final group = savingsGroups.where((g) => g.id == groupId).firstOrNull;
  if (group == null) return;

  final user = memberName.isEmpty ? (fullName.isEmpty ? 'Mwanachama' : fullName) : memberName;
  final member = group.members.where((m) => m.name == user).firstOrNull;
  if (member != null) {
    member.contributed += amount;
    member.lastContributedAt = DateTime.now();
  }

  group.history.insert(0, {
    'member': user,
    'amount': amount,
    'date': DateTime.now().toIso8601String(),
    'type': 'deposit',
  });

  await saveGroupsData();
}
