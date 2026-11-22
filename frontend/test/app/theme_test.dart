import 'package:claim_whats_yours/app/theme/app_colors.dart';
import 'package:claim_whats_yours/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Light theme can be constructed with Material 3', () {
    final light = AppTheme.lightTheme;
    expect(light.useMaterial3, isTrue);
    expect(light.brightness, Brightness.light);
    expect(light.colorScheme.primary, AppColors.primary);
  });

  test('Dark theme can be constructed with Material 3', () {
    final dark = AppTheme.darkTheme;
    expect(dark.useMaterial3, isTrue);
    expect(dark.brightness, Brightness.dark);
  });
}
