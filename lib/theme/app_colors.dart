import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors - Modern Slate & Sky Palette
  static const Color primary = Color(0xFF38BDF8); // Electric Cyan (Sky 400)
  static const Color primaryLight = Color(0xFF7DD3FC); // Sky 300
  static const Color primaryDark = Color(0xFF0284C7); // Sky 600

  static const Color secondary = Color(0xFF818CF8); // Indigo 400
  static const Color accent = Color(0xFFF59E0B); // Amber 500 (Gold)

  // Neutral Surface Colors (Light Mode)
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Colors.white;
  static const Color card = Colors.white;

  // Neutral Surface Colors (Dark Mode)
  static const Color backgroundDark = Color(
    0xFF020617,
  ); // Slate 950 (Deep Navy)
  static const Color surfaceDark = Color(0xFF0F172A); // Slate 900
  static const Color cardDark = Color(0xFF1E293B); // Slate 800

  // Semantic Colors
  static const Color success = Color(0xFF22C55E); // Green 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color error = Color(0xFFEF4444); // Red 500

  // Text Colors
  static const Color textPrimary = Color(0xFF1E293B); // Slate 800
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textHint = Color(0xFF94A3B8); // Slate 400

  // Borders & Accents
  static const Color border = Color(0xFFE2E8F0); // Slate 200
  static const Color divider = Color(0xFFF1F5F9); // Slate 100

  // Legacy Mappings (to avoid breaking existing code)
  static const Color gold = accent;
  static const Color primaryGradientStart = primary;
  static const Color primaryGradientEnd = Color(0xFF818CF8);

  // Premium Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF818CF8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF020617)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient glassGradient = LinearGradient(
    colors: [
      Colors.white.withValues(alpha: 0.1),
      Colors.white.withValues(alpha: 0.02),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
