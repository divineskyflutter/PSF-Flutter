import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ===========================
  // Primary Theme
  // ===========================

  static const Color primary = Color(0xFF258077);

  static const Color primaryDark = Color(0xFF185A55);

  static const Color primaryLight = Color(0xFF6FB8B1);

  // ===========================
  // Background
  // ===========================

  static const Color background = Color(0xFFF8F6EF);

  static const Color card = Colors.white;

  static const Color border = Color(0xFFE5E7EB);

  // ===========================
  // Text
  // ===========================

  static const Color textPrimary = Color(0xFF222222);

  static const Color textSecondary = Color(0xFF757575);

  // ===========================
  // Language Colors
  // ===========================

  static const Color gujarati = Color(0xFF4F8F21);

  static const Color hindi = Color(0xFFF59E0B);

  static const Color english = Color(0xFF8E1E2D);

  // ===========================
  // Others
  // ===========================

  static const Color white = Colors.white;

  static const Color transparent = Colors.transparent;

  static const Color shadow = Color(0x15000000);

  // ===========================
  // Status / Semantic
  //
  // Shared across Home / Loans / Profile for reminders, dues, progress and
  // destructive actions. (AppDialog / ToastUtil already use these same
  // values as private literals for their own icon/snackbar colors — kept
  // as-is there to avoid touching working shared widgets; these constants
  // are for any new screen that needs the same palette.)
  // ===========================

  static const Color success = Color(0xFF2E9D68);

  static const Color warning = Color(0xFFE7A72E);

  static const Color danger = Color(0xFFD94B4B);

  static const Color info = Color(0xFF3985C6);

  /// Warm gold accent used sparingly next to the teal theme (card trim,
  /// highlights) — not a second brand color.
  static const Color accentGold = Color(0xFFE3C16F);

  // ===========================
  // Header Gradient
  // ===========================

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primaryDark,
      primary,
      primaryLight,
    ],
  );

  // ===========================
  // Button Gradient
  // ===========================

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      primaryDark,
      primary,
    ],
  );
}