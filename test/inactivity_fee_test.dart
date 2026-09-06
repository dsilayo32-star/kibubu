import 'package:flutter_test/flutter_test.dart';
import 'package:kibubu/models/goal.dart';
import 'package:kibubu/state/app_state.dart' as state;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    state.goals = [];
    state.activeGoalIndex = -1;
    state.goalName = '';
    state.targetAmount = 0;
    state.savedAmount = 0;
    state.savingsHistory = [];
    state.startDate = null;
    state.endDate = null;
    state.lastSavedAt = null;
    state.lastPenaltyAt = null;
    state.goalCompleted = false;
  });

  group('Kanuni ya Tozo ya Kutoweka Akiba (Wiki 3 / 6%)', () {
    test('daysSinceLastDeposit inarudisha siku sahihi', () {
      final now = DateTime.now();
      state.lastSavedAt = now.subtract(const Duration(days: 10));
      expect(state.daysSinceLastDeposit, 10);
      expect(state.daysUntilInactivityFee, 11);
    });

    test('isInactivityFeeApplicable ni false kama chini ya siku 21', () {
      final now = DateTime.now();
      state.savedAmount = 100000;
      state.lastSavedAt = now.subtract(const Duration(days: 20));
      expect(state.isInactivityFeeApplicable, isFalse);
    });

    test('isInactivityFeeApplicable ni true kama siku 21 au zaidi zimepita na kuna akiba', () {
      final now = DateTime.now();
      state.savedAmount = 100000;
      state.lastSavedAt = now.subtract(const Duration(days: 22));
      expect(state.isInactivityFeeApplicable, isTrue);
      expect(state.inactivityFeeAmount, 6000.0); // 6% ya 100,000 = 6,000
    });

    test(
      'applyInactivityFeeIfNeeded inakata 6% na kuweka rekodi kwenye history',
      () async {
        final now = DateTime.now();
        state.goalName = 'Gari';
        state.targetAmount = 500000;
        state.savedAmount = 100000;
        state.lastSavedAt = now.subtract(const Duration(days: 25));

        final applied = await state.applyInactivityFeeIfNeeded();

        expect(applied, isTrue);
        expect(state.savedAmount, 94000.0); // 100,000 - 6,000 = 94,000
        expect(state.savingsHistory.length, 1);
        expect(state.savingsHistory[0].type, 'penalty');
        expect(state.savingsHistory[0].amount, 6000.0);
        expect(state.lastPenaltyAt, isNotNull);
      },
    );

    test('checkAndApplyAllInactivityFees inakagua malengo yote na kuzuia tozo kurudiwa ndani ya siku 21', () async {
      final now = DateTime.now();
      state.goals = [
        Goal.fromMap({
          'name': 'Lengo A (Inactive)',
          'target': 200000.0,
          'saved': 50000.0,
          'completed': false,
          'lastSavedAt': now
              .subtract(const Duration(days: 30))
              .toIso8601String(),
          'history': [],
        }),
        Goal.fromMap({
          'name': 'Lengo B (Active hivi karibuni)',
          'target': 200000.0,
          'saved': 50000.0,
          'completed': false,
          'lastSavedAt': now
              .subtract(const Duration(days: 5))
              .toIso8601String(),
          'history': [],
        }),
      ];

      final count = await state.checkAndApplyAllInactivityFees();
      expect(count, 1);
      expect(state.goals[0].saved, 47000.0); // 50,000 - 6% (3,000) = 47,000
      expect(state.goals[1].saved, 50000.0); // Bado haijakatwa

      // Kama tutaiita tena mara moja, isikate tena kwa sababu lastPenaltyAt ni sasa
      final countAgain = await state.checkAndApplyAllInactivityFees();
      expect(countAgain, 0);
    });
  });
}
