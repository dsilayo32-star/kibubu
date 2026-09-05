import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibubu/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('AppTheme.light ina brightness light na msingi wa kijani', () {
      final light = AppTheme.light;
      expect(light.brightness, Brightness.light);
      expect(light.useMaterial3, isTrue);
      expect(light.scaffoldBackgroundColor, AppColors.bg);
    });

    test('AppTheme.dark ina brightness dark na rangi ya giza', () {
      final dark = AppTheme.dark;
      expect(dark.brightness, Brightness.dark);
      expect(dark.useMaterial3, isTrue);
      expect(dark.scaffoldBackgroundColor, AppColors.darkBg);
    });
  });
}
