class LoanRepayment {
  const LoanRepayment({required this.amount, required this.date});

  final double amount;
  final DateTime date;

  Map<String, dynamic> toMap() => {
    'amount': amount,
    'date': date.toIso8601String(),
  };

  factory LoanRepayment.fromMap(Map<String, dynamic> map) {
    final rawDate = map['date'];
    return LoanRepayment(
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      date: rawDate is DateTime
          ? rawDate
          : DateTime.tryParse(rawDate as String? ?? '') ?? DateTime.now(),
    );
  }
}
