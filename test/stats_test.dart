import 'package:flutter_test/flutter_test.dart';
import 'package:kibubu/models/savings_entry.dart';
import 'package:kibubu/utils/stats.dart';

HistoryEntry deposit(double amount, DateTime date) =>
    SavingsEntry(amount: amount, date: date);

HistoryEntry withdraw(double amount, DateTime date) =>
    SavingsEntry(amount: amount, date: date, type: 'withdraw');

void main() {
  final now = DateTime(2026, 2, 11, 14, 30); // Alhamisi

  group('netSaved', () {
    test('inajumlisha deposits na kuondoa withdrawals', () {
      final history = [
        deposit(10000, DateTime(2026, 2, 1)),
        deposit(5000, DateTime(2026, 2, 5)),
        withdraw(2000, DateTime(2026, 2, 7)),
        deposit(1000, DateTime(2026, 1, 15)), // nje ya kipindi
      ];
      final net = netSaved(
        history,
        DateTime(2026, 2, 1),
        DateTime(2026, 2, 28),
      );
      expect(net, 13000);
    });

    test('inapuuza entries zenye tarehe batili', () {
      final history = [deposit(500, DateTime(2026, 2, 2))];
      final net = netSaved(
        history,
        DateTime(2026, 2, 1),
        DateTime(2026, 2, 28),
      );
      expect(net, 500);
    });
  });

  group('summarize', () {
    test('inahesabu deposits, withdrawals na siku tofauti', () {
      final history = [
        deposit(3000, DateTime(2026, 2, 2, 8)),
        deposit(2000, DateTime(2026, 2, 2, 20)), // siku ileile
        withdraw(1000, DateTime(2026, 2, 3)),
        deposit(4000, DateTime(2026, 2, 10)),
      ];
      final s = summarize(history, DateTime(2026, 2, 1), DateTime(2026, 2, 28));
      expect(s.deposits, 9000);
      expect(s.withdrawals, 1000);
      expect(s.net, 8000);
      expect(s.daysSaved, 2);
      expect(s.averagePerActiveDay, 4500);
    });

    test('kipindi tupu kunarudisha zeros', () {
      final s = summarize([], DateTime(2026, 2, 1), DateTime(2026, 2, 28));
      expect(s.net, 0);
      expect(s.daysSaved, 0);
      expect(s.averagePerActiveDay, 0);
    });
  });

  group('weekStart', () {
    test('inarudisha Jumatatu ya wiki hiyo', () {
      // 11 Feb 2026 ni Alhamisi (weekday 4)
      expect(weekStart(now), DateTime(2026, 2, 9));
    });

    test('Jumatatu inabaki Jumatatu', () {
      final monday = DateTime(2026, 2, 9);
      expect(weekStart(monday), DateTime(2026, 2, 9));
    });
  });

  group('monthStart', () {
    test('inarudisha siku ya 1 ya mwezi', () {
      expect(monthStart(now), DateTime(2026, 2, 1));
    });
  });

  group('last7DaysTotals', () {
    test('inarudisha siku 7 kwa mpangilio, na jumla sahihi', () {
      final history = [
        deposit(100, DateTime(2026, 2, 10, 9)),
        deposit(200, DateTime(2026, 2, 10, 18)),
      ];
      final totals = last7DaysTotals(history, now);
      expect(totals.length, 7);
      expect(totals.last.day, DateTime(2026, 2, 11));
      // 10 Feb iko kwenye orodha (index ya pili kutoka mwisho)
      final feb10 = totals.firstWhere((d) => d.day.day == 10);
      expect(feb10.total, 300);
      final feb9 = totals.firstWhere((d) => d.day.day == 9);
      expect(feb9.total, 0);
    });
  });

  group('last6MonthsTotals', () {
    test('inarudisha miezi 6, ikijumuisha kuvuka mwaka', () {
      final history = [deposit(7000, DateTime(2025, 12, 20))];
      final totals = last6MonthsTotals(history, now);
      expect(totals.length, 6);
      expect(totals.first.month, DateTime(2025, 9));
      final dec = totals.firstWhere((m) => m.month.month == 12);
      expect(dec.total, 7000);
    });
  });
}
