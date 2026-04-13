import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF38BDF8); // Electric Cyan
  static const Color secondary = Color(0xFF6366F1); // Indigo
  static const Color gold = Color(0xFFF59E0B); // Amber 500
  static const Color accent = gold;

  // Design Tokens (Light) — улучшенный контраст
  static const Color background = Color(0xFFEFF3F8); // чуть серее фон
  static const Color surface = Color(0xFFFFFFFF);    // белые карточки
  static const Color surfaceElevated = Color(0xFFF8FAFC); // для вложенных поверхностей
  static const Color textPrimary = Color(0xFF0F172A); // почти чёрный
  static const Color textSecondary = Color(0xFF475569);
  static const Color textHint = Color(0xFF94A3B8);
  static const Color border = Color(0xFFCDD5E0); // заметная граница

  // Design Tokens (Dark Premium - Deep Blue-Black)
  static const Color backgroundDark = Color(0xFF020617); // Slate 950
  static const Color surfaceDark = Color(0xFF0F172A); // Slate 900
  static const Color cardDark = Color(0xFF1E293B); // Slate 800
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);

  // Premium Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF60A5FA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Fixed Invalid Static Constants
  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0x1AFFFFFF), Color(0x33FFFFFF)], // Used HEX for const colors
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
