import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager {
  // Singleton instance
  static final ThemeManager _instance = ThemeManager._internal();
  factory ThemeManager() => _instance;
  ThemeManager._internal();

  // ValueNotifier to listen to theme changes
  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.light);

  // Key for storing theme preference
  static const String _themeKey = 'theme_mode';

  /// Initialize and load saved theme preference
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_themeKey) ?? false;
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
