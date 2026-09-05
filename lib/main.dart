import 'package:flutter/material.dart';

import 'pages/home_page.dart';
import 'services/firebase_service.dart';
import 'services/notification_service.dart';
import 'state/app_state.dart';
import 'state/group_state.dart';
import 'theme/app_theme.dart';

final notificationService = NotificationService();
final firebaseService = FirebaseService();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadData();
  await loadGroupsData();
  await checkAndApplyAllInactivityFees();
  await refreshLoanStatuses();
  await FirebaseService.init();
  await notificationService.init();
  if (notificationsEnabled) {
    await notificationService.enableDailyReminder();
    if (daysUntilInactivityFee > 0 && daysUntilInactivityFee <= 7) {
      await notificationService.scheduleInactivityWarning(daysUntilInactivityFee);
    }
    final loan = activeLoan;
    if (loan != null) await notificationService.scheduleLoanReminder(loan.dueDate);
  }
  runApp(const KibubuApp());
}

class KibubuApp extends StatelessWidget {
  const KibubuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Kibubu',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          home: const HomePage(),
        );
      },
    );
  }
}