import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager {
  // Singleton instance
  static final ThemeManager _instance = ThemeManager._internal();
  factory ThemeManager() => _instance;
  ThemeManager._internal();

  // ValueNotifier to listen to theme changes
  // ⚡ Default to system theme for all new users
  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);

  // Key for storing theme preference (null means system)
  static const String _themeKey = 'theme_mode_v2'; // Changed key to reset for old users too

  /// Initialize and load saved theme preference
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    // Default to system for users who haven't set a preference
    final themeString = prefs.getString(_themeKey);
    if (themeString == 'dark') {
      themeMode.value = ThemeMode.dark;
    } else if (themeString == 'light') {
      themeMode.value = ThemeMode.light;
    } else {
      themeMode.value = ThemeMode.system;
    }
  }

  /// Toggle between light and dark themes (overrides system)
  Future<void> toggleTheme(bool isDark) async {
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, isDark ? 'dark' : 'light');
  }
  
  /// Reset to system theme
  Future<void> setSystemTheme() async {
    themeMode.value = ThemeMode.system;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_themeKey);
  }

  /// Get current brightness (helper) - will always return true/false based on explicit setting,
  /// but UI should rely on `Theme.of(context).brightness`
  bool get isDarkMode => themeMode.value == ThemeMode.dark;
}
