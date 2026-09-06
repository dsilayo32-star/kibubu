import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibubu/models/goal.dart';
import 'package:kibubu/pages/profile_page.dart';
import 'package:kibubu/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Historia: inaonyesha miamala ya malengo yote', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await loadData();

    // Malengo mawili, kila moja na historia yake.
    goals.clear();
    goals.addAll([
      Goal.fromMap({
        'name': 'Kompyuta',
        'target': 500000.0,
        'saved': 10000.0,
        'start': DateTime(2026, 2, 1).toIso8601String(),
        'end': DateTime(2026, 6, 1).toIso8601String(),
        'completed': false,
        'history': [
          {
            'amount': 10000.0,
            'date': DateTime(2026, 2, 5, 10).toIso8601String(),
            'type': 'deposit',
          },
        ],
      }),
      Goal.fromMap({
        'name': 'Baiskeli',
        'target': 200000.0,
        'saved': 5000.0,
        'start': DateTime(2026, 2, 1).toIso8601String(),
        'end': DateTime(2026, 6, 1).toIso8601String(),
        'completed': false,
        'history': [
          {
            'amount': 5000.0,
            'date': DateTime(2026, 2, 8, 12).toIso8601String(),
            'type': 'deposit',
          },
        ],
      }),
    ]);
    // Active goal: Baiskeli (history yake iko live kwenye savingsHistory).
    activeGoalIndex = 1;
    loadGoalRecord(goals[1]);

    await tester.pumpWidget(const MaterialApp(home: SavingsHistoryPage()));
    await tester.pumpAndSettle();

    // Miamala ya malengo yote inaonekana (scroll — ListView ni lazy).
    for (var i = 0; i < 4; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();
      if (find.textContaining('ULIWEKA').evaluate().isNotEmpty) break;
    }
    expect(find.textContaining('ULIWEKA'), findsWidgets);
    expect(find.textContaining('Kompyuta'), findsWidgets);
    expect(find.textContaining('Baiskeli'), findsWidgets);
  });
}
