import 'dart:io';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tandau/widgets/update_dialog.dart';

class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  Future<void> init() async {
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: const Duration(hours: 1), // Check every hour
        ),
      );

      // Defaults
      await _remoteConfig.setDefaults({
        'force_update_current_version': '1.0.0',
        'min_supported_version': '1.0.0',
        'store_url_android':
            'https://play.google.com/store/apps/details?id=com.project.tandau',
        'store_url_ios': 'https://apps.apple.com/app/id123456789',
      });

      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      debugPrint('UpdateService: Error initializing Remote Config: $e');
    }
  }

  Future<void> checkForUpdate(BuildContext context) async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;

      final String forceUpdateVersion = _remoteConfig.getString(
        'force_update_current_version',
      );
      final String minSupportedVersion = _remoteConfig.getString(
        'min_supported_version',
      );

      // Check for FORCE update separate from recommended update
      // Logic:
      // 1. If current < min_supported -> FORCE
      // 2. If current < force_update_current (which might be "latest") -> RECOMMEND

      // Correction: usually 'min_supported' means "if you are below this, you MUST update".
      // 'latest_version' means "if you are below this, you SHOULD update".
      // Let's stick to the plan variables but interpret them clearly.

      bool isForceUpdate = _isVersionLower(currentVersion, minSupportedVersion);
      bool isRecommendedUpdate = _isVersionLower(
        currentVersion,
        forceUpdateVersion,
      );

      if (isForceUpdate) {
        if (context.mounted) {
          _showUpdateDialog(context, forceUpdate: true);
        }
      } else if (isRecommendedUpdate) {
        if (context.mounted) {
          _showUpdateDialog(context, forceUpdate: false);
        }
      }
    } catch (e) {
      debugPrint('UpdateService: Error checking for update: $e');
    }
  }

  void _showUpdateDialog(BuildContext context, {required bool forceUpdate}) {
    final String storeUrl = Platform.isAndroid
        ? _remoteConfig.getString('store_url_android')
        : _remoteConfig.getString('store_url_ios');

    if (storeUrl.isEmpty) {
      debugPrint('UpdateService: Shop URL is empty, skipping update dialog.');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (context) =>
          UpdateDialog(isForceUpdate: forceUpdate, storeUrl: storeUrl),
    );
  }

  /// Returns true if [current] is lower than [target]
  bool _isVersionLower(String current, String target) {
    try {
      // Extract generic version pattern x.y.z from strings like "1.0.0+1" or "2.1.0-beta"
      final RegExp versionRegExp = RegExp(r'^(\d+)\.(\d+)\.(\d+)');

      final Match? currentMatch = versionRegExp.firstMatch(current);
      final Match? targetMatch = versionRegExp.firstMatch(target);

      if (currentMatch == null || targetMatch == null) {
        debugPrint(
          'UpdateService: Could not parse version strings: "$current" or "$target"',
        );
        return false;
      }

      // Parse the matched groups
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
