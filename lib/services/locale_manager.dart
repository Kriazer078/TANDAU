import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleManager {
  // Singleton instance
  static final LocaleManager _instance = LocaleManager._internal();
  factory LocaleManager() => _instance;
  LocaleManager._internal();

  // ValueNotifier to listen to locale changes (nullable for system default)
  final ValueNotifier<Locale?> locale = ValueNotifier<Locale?>(null);

  // Key for storing locale preference
  static const String _localeKey = 'app_locale';

  /// Initialize and load saved locale preference
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLocale = prefs.getString(_localeKey);
      if (savedLocale != null) {
        locale.value = Locale(savedLocale);
      }
      // If no saved locale, keep it null so MaterialApp uses system locale
    } catch (e) {
      debugPrint('Error initializing locale: $e');
    }
  }

  /// Set the locale
  Future<void> setLocale(String languageCode) async {
    locale.value = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, languageCode);
  }
}
