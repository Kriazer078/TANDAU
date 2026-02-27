import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatService {
  static final RevenueCatService _instance = RevenueCatService._internal();
  factory RevenueCatService() => _instance;
  RevenueCatService._internal();

  // 🔐 API ключи загружаются через --dart-define (не хардкодим в коде!)
  // Запуск: flutter run --dart-define=REVENUECAT_GOOGLE_KEY=goog_xxx
  // Сборка: flutter build apk --dart-define=REVENUECAT_GOOGLE_KEY=goog_xxx
  static const String _googleApiKey = String.fromEnvironment(
    'REVENUECAT_GOOGLE_KEY',
  );

  // Ключ для iOS (App Store) — передавать через --dart-define=REVENUECAT_APPLE_KEY=appl_xxx
  static const String _appleApiKey = String.fromEnvironment(
    'REVENUECAT_APPLE_KEY',
  );

  Future<void> init() async {
    // RevenueCat не работает в Web (только iOS и Android)
    if (kIsWeb) return;

    if (_googleApiKey.isEmpty && _appleApiKey.isEmpty) {
      debugPrint(
        '⚠️ RevenueCat: API ключи не указаны. '
        'Используйте --dart-define=REVENUECAT_GOOGLE_KEY=goog_xxx при сборке.',
      );
      return;
    }

    try {
      // SECURITY: Only enable verbose logs in debug mode
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.error);

      PurchasesConfiguration? configuration;

      if (Platform.isAndroid &&
          _googleApiKey.isNotEmpty &&
          !_googleApiKey.startsWith('test_')) {
        configuration = PurchasesConfiguration(_googleApiKey);
      } else if (Platform.isIOS &&
          _appleApiKey.isNotEmpty &&
          !_appleApiKey.startsWith('test_')) {
        configuration = PurchasesConfiguration(_appleApiKey);
      }

      if (configuration != null) {
        await Purchases.configure(configuration);
      }
    } catch (e) {
      debugPrint('⚠️ RevenueCat configure error: $e');
    }
  }

  // Получить доступные пакеты (цены и варианты подписки)
  Future<List<Package>> getOfferings() async {
    try {
      if (kIsWeb) return [];

      final offerings = await Purchases.getOfferings();
      if (offerings.current != null) {
        return offerings.current!.availablePackages;
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching offerings: $e');
      return [];
    }
  }

  // Сделать покупку
  Future<bool> makePurchase(Package package) async {
    try {
      if (kIsWeb) return false;

      // ignore: deprecated_member_use
      final result = await Purchases.purchasePackage(package);
      final customerInfo = result.customerInfo;

      // В твоем скриншоте Entitlement (уровень доступа) назывался "TANDAU Pro"
      final isPro =
          customerInfo.entitlements.all['TANDAU Pro']?.isActive ?? false;

      return isPro;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        debugPrint('Error purchasing package: $e');
      }
      return false;
    } catch (e) {
      debugPrint('Error purchasing package: $e');
      return false;
    }
  }
}
