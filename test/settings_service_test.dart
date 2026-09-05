import 'package:flutter_test/flutter_test.dart';
import 'package:kibubu/services/settings_service.dart';
import 'package:kibubu/state/app_state.dart' as state;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    state.notificationsEnabled = false;
    state.biometricsEnabled = false;
    state.darkMode = false;
  });

  group('setNotificationsEnabled()', () {
    test('inahifadhi true kwenye prefs na state', () async {
      await SettingsService.setNotificationsEnabled(true);

      expect(state.notificationsEnabled, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('notificationsEnabled'), isTrue);
    });

    test('inahifadhi false kwenye prefs na state', () async {
      await SettingsService.setNotificationsEnabled(false);

      expect(state.notificationsEnabled, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('notificationsEnabled'), isFalse);
    });
  });

  group('setBiometricsEnabled()', () {
    test('inahifadhi true kwenye prefs na state', () async {
      await SettingsService.setBiometricsEnabled(true);

      expect(state.biometricsEnabled, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('biometricsEnabled'), isTrue);
    });

    test('inahifadhi false kwenye prefs na state', () async {
      await SettingsService.setBiometricsEnabled(false);

      expect(state.biometricsEnabled, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('biometricsEnabled'), isFalse);
    });
  });

  group('setDarkMode()', () {
    test('inahifadhi true kwenye prefs na state', () async {
      await SettingsService.setDarkMode(true);

      expect(state.darkMode, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('darkMode'), isTrue);
    });

    test('inahifadhi false kwenye prefs na state', () async {
      await SettingsService.setDarkMode(false);

      expect(state.darkMode, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('darkMode'), isFalse);
    });
  });
}
