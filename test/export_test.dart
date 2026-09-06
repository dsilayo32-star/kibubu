import 'package:flutter_test/flutter_test.dart';
import 'package:kibubu/models/goal.dart';
import 'package:kibubu/models/savings_entry.dart';
import 'package:kibubu/utils/export_helper.dart';

void main() {
  group('ExportHelper', () {
    test('generateCsv() inazalisha vichwa vya safu na miamala sahihi', () {
      final entries = [
        SavingsEntry(
          amount: 50000,
          date: DateTime(2026, 3, 1, 10, 30),
          goalName: 'Ada ya Shule',
        ),
        SavingsEntry(
          amount: 20000,
          date: DateTime(2026, 3, 2, 14, 0),
          type: 'withdrawal',
          goalName: 'Gari',
        ),
      ];

      final csv = ExportHelper.generateCsv(entries);
      expect(csv, contains('Tarehe,Lengo,Aina,Kiasi (TSh)'));
      expect(csv, contains('Ada ya Shule,Kuweka,50000.0'));
      expect(csv, contains('Gari,Kutoa,20000.0'));
    });

    test('generateTextSummary() inaweka taarifa zote muhimu', () {
      final goals = [
        Goal.fromMap({
          'name': 'Ada ya Shule',
          'target': 100000.0,
          'saved': 50000.0,
          'completed': false,
        }),
      ];
      final entries = [
        SavingsEntry(
          amount: 50000,
          date: DateTime(2026, 3, 1),
          goalName: 'Ada ya Shule',
        ),
      ];

      final summary = ExportHelper.generateTextSummary(
        userName: 'Amani',
        goalsList: goals,
        entries: entries,
        now: DateTime(2026, 3, 5),
      );

      expect(summary, contains('Amani'));
      expect(summary, contains('Ada ya Shule'));
      expect(summary, contains('50%'));
      expect(summary, contains('Jumla ya Amana'));
      expect(summary, contains('Salio Halisi'));
    });

    test('collectAllEntries() inakusanya miamala kutoka malengo tofauti na kupanga kwa tarehe', () {
      final goals = [
        Goal.fromMap({
          'name': 'Lengo 1',
          'history': [
            {
              'date': '2026-03-01T10:00:00.000',
              'amount': 1000,
              'type': 'deposit',
            },
          ],
        }),
      ];
      final currentHistory = [
        SavingsEntry(amount: 2000, date: DateTime(2026, 3, 2, 10, 0)),
      ];

      final all = ExportHelper.collectAllEntries(
        goalsList: goals,
        currentGoalName: 'Lengo 2',
        currentHistory: currentHistory,
      );

      expect(all.length, 2);
      expect(all[0].date.isAfter(all[1].date), isTrue);
      expect(all[0].amount, 2000.0);
      expect(all[1].amount, 1000.0);
    });
  });
}
