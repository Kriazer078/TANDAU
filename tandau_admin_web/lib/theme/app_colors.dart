import 'package:flutter/material.dart';

class AppColors {
  // ── Brand (Modern, Premium) ──────────────────────────────────────────────────
  static const Color primary = Color(0xFF3B82F6); // Blue 500
  static const Color primaryLight = Color(0xFF60A5FA); // Blue 400
  static const Color secondary = Color(0xFF8B5CF6); // Violet 500
  static const Color gold = Color(0xFFF59E0B); // Amber 500
  static const Color accent = Color(0xFF10B981); // Emerald 500

  // ── Sidebar ─────────────────────────────────────────────────────────────
  static const Color sidebarBg = Color(0xFF09090B); // Zinc 950
  static const Color sidebarSelected = Color(0xFF27272A); // Zinc 800
  static const Color sidebarHover = Color(0xFF18181B); // Zinc 900
  static const Color sidebarText = Color(0xFFF4F4F5); // Zinc 100
  static const Color sidebarSubtext = Color(0xFFA1A1AA); // Zinc 400

  // ── Light Theme ─────────────────────────────────────────────────────────
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Colors.white;
  static const Color cardBorder = Color(0xFFE2E8F0); // Slate 200
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textHint = Color(0xFF94A3B8); // Slate 400
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);

  // ── Glow & Effects ──────────────────────────────────────────────────────
  static const Color glowPrimary = Color(0x333B82F6); // Soft blue glow
  static const Color glowSecondary = Color(0x338B5CF6); // Soft purple glow
  static const Color glowAccent = Color(0x3310B981); // Soft green glow
  static const Color glassWhite = Color(0x0AFFFFFF); // Barely visible white
  static const Color glassBorder = Color(0x1AFFFFFF); // Subtle white border

  // ── Dark Theme (Premium Dark) ───────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF020817); // Slate 950
  static const Color surfaceDark = Color(0xFF0F172A); // Slate 900
  static const Color cardDark = Color(0xFF1E293B); // Slate 800
  static const Color textPrimaryDark = Color(0xFFF8FAFC); // Slate 50
  static const Color textSecondaryDark = Color(0xFF94A3B8); // Slate 400

  // ── Status ───────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color info = Color(0xFF0EA5E9); // Sky 500

  // ── Chart Colors ─────────────────────────────────────────────────────────
  static const Color chartBlue = Color(0xFF3B82F6);
  static const Color chartGreen = Color(0xFF10B981);
  static const Color chartOrange = Color(0xFFF59E0B);
  static const Color chartRed = Color(0xFFEF4444);
  static const Color chartPurple = Color(0xFF8B5CF6);

  // ── Gradients ────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sidebarGradient = LinearGradient(
    colors: [Color(0xFF020817), Color(0xFF0F172A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient blueGradient = LinearGradient(
    colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF34D399), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFFA78BFA), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0x33FFFFFF), Color(0x0AFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
