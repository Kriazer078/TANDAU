import 'dart:io';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/update_bottom_sheet.dart';

/// 🔄 Manages app update checking via Firebase Remote Config.
///
/// Features:
/// - Force update (blocks app) vs recommended update (dismissible)
/// - "What's New" changelog per locale
/// - "Remind later" — skips showing for 24 hours on recommended updates
class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  // SharedPreferences keys for "remind later" logic
  static const String _dismissedVersionKey = 'update_dismissed_version';
  static const String _dismissedTimeKey = 'update_dismissed_time';
  static const Duration _remindInterval = Duration(hours: 24);

  /// Initialize Remote Config with defaults and fetch latest values.
  Future<void> init() async {
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );

      await _remoteConfig.setDefaults({
        'force_update_current_version': '1.0.0',
        'min_supported_version': '1.0.0',
        'store_url_android':
            'https://play.google.com/store/apps/details?id=com.project.tandau',
        'store_url_ios': 'https://apps.apple.com/app/id123456789',
        'whats_new_ru': '',
        'whats_new_kk': '',
        'whats_new_en': '',
      });

      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      debugPrint('UpdateService: Error initializing Remote Config: $e');
    }
  }

  /// Check for available updates and show the update bottom sheet if needed.
  Future<void> checkForUpdate(BuildContext context) async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;

      final String latestVersion = _remoteConfig.getString(
        'force_update_current_version',
      );
      final String minSupportedVersion = _remoteConfig.getString(
        'min_supported_version',
      );

      // 1. If current < min_supported → FORCE (cannot dismiss)
      bool isForceUpdate = _isVersionLower(currentVersion, minSupportedVersion);

      // 2. If current < latest → RECOMMENDED (can dismiss)
      bool isRecommendedUpdate = _isVersionLower(
        currentVersion,
        latestVersion,
      );

      if (isForceUpdate) {
        if (context.mounted) {
          _showUpdateSheet(
            context,
            forceUpdate: true,
            newVersion: latestVersion,
          );
        }
      } else if (isRecommendedUpdate) {
        // Check "remind later" — skip if dismissed recently
        final bool shouldSkip = await _shouldSkipReminder(latestVersion);
        if (shouldSkip) {
          debugPrint(
            'UpdateService: Recommended update dismissed recently, skipping.',
          );
          return;
        }

        if (context.mounted) {
          _showUpdateSheet(
            context,
            forceUpdate: false,
            newVersion: latestVersion,
          );
        }
      }
    } catch (e) {
      debugPrint('UpdateService: Error checking for update: $e');
    }
  }

  /// Show the premium update bottom sheet
  void _showUpdateSheet(
    BuildContext context, {
    required bool forceUpdate,
    required String newVersion,
  }) {
    final String storeUrl = Platform.isAndroid
        ? _remoteConfig.getString('store_url_android')
        : _remoteConfig.getString('store_url_ios');

    if (storeUrl.isEmpty) {
      debugPrint('UpdateService: Store URL is empty, skipping.');
      return;
    }

    // Get localized changelog
    final String whatsNew = _getWhatsNew(context);

    showModalBottomSheet(
      context: context,
      isDismissible: !forceUpdate,
      enableDrag: !forceUpdate,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) => UpdateBottomSheet(
        isForceUpdate: forceUpdate,
        storeUrl: storeUrl,
        newVersion: newVersion,
        whatsNew: whatsNew,
      ),
    ).then((_) {
      // Dismissed (only possible for recommended updates)
      if (!forceUpdate) {
        _saveDismissedVersion(newVersion);
      }
    });
  }

  /// Get changelog text for the current locale.
  String _getWhatsNew(BuildContext context) {
    final Locale locale =
        Localizations.localeOf(context);
    final String langCode = locale.languageCode;

    // Try locale-specific first, then fallback to Russian
    String whatsNew = _remoteConfig.getString('whats_new_$langCode');
    if (whatsNew.isEmpty && langCode != 'ru') {
      whatsNew = _remoteConfig.getString('whats_new_ru');
    }
    return whatsNew;
  }

  // ─── "Remind Later" Logic ─────────────────────────────────────────

  /// Returns true if we should skip showing the update reminder.
  Future<bool> _shouldSkipReminder(String latestVersion) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? dismissedVersion = prefs.getString(_dismissedVersionKey);
      final int? dismissedTime = prefs.getInt(_dismissedTimeKey);

      if (dismissedVersion == null || dismissedTime == null) return false;

      // Different version — always show
      if (dismissedVersion != latestVersion) return false;

      // Same version — check if 24 hours have passed
      final DateTime dismissedAt =
          DateTime.fromMillisecondsSinceEpoch(dismissedTime);
      final Duration elapsed = DateTime.now().difference(dismissedAt);

      return elapsed < _remindInterval;
    } catch (e) {
      debugPrint('UpdateService: Error reading dismiss state: $e');
      return false;
    }
  }

  /// Save that user dismissed the update for this version.
  Future<void> _saveDismissedVersion(String version) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_dismissedVersionKey, version);
      await prefs.setInt(
        _dismissedTimeKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('UpdateService: Error saving dismiss state: $e');
    }
  }

  // ─── Version Comparison ───────────────────────────────────────────

  /// Returns true if [current] is lower than [target].
  bool _isVersionLower(String current, String target) {
    try {
      final RegExp versionRegExp = RegExp(r'^(\d+)\.(\d+)\.(\d+)');

      final Match? currentMatch = versionRegExp.firstMatch(current);
      final Match? targetMatch = versionRegExp.firstMatch(target);

      if (currentMatch == null || targetMatch == null) {
        debugPrint(
          'UpdateService: Could not parse versions: "$current" or "$target"',
        );
        return false;
      }

      List<int> currentParts = [
        int.parse(currentMatch.group(1)!),
        int.parse(currentMatch.group(2)!),
        int.parse(currentMatch.group(3)!),
      ];

      List<int> targetParts = [
        int.parse(targetMatch.group(1)!),
        int.parse(targetMatch.group(2)!),
        int.parse(targetMatch.group(3)!),
      ];

      for (int i = 0; i < 3; i++) {
        int c = currentParts[i];
        int t = targetParts[i];
        if (c < t) return true;
        if (c > t) return false;
      }
    } catch (e) {
      debugPrint('UpdateService: Error parsing versions: $e');
    }
    return false;
  }
}
