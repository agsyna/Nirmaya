import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary palette
  static const Color primary = Color(0xFF5B2E5A);
  static const Color primaryDark = Color(0xFF4A1F40);
  static const Color primaryLight = Color(0xFF6A2C5B);
  static const Color primarySurface = Color(0xFFF3E5F5);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6A2C5B), Color(0xFF4A1F40)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Background
  static const Color background = Color(0xFFF5F5F7);
  static const Color surface = Colors.white;
  static const Color cardBackground = Color(0xFFF7F7F7);

  // Text
  static const Color textPrimary = Color(0xFF2C2C2C);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Colors.white;

  // Status
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFFE6EEDC);
  static const Color warning = Color(0xFFFFA726);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color error = Color(0xFFEF5350);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF42A5F5);
  static const Color infoLight = Color(0xFFE3F2FD);

  // Misc
  static const Color divider = Color(0xFFE0E0E0);
  static const Color shadow = Color(0x14000000);
  static const Color shimmer = Color(0xFFE0E0E0);

  // Medication types
  static const Color medicationPill = Color(0xFFE8D5B7);
  static const Color medicationCapsule = Color(0xFFB7D5E8);
  static const Color medicationSyrup = Color(0xFFD5E8B7);
  static const Color medicationInjection = Color(0xFFE8B7D5);
}
