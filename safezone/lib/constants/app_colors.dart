import 'package:flutter/material.dart';

/// AppColors defines the central palette and color constants used throughout SafeZone
class AppColors {
  AppColors._();

  // Primary Branding
  static const Color primary = Color(0xFF2563EB); // Vibrant Safe Blue
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFFEFF6FF); // Soft blue tint
  static const Color primaryBorder = Color(0xFFDBEAFE);

  // Emergency / SOS / Danger
  static const Color danger = Color(0xFFEF4444); // Bright emergency red
  static const Color dangerDark = Color(0xFFDC2626);
  static const Color dangerLight = Color(0xFFFEE2E2);
  static const Color dangerBorder = Color(0xFFFECACA);

  // Success / Verified Safe
  static const Color success = Color(0xFF10B981); // Emerald green
  static const Color successDark = Color(0xFF059669);
  static const Color successLight = Color(0xFFD1FAE5);

  // Warning / Urgency / Hazards
  static const Color warning = Color(0xFFF59E0B); // Amber / orange
  static const Color warningDark = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFEF3C7);

  // Neutral / Grayscale / Slates
  static const Color background = Color(0xFFF8FAFC); // Main scaffold background
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textDark = Color(0xFF1E293B); // Slate 800
  static const Color textBody = Color(0xFF334155); // Slate 700
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400
  static const Color border = Color(0xFFE2E8F0); // Slate 200
  static const Color borderDark = Color(0xFFCBD5E1); // Slate 300
  static const Color divider = Color(0xFFF1F5F9); // Slate 100
  static const Color inputFill = Color(0xFFF8FAFC);

  // Feature & Brand Accent Colors
  static const Color purple = Color(0xFF8B5CF6);
  static const Color purpleLight = Color(0xFFF5F3FF);
  static const Color orange = Color(0xFFF97316);
  static const Color orangeLight = Color(0xFFFFF7ED);
  static const Color googleRed = Color(0xFFEA4335);
}
