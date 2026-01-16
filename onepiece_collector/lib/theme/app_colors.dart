import 'package:flutter/material.dart';

/// App color palette following brand guidelines
/// Reference: brand_guidelines.md
class AppColors {
  // Primary colors
  static const Color darkBlue = Color(0xFF0F172A);
  static const Color cyan = Color(0xFF38BDF8);
  static const Color purple = Color(0xFF7C3AED);
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  // Gradient for backgrounds and cards
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [darkBlue, Color(0xFF1E293B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [cyan, purple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Glassmorphism colors
  static Color glassWhite = white.withOpacity(0.1);
  static Color glassBorder = white.withOpacity(0.2);

  // Text colors
  static const Color textPrimary = white;
  static const Color textSecondary = Color(0xFFCBD5E1);
  static const Color textMuted = Color(0xFF94A3B8);

  // Status colors
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFEF4444);
}
