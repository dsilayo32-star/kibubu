import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Huduma ya vikumbusho: kikumbusho cha kila siku cha kuweka akiba.
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      tz.initializeTimeZones();
      final localName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localName));

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      await _plugin.initialize(
        const InitializationSettings(android: androidInit, iOS: iosInit),
      );

      if (defaultTargetPlatform == TargetPlatform.android) {
        await _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
      }
      _initialized = true;
    } catch (_) {
      // App inaendelea hata kama notifications zimeshindikana.
    }
  }

  /// Weka kikumbusho cha kila siku saa mbili usiku (20:00).
  Future<void> enableDailyReminder() async {
    if (!_initialized) await init();
    try {
      await _plugin.zonedSchedule(
        1,
        '💰 Muda wa kuweka akiba!',
        'Fikia lengo lako — weka akiba yako ya leo kwenye Kibubu.',
        _nextInstanceOf(20, 0),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'kibubu_reminder',
            'Vikumbusho vya akiba',
            channelDescription: 'Kikumbusho cha kila siku cha kuweka akiba',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {}
  }

  Future<void> scheduleInactivityWarning(int daysRemaining) async {
    if (!_initialized) await init();
    if (daysRemaining <= 0) return;
    try {
      await _plugin.zonedSchedule(
        2,
        'Kumbusho la Kibubu',
        'Zimebaki siku $daysRemaining kabla ya tozo ya kutoweka akiba.',
        _nextInstanceOf(9, 0),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'kibubu_warnings',
            'Tahadhari za Kibubu',
            channelDescription: 'Tahadhari za inactivity fee na mikopo',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {}
  }

  Future<void> scheduleLoanReminder(DateTime dueDate) async {
    if (!_initialized) await init();
    final reminderDate = dueDate.subtract(const Duration(days: 3));
    if (reminderDate.isBefore(DateTime.now())) return;
    try {
      await _plugin.zonedSchedule(
        3,
        'Muda wa kurejesha mkopo unakaribia',
        'Kumbuka kurejesha mkopo wako wa Kibubu kabla ya tarehe ya mwisho.',
        tz.TZDateTime.from(reminderDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'kibubu_loans',
            'Vikumbusho vya mikopo',
            channelDescription: 'Kumbusho la tarehe ya mwisho ya mkopo',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {}
  }

  Future<void> disableDailyReminder() async {
    try {
      await _plugin.cancel(1);
      await _plugin.cancel(2);
      await _plugin.cancel(3);
    } catch (_) {}
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
