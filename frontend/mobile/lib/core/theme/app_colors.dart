import 'package:flutter/material.dart';

/// Enterprise Industrial Color Palette (Samsara & Linear Inspired)
class AppColors {
  AppColors._();

  // Core Canvas & Surfaces
  static const Color bgScreen = Color(0xFFF3F4F6);       // Clean Neutral Slate Canvas
  static const Color bgCard = Color(0xFFFFFFFF);         // Pure White Card
  static const Color bgInset = Color(0xFFF9FAFB);        // Subtle Inset
  static const Color bgDarkHero = Color(0xFF111827);     // Charcoal Solid Hero
  static const Color bgDarkCard = Color(0xFF1F2937);     // Dark Slate Card

  // Hairline Borders
  static const Color borderSubtle = Color(0xFFE5E7EB);   // Crisp 1px Border
  static const Color borderStrong = Color(0xFFD1D5DB);   // Active Border
  static const Color borderFocus = Color(0xFFEA580C);    // Safety Orange Accent

  // Primary Accent: International Safety Orange
  static const Color accentAmber = Color(0xFFEA580C);     // Primary Industrial Accent
  static const Color accentAmberLight = Color(0xFFF97316);// Hover / Light
  static const Color accentAmberDark = Color(0xFFC2410C); // Dark Pressed
  static const Color accentAmberSubtle = Color(0x1AEA580C);// 10% Tonal
  static const Color amberContainer = Color(0xFFF3F4F6);  // Neutral Container
  static const Color onAmberContainer = Color(0xFF111827);// Crisp Text

  // Dark Authority
  static const Color navyDeep = Color(0xFF111827);       // Slate-900 Primary
  static const Color navySlate = Color(0xFF1F2937);      // Slate-800
  static const Color navyContainer = Color(0xFFE5E7EB);  // Container

  // High-Contrast Legible Typography
  static const Color textMain = Color(0xFF111827);       // Slate-900 (High Contrast)
  static const Color textSub = Color(0xFF4B5563);        // Slate-600
  static const Color textMuted = Color(0xFF6B7280);      // Slate-500
  static const Color textWhite = Color(0xFFF9FAFB);      // White on Dark Surfaces

  // Operational Status
  static const Color statusSuccess = Color(0xFF059669);   // Emerald-600
  static const Color statusSuccessBg = Color(0xFFECFDF5); // Emerald-50
  static const Color statusSuccessBorder = Color(0xFFA7F3D0); // Emerald-200
  static const Color statusSuccessText = Color(0xFF065F46); // Emerald-800

  static const Color statusError = Color(0xFFDC2626);     // Red-600
  static const Color statusErrorBg = Color(0xFFFEF2F2);   // Red-50
  static const Color statusErrorText = Color(0xFF991B1B); // Red-800

  static const Color statusWarning = Color(0xFFD97706);   // Amber-600
  static const Color statusInfo = Color(0xFF0284C7);      // Sky-600

  // Surveyor Watermark Tokens
  static const Color stampBg = Color(0xFFFFFFFF);
  static const Color stampRedTime = Color(0xFFDC2626);   // Red Monospace Clock
  static const Color stampBorder = Color(0xFFE5E7EB);
}
