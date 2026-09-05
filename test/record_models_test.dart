import 'package:flutter_test/flutter_test.dart';
import 'package:kibubu/models/loan_repayment.dart';
import 'package:kibubu/models/savings_entry.dart';

void main() {
  test('SavingsEntry inahifadhi fields zake na kurudi kama model', () {
    final entry = SavingsEntry(
      amount: 12500,
      date: DateTime(2026, 3, 4, 9),
      type: 'deposit',
      description: 'Amana',
      reference: 'KB-123',
      network: 'M-Pesa',
    );

    final restored = SavingsEntry.fromMap(entry.toMap());

    expect(restored.amount, 12500);
    expect(restored.date, entry.date);
    expect(restored.type, 'deposit');
    expect(restored.description, 'Amana');
    expect(restored.reference, 'KB-123');
    expect(restored.network, 'M-Pesa');
  });

  test('LoanRepayment inahifadhi na kupakia tarehe na kiasi', () {
    final repayment = LoanRepayment(
      amount: 25000,
      date: DateTime(2026, 3, 4, 12),
    );

    final restored = LoanRepayment.fromMap(repayment.toMap());

    expect(restored.amount, 25000);
    expect(restored.date, repayment.date);
  });
}
