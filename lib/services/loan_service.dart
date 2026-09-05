import 'dart:math';

import '../models/loan_repayment.dart';

/// Mfumo wa Mikopo ya Kibubu (Akiba kama Dhamana)
/// Kanuni:
/// 1. Akiba ya chini ya kufungua mkopo: TSh 50,000
/// 2. Kiwango cha juu cha mkopo: 20% ya akiba ya mtumiaji
/// 3. Riba ya mkopo: 10% ya kiasi kilichokopwa
/// 4. Akiba hutumika kama dhamana ya mkopo

class LoanRecord {
  LoanRecord({
    required this.id,
    required this.principal,
    required this.interestRate,
    required this.interestAmount,
    required this.totalRepayable,
    required this.amountPaid,
    required this.borrowedDate,
    required this.dueDate,
    required this.status,
    this.purpose = 'Dhamana ya Akiba',
    this.repayments = const [],
  });

  final String id;
  final double principal;
  final double interestRate; // e.g. 0.10 for 10%
  final double interestAmount;
  final double totalRepayable;
  double amountPaid;
  final DateTime borrowedDate;
  final DateTime dueDate;
  String status; // 'ACTIVE', 'REPAID', 'OVERDUE'
  final String purpose;
  List<LoanRepayment> repayments;

  double get remainingBalance =>
      (totalRepayable - amountPaid).clamp(0.0, totalRepayable);

  bool get isFullyPaid => amountPaid >= totalRepayable;

  bool get isOverdue =>
      status == 'ACTIVE' && DateTime.now().isAfter(dueDate) && !isFullyPaid;

  Map<String, dynamic> toMap() => {
    'id': id,
    'principal': principal,
    'interestRate': interestRate,
    'interestAmount': interestAmount,
    'totalRepayable': totalRepayable,
    'amountPaid': amountPaid,
    'borrowedDate': borrowedDate.toIso8601String(),
    'dueDate': dueDate.toIso8601String(),
    'status': status,
    'purpose': purpose,
    'repayments': repayments.map((repayment) => repayment.toMap()).toList(),
  };

  factory LoanRecord.fromMap(Map<String, dynamic> map) {
    return LoanRecord(
      id:
          map['id'] as String? ??
          'LOAN-${DateTime.now().millisecondsSinceEpoch}',
      principal: (map['principal'] as num?)?.toDouble() ?? 0.0,
      interestRate: (map['interestRate'] as num?)?.toDouble() ?? 0.10,
      interestAmount: (map['interestAmount'] as num?)?.toDouble() ?? 0.0,
      totalRepayable: (map['totalRepayable'] as num?)?.toDouble() ?? 0.0,
      amountPaid: (map['amountPaid'] as num?)?.toDouble() ?? 0.0,
      borrowedDate:
          DateTime.tryParse(map['borrowedDate'] as String? ?? '') ??
          DateTime.now(),
      dueDate:
          DateTime.tryParse(map['dueDate'] as String? ?? '') ??
          DateTime.now().add(const Duration(days: 30)),
      status: map['status'] as String? ?? 'ACTIVE',
      purpose: map['purpose'] as String? ?? 'Dhamana ya Akiba',
      repayments: (map['repayments'] as List<dynamic>? ?? [])
          .map(
            (item) =>
                LoanRepayment.fromMap(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
    );
  }
}

class LoanService {
  /// Kiwango cha chini cha akiba ili kufungua fursa ya kukopa (TSh 50,000)
  static const double minSavingsRequired = 50000.0;

  /// Asilimia ya juu ya akiba anayoruhusiwa kukopa (20%)
  static const double maxBorrowPercentage = 0.20;

  /// Riba ya mkopo (10%)
  static const double interestRate = 0.10;

  /// Angalia kama mtumiaji amekidhi vigezo vya kukopa
  static bool isEligibleForLoan(double totalSavings) {
    return totalSavings >= minSavingsRequired;
  }

  /// Kiasi cha juu cha mkopo anachoweza kuchukua (20% ya akiba)
  static double calculateMaxLoan(double totalSavings) {
    if (totalSavings < minSavingsRequired) return 0.0;
    return totalSavings * maxBorrowPercentage;
  }

  /// Hesabu ya riba ya mkopo (10%)
  static double calculateInterest(double principal) {
    return principal * interestRate;
  }

  /// Hesabu ya jumla ya kiasi cha kurejesha (Kuu + Riba ya 10%)
  static double calculateTotalRepayable(double principal) {
    return principal + calculateInterest(principal);
  }

  /// Thibitisha maombi ya mkopo
  static String? validateLoanRequest({
    required double requestedAmount,
    required double totalSavings,
    required bool hasActiveLoan,
  }) {
    if (hasActiveLoan) {
      return 'Tayari una mkopo ambao haujakamilika kurejeshwa. Kamilisha kwanza.';
    }
    if (totalSavings < minSavingsRequired) {
      return 'Unahitaji kufikisha akiba ya kuanzia TSh 50,000 ili kufungua huduma ya mikopo.';
    }
    if (requestedAmount <= 0) {
      return 'Tafadhali weka kiasi halali cha mkopo.';
    }
    final maxAllowed = calculateMaxLoan(totalSavings);
    if (requestedAmount > maxAllowed) {
      return 'Kiwango cha juu unachoweza kukopa ni 20% ya akiba yako (TSh ${maxAllowed.toStringAsFixed(0)}).';
    }
    return null;
  }

  /// Tengeneza namba ya kumbukumbu ya mkopo
  static String generateLoanId() {
    final rand = Random().nextInt(9000) + 1000;
    return 'MKP-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}-$rand';
  }
}
