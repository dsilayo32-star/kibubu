import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../state/app_state.dart';
import 'notification_service.dart';

/// Sehemu ya Mipangilio: vikumbusho, biometrics, dark mode na cloud sync.
class SettingsService {
  static Future<void> setNotificationsEnabled(bool value) async {
    notificationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', value);
    final service = NotificationService();
    if (value) {
      await service.enableDailyReminder();
      if (daysUntilInactivityFee > 0 && daysUntilInactivityFee <= 7) {
        await service.scheduleInactivityWarning(daysUntilInactivityFee);
      }
      final loan = activeLoan;
      if (loan != null) await service.scheduleLoanReminder(loan.dueDate);
    } else {
      await service.disableDailyReminder();
    }
  }

  static Future<void> setBiometricsEnabled(bool value) async {
    biometricsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometricsEnabled', value);
  }

  static Future<void> setDarkMode(bool value) async {
    darkMode = value;
    themeModeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
  }
}

class SettingsSectionState {
  // Placeholder ili kupunguza hatari ya naming conflicts.
}
