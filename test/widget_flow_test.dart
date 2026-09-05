import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibubu/pages/auth_pages.dart';
import 'package:kibubu/pages/dashboard_page.dart';
import 'package:kibubu/pages/goal_pages.dart';
import 'package:kibubu/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dashboard ina Timer.periodic (countdown) — pumpAndSettle haitoshi.
/// Tumia pump kadhaa za muda uliopimwa badala yake.
Future<void> settle(
  WidgetTester tester, [
  Duration duration = const Duration(milliseconds: 300),
]) async {
  // Pump 3 za nyongeza: kamilisha microtasks (prefs), navigation transition,
  // na frame ya mwisho ya dashboard.
  await tester.pump(duration);
  await tester.pump(duration);
  await tester.pump(duration);
}

Future<void> resetPrefs() async {
  SharedPreferences.setMockInitialValues({});
  await loadData();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Register: validation inazuia PIN fupi na simu batili', (
    tester,
  ) async {
    await resetPrefs();
    await tester.pumpWidget(const MaterialApp(home: RegisterPage()));
    await tester.pumpAndSettle();

    // Bofya save bila kujaza — lazima ikae kwenye validation
    await tester.ensureVisible(find.text('HIFADHI AKAUNTI 💾'));
    await tester.tap(find.text('HIFADHI AKAUNTI 💾'));
    await settle(tester);

    // Page bado iko (hakuna navigation)
    expect(find.byType(RegisterPage), findsOneWidget);

    // Jaza jina tu, PIN fupi
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Jina kamili'),
      'Amina',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Namba ya simu'),
      '0712345678',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tarehe ya kuzaliwa'),
      '2000-01-01',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Mkoa'), 'Dar');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Wilaya'),
      'Ilala',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Kijiji / Mtaa'),
      'Tabata',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'PIN / Namba ya siri'),
      '12',
    );
    await tester.ensureVisible(find.text('HIFADHI AKAUNTI 💾'));
    await tester.tap(find.text('HIFADHI AKAUNTI 💾'));
    await settle(tester);
    expect(find.text('PIN iwe na tarakimu 4 au zaidi.'), findsOneWidget);

    // PIN sahihi ila simu batili
    await tester.enterText(
      find.widgetWithText(TextFormField, 'PIN / Namba ya siri'),
      '1234',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Namba ya simu'),
      'abc',
    );
    await tester.ensureVisible(find.text('HIFADHI AKAUNTI 💾'));
    await tester.tap(find.text('HIFADHI AKAUNTI 💾'));
    await settle(tester);
    expect(find.text('Weka namba sahihi, mfano 0712345678.'), findsOneWidget);
  });

  testWidgets('Register → Dashboard: PIN inahifadhiwa kama hash', (
    tester,
  ) async {
    await resetPrefs();
    await tester.pumpWidget(const MaterialApp(home: RegisterPage()));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Jina kamili'),
      'Amina',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'PIN / Namba ya siri'),
      '1234',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Namba ya simu'),
      '0712345678',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tarehe ya kuzaliwa'),
      '2000-01-01',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Mkoa'), 'Dar');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Wilaya'),
      'Ilala',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Kijiji / Mtaa'),
      'Tabata',
    );

    await tester.ensureVisible(find.text('HIFADHI AKAUNTI 💾'));
    await tester.tap(find.text('HIFADHI AKAUNTI 💾'));
    await settle(tester);

    // Tumeingia dashboard
    expect(find.byType(DashboardPage), findsOneWidget);
    expect(find.textContaining('Amina'), findsWidgets);

    // Kwenye prefs, hakuna PIN wazi — kuna hash tu
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('pin'), isNull);
    expect(prefs.getString('pinHash'), isNotNull);
    expect(prefs.getString('pinHash'), isNot(contains('1234')));
    expect(verifyPin('1234'), isTrue);
    expect(verifyPin('9999'), isFalse);
  });

  testWidgets('Login: PIN mbaya inakataa, PIN sahihi inaingia', (tester) async {
    await resetPrefs();
    // Tengeneza account moja kwa moja
    fullName = 'Amina';
    phone = '0712345678';
    await setPin('1234');
    expect(verifyPin('0000'), isFalse);

    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Namba ya simu'),
      '0712345678',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'PIN / Namba ya siri'),
      '0000',
    );
    await tester.tap(find.text('INGIA'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'PIN / Namba ya siri'),
      '1234',
    );
    await tester.tap(find.text('INGIA'));
    await tester.pumpAndSettle();
    expect(find.byType(DashboardPage), findsOneWidget);
  });

  testWidgets('Dashboard bila lengo: inaonyesha ujumbe wa kuhamasisha', (
    tester,
  ) async {
    await resetPrefs();
    fullName = 'Amina';
    phone = '0712345678';

    await tester.pumpWidget(const MaterialApp(home: DashboardPage()));
    await tester.pumpAndSettle();

    expect(find.text('Bado hujatengeneza lengo.'), findsOneWidget);
    expect(find.text('TENGENEZA LENGO 🎯'), findsOneWidget);
  });

  testWidgets('GoalPage: tarehe inabidi kwanza kabla ya ku-save', (
    tester,
  ) async {
    await resetPrefs();
    await tester.pumpWidget(const MaterialApp(home: GoalPage()));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Jina la Lengo'),
      'Kompyuta',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Kiasi cha Lengo'),
      '500000',
    );
    await tester.ensureVisible(find.text('SAVE LENGO 💾'));
    await tester.tap(find.text('SAVE LENGO 💾'));
    await tester.pumpAndSettle();

    // Inakataa kwa sababu tarehe hazijachaguliwa
    expect(
      find.text('Jaza taarifa zote na weka kiasi sahihi cha lengo.'),
      findsOneWidget,
    );
    expect(find.byType(GoalPage), findsOneWidget);
  });

  testWidgets('GoalsPage: empty state yenye kitufe cha kuongeza', (
    tester,
  ) async {
    await resetPrefs();
    goals.clear();
    goalName = '';

    await tester.pumpWidget(const MaterialApp(home: GoalsPage()));
    await tester.pumpAndSettle();

    expect(find.text('Bado hujatengeneza lengo.'), findsOneWidget);
    expect(find.text('ONGEZA LENGO'), findsOneWidget);
  });
}
