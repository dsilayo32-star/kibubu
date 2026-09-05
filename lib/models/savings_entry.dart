class SavingsEntry {
  const SavingsEntry({
    required this.amount,
    required this.date,
    this.type = 'deposit',
    this.description,
    this.reference,
    this.network,
    this.goalName,
  });

  final double amount;
  final DateTime date;
  final String type;
  final String? description;
  final String? reference;
  final String? network;
  final String? goalName;

  bool get isWithdrawal => type == 'withdrawal' || type == 'withdraw';
  bool get isPenalty => type == 'penalty' || type == 'fee';

  SavingsEntry copyWith({String? goalName}) => SavingsEntry(
    amount: amount,
    date: date,
    type: type,
    description: description,
    reference: reference,
    network: network,
    goalName: goalName ?? this.goalName,
  );

  Map<String, dynamic> toMap() => {
    'amount': amount,
    'date': date.toIso8601String(),
    'type': type,
    if (description != null) 'description': description,
    if (reference != null) 'reference': reference,
    if (network != null) 'network': network,
  };

  factory SavingsEntry.fromMap(Map<String, dynamic> map) {
    final rawDate = map['date'];
    final date = rawDate is DateTime
        ? rawDate
        : DateTime.tryParse(rawDate as String? ?? '') ?? DateTime.now();
    return SavingsEntry(
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      date: date,
      type: map['type'] as String? ?? 'deposit',
      description: map['description'] as String?,
      reference: map['reference'] as String?,
      network: map['network'] as String?,
      goalName: map['goal'] as String?,
    );
  }
}
