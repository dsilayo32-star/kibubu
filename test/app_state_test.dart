import 'package:flutter_test/flutter_test.dart';
import 'package:kibubu/models/savings_entry.dart';
import 'package:kibubu/state/app_state.dart' as state;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('goalRecord() / loadGoalRecord()', () {
    test('inahifadhi na kupakia lengo kikamilifu', () {
      state.goalName = 'Ada ya shule';
      state.targetAmount = 100000;
      state.savedAmount = 25000;
      state.goalCompleted = false;
      state.startDate = DateTime(2026, 1, 1);
      state.endDate = DateTime(2026, 2, 1);
      state.savingsHistory = [
        SavingsEntry(amount: 15000, date: DateTime(2026, 1, 5)),
        SavingsEntry(
          amount: 5000,
          date: DateTime(2026, 1, 10),
          type: 'withdrawal',
        ),
      ];

      final record = state.goalRecord();

      expect(record['name'], 'Ada ya shule');
      expect(record['target'], 100000);
      expect(record['saved'], 25000);
      expect((record['history'] as List).length, 2);
      expect((record['history'] as List).first['type'], 'deposit');

      // Futa memory kisha pakia kutoka record
      state.goalName = '';
      state.targetAmount = 0;
      state.savedAmount = 0;
      state.savingsHistory = [];

      state.loadGoalRecord(record);

      expect(state.goalName, 'Ada ya shule');
      expect(state.targetAmount, 100000);
      expect(state.savedAmount, 25000);
      expect(state.savingsHistory.length, 2);
      expect(state.savingsHistory.last.type, 'withdrawal');
      expect(state.savingsHistory.last.date, DateTime(2026, 1, 10));
    });

    test('inapokea type iliyokosekana kama deposit', () {
      state.goalName = 'X';
      state.targetAmount = 10;
      state.savedAmount = 5;
      state.goalCompleted = false;
      state.startDate = null;
      state.endDate = null;
      state.savingsHistory = [
        SavingsEntry(amount: 5, date: DateTime(2026, 1, 5)),
      ];

      final record = state.goalRecord();
      expect((record['history'] as List).first['type'], 'deposit');
    });
  });

  group('goalPastDeadline & remainingDuration', () {
    test('deadline iliyopita inaonyeshwa', () {
      state.endDate = DateTime.now().subtract(const Duration(days: 3));
      expect(state.goalPastDeadline, isTrue);
    });

    test('deadline ijayo haijafika', () {
      state.endDate = DateTime.now().add(const Duration(days: 3));
      expect(state.goalPastDeadline, isFalse);
    });

    test('bila deadline, hairudishi true', () {
      state.endDate = null;
      expect(state.goalPastDeadline, isFalse);
    });

    test('remainingDuration inaisha kwa deadline', () {
      state.endDate = DateTime.now().add(const Duration(days: 2));
      final remaining = state.remainingDuration;
      // Deadline ni 23:59:59 ya siku ileile — kati ya siku 2 na 3 kamili.
      expect(remaining.inHours, greaterThan(24));
      expect(remaining.inHours, lessThanOrEqualTo(72));
      expect(remaining.inMinutes, greaterThan(0));
    });
  });

  group('progressValue & goalReachedTarget', () {
    test('progress 0 kama target 0', () {
      state.targetAmount = 0;
      state.savedAmount = 0;
      expect(state.progressValue, 0.0);
    });

    test('progress inafikia 1.0 na haisongee zaidi', () {
      state.targetAmount = 1000;
      state.savedAmount = 2500;
      expect(state.progressValue, 1.0);
      expect(state.goalReachedTarget, isTrue);
    });

    test('hakikisha 50%', () {
      state.targetAmount = 1000;
      state.savedAmount = 500;
      expect(state.progressValue, closeTo(0.5, 0.001));
      expect(state.goalReachedTarget, isFalse);
    });
  });

  group('countdownText()', () {
    test('inaonyesha siku na saa', () {
      final now = DateTime.now();
      state.endDate = DateTime(now.year, now.month, now.day + 1);
      final text = state.countdownText();
      expect(text, contains('Siku 1'));
      expect(text, contains(':'));
    });
  });

  group('syncActiveGoal()', () {
    test('inaandika upya lengo lililo active tu', () {
      state.goals = [
        {'name': 'Lengo A', 'target': 100, 'saved': 10},
        {'name': 'Lengo B', 'target': 200, 'saved': 20},
      ];
      state.activeGoalIndex = 1;

      state.goalName = 'Lengo B';
      state.targetAmount = 250;
      state.savedAmount = 30;
      state.goalCompleted = false;
      state.startDate = null;
      state.endDate = null;
      state.savingsHistory = [];

      state.syncActiveGoal();

      expect(state.goals[0]['name'], 'Lengo A');
      expect(state.goals[0]['target'], 100);
      expect(state.goals[1]['target'], 250);
      expect(state.goals[1]['saved'], 30);
    });

    test('hakuna index active — hakuna kinachoharibika', () {
      state.goals = [
        {'name': 'Lengo A', 'target': 100, 'saved': 10},
      ];
      state.activeGoalIndex = -1;
      state.goalName = 'X';
      state.targetAmount = 1;
      state.savedAmount = 1;
      state.goalCompleted = false;
      state.startDate = null;
      state.endDate = null;
      state.savingsHistory = [];

      state.syncActiveGoal();
      expect(state.goals.length, 1);
      expect(state.goals[0]['name'], 'Lengo A');
    });
  });

  group('deleteGoal() & updateGoal()', () {
    test('deleteGoal() inafuta lengo na kurekebisha activeGoalIndex', () async {
      state.goals = [
        {
          'name': 'Lengo 1',
          'target': 100,
          'saved': 10,
          'completed': false,
          'history': [],
        },
        {
          'name': 'Lengo 2',
          'target': 200,
          'saved': 20,
          'completed': false,
          'history': [],
        },
        {
          'name': 'Lengo 3',
          'target': 300,
          'saved': 30,
          'completed': false,
          'history': [],
        },
      ];
      state.activeGoalIndex = 1;

      await state.deleteGoal(1);

      expect(state.goals.length, 2);
      expect(state.goals[0]['name'], 'Lengo 1');
      expect(state.goals[1]['name'], 'Lengo 3');
      expect(state.activeGoalIndex, 1);
      expect(state.goalName, 'Lengo 3');
    });

    test('deleteGoal() inafuta lengo la mwisho kabisa na kuweka activeGoalIndex -1', () async {
      state.goals = [
        {
          'name': 'Lengo Pekee',
          'target': 100,
          'saved': 10,
          'completed': false,
          'history': [],
        },
      ];
      state.activeGoalIndex = 0;
      state.goalName = 'Lengo Pekee';
      state.targetAmount = 100;

      await state.deleteGoal(0);

      expect(state.goals.isEmpty, isTrue);
      expect(state.activeGoalIndex, -1);
      expect(state.goalName, '');
      expect(state.targetAmount, 0);
    });

    test('updateGoal() inasasisha jina, target na tarehe', () async {
      final start = DateTime(2026, 1, 1);
      final end = DateTime(2026, 6, 1);
      state.goals = [
        {
          'name': 'Lengo La Zamani',
          'target': 100,
          'saved': 10,
          'completed': false,
          'history': [],
        },
      ];
      state.activeGoalIndex = 0;

      await state.updateGoal(
        index: 0,
        name: 'Lengo Jipya',
        target: 500,
        start: start,
        end: end,
      );

      expect(state.goals[0]['name'], 'Lengo Jipya');
      expect(state.goals[0]['target'], 500);
      expect(state.goalName, 'Lengo Jipya');
      expect(state.targetAmount, 500);
      expect(state.startDate, start);
      expect(state.endDate, end);
    });
  });

  group('loan validation', () {
    test('applyForLoan inakataa duration isiyo sahihi', () async {
      state.userLoans = [];
      state.goals = [
        {'name': 'Lengo', 'saved': 100000.0, 'target': 200000.0},
      ];

      final error = await state.applyForLoan(
        requestedAmount: 10000,
        purpose: 'Dharura',
        durationDays: 0,
      );

      expect(error, contains('siku 1 na 365'));
      expect(state.userLoans, isEmpty);
    });
  });
}
