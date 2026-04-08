import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager {
  // Singleton instance
  static final ThemeManager _instance = ThemeManager._internal();
  factory ThemeManager() => _instance;
  ThemeManager._internal();

  // ValueNotifier to listen to theme changes
  // ⚡ Default to dark theme for all new users
  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.dark);

  // Key for storing theme preference
  static const String _themeKey = 'theme_mode';

  /// Initialize and load saved theme preference
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    // Default to true (dark) for new users who haven't set a preference
    final isDark = prefs.getBool(_themeKey) ?? true;
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  /// Toggle between light and dark themes
  Future<void> toggleTheme(bool isDark) async {
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
  }

  /// Get current brightness (helper)
  bool get isDarkMode => themeMode.value == ThemeMode.dark;
}
