import 'package:flutter/material.dart';

/// Minimal restrained design system colors for Claim What's Yours.
///
/// Palette specifications:
/// Light theme:
/// - Background: #FAFAFA / #FFFFFF
/// - Cards / Surfaces: #FFFFFF
/// - Primary text: #202124
/// - Secondary text: #6B7280
/// - Borders / Dividers: #E5E7EB
/// - Muted Indigo (Primary): #5967A8
/// - Soft Teal (Secondary): #4D8C87
/// - Muted Lavender (Accent): #8B78AD
/// - Status Success: #4F896B
/// - Status Warning: #B68B4C
/// - Status Error: #C46C6C
///
/// Dark theme:
/// - Background: #121417
/// - Cards / Surfaces: #1C2025
/// - Elevated surfaces: #242A31
/// - Primary text: #F3F4F6
/// - Secondary text: #A1A7B0
/// - Borders / Dividers: #303741
/// - Muted Indigo (Primary): #929FE0
/// - Soft Teal (Secondary): #75B5AE
/// - Muted Lavender (Accent): #B2A0D2
abstract final class AppColors {
  // Brand Accents (Light)
  static const Color primary = Color(0xFF5967A8); // Muted Indigo
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFE8EBF8);
  static const Color onPrimaryContainer = Color(0xFF1F2954);

  static const Color secondary = Color(0xFF4D8C87); // Soft Teal
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFE2F1EF);
  static const Color onSecondaryContainer = Color(0xFF1B403D);

  static const Color tertiary = Color(0xFF8B78AD); // Muted Lavender
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFF1EDF8);
  static const Color onTertiaryContainer = Color(0xFF382B50);

  // Neutral Background & Surface - Light
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color onSurfaceLight = Color(0xFF202124);
  static const Color onSurfaceVariantLight = Color(0xFF6B7280);
  static const Color outlineLight = Color(0xFFE5E7EB);
  static const Color outlineVariantLight = Color(0xFFF0F2F5);

  // Neutral Background & Surface - Dark
  static const Color backgroundDark = Color(0xFF121417);
  static const Color surfaceDark = Color(0xFF1C2025);
  static const Color surfaceElevatedDark = Color(0xFF242A31);
  static const Color onSurfaceDark = Color(0xFFF3F4F6);
  static const Color onSurfaceVariantDark = Color(0xFFA1A7B0);
  static const Color outlineDark = Color(0xFF303741);
  static const Color outlineVariantDark = Color(0xFF252B33);

  // Brand Accents (Dark)
  static const Color primaryDark = Color(0xFF929FE0);
  static const Color onPrimaryDark = Color(0xFF141C40);
  static const Color primaryContainerDark = Color(0xFF2E386B);
  static const Color onPrimaryContainerDark = Color(0xFFDCE2FF);

  static const Color secondaryDark = Color(0xFF75B5AE);
  static const Color onSecondaryDark = Color(0xFF0F3532);
  static const Color secondaryContainerDark = Color(0xFF244E4B);
  static const Color onSecondaryContainerDark = Color(0xFFD2EDE9);

  static const Color tertiaryDark = Color(0xFFB2A0D2);
  static const Color onTertiaryDark = Color(0xFF2E2245);
  static const Color tertiaryContainerDark = Color(0xFF4A3B66);
  static const Color onTertiaryContainerDark = Color(0xFFEDE4FB);

  // Restrained Status Colors
  static const Color error = Color(0xFFC46C6C); // Muted Coral / Red
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFBEAEA);
  static const Color onErrorContainer = Color(0xFF5A1E1E);

  static const Color success = Color(0xFF4F896B); // Muted Olive / Sage Green
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color successContainer = Color(0xFFEBF5EF);
  static const Color onSuccessContainer = Color(0xFF1B402B);

  static const Color warning = Color(0xFFB68B4C); // Muted Sand / Ochre
  static const Color onWarning = Color(0xFFFFFFFF);
  static const Color warningContainer = Color(0xFFFAF2E6);
  static const Color onWarningContainer = Color(0xFF523B17);
}
