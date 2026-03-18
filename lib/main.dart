import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'theme/theme_manager.dart';

import 'screens/splash_screen.dart';
import 'screens/banned_screen.dart';
import 'services/locale_manager.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/ai_consultant_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/revenuecat_service.dart';

import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔇 Disable debugPrint in production
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  // 🛡️ Global Error Handlers (Stability)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('🔴 FlutterError: ${details.exception}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('🔴 PlatformDispatcher Error: $error\n$stack');
    return true; // Prevent app crash
  };

  // 🛡️ Fallback Error Screen (Replaces Red Screen of Death)
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return Container(
            color: Colors.red.shade400,
            padding: const EdgeInsets.all(20),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 48),
                const SizedBox(height: 16),
                Text(
                  l10n?.errorOops ?? 'Упс! Произошла ошибка.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  details.exceptionAsString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }
      ),
    );
  };

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ⚡ PARALLEL: Fonts, Theme, Locale are independent — load together
  await Future.wait([
    AppTheme.preloadFonts(),
    ThemeManager().init(),
    LocaleManager().init(),
  ]);

  // Auth must finish before UI (needed by splash navigation)
  await AuthService().init();

  // ⚡ FIRE-AND-FORGET: These don't block UI rendering
  NotificationService().init();
  try {
    RevenueCatService().init().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        debugPrint('⚠️ RevenueCat init timed out, skipping');
      },
    );
  } catch (e) {
    debugPrint('⚠️ RevenueCat init failed: $e');
  }
  AIConsultantService().init(); // Fire-and-forget warm-up

  // ⚠️ FirestoreUploadScript removed from startup — was causing
  // Firestore contention on every launch, contributing to registration ANR.
  // Run manually from admin panel when needed.

  // System UI overlay will be set dynamically per-screen via AnnotatedRegion
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  runApp(const ProviderScope(child: TandauApp()));
}

class TandauApp extends StatefulWidget {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  const TandauApp({super.key});

  @override
  State<TandauApp> createState() => _TandauAppState();
}

class _TandauAppState extends State<TandauApp> {
  @override
  void initState() {
    super.initState();

    // Pass navigator key to notification service (once, not on every rebuild)
    NotificationService().setNavigatorKey(TandauApp.navigatorKey);

    // Listen for ban events globally — navigate to BannedScreen if banned
    AuthService().bannedReason.addListener(_onBanStateChanged);
  }

  @override
  void dispose() {
    AuthService().bannedReason.removeListener(_onBanStateChanged);
    super.dispose();
  }

  void _onBanStateChanged() {
    final String? reason = AuthService().bannedReason.value;
    if (reason != null) {
      // Use addPostFrameCallback to avoid modifying widget tree during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final NavigatorState? navigator = TandauApp.navigatorKey.currentState;
        if (navigator != null) {
          navigator.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => BannedScreen(reason: reason)),
            (route) => false,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager().themeMode,
      builder: (context, themeMode, child) {
        return ValueListenableBuilder<Locale?>(
          valueListenable: LocaleManager().locale,
          builder: (context, locale, child) {
            return MaterialApp(
              navigatorKey: TandauApp.navigatorKey,
              title: 'TANDAU',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,

              // ⚡ CRITICAL: Disable theme animation to prevent lag
              // Without this, Flutter interpolates ALL colors across
              // ~200ms → causes heavy jank with 4 screens in IndexedStack
              themeAnimationDuration: Duration.zero,

              locale: locale,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('ru'), // Russian (Default)
                Locale('kk'), // Kazakh
                Locale('en'), // English
              ],
              localeResolutionCallback: (deviceLocale, supportedLocales) {
                if (deviceLocale != null) {
                  for (var supportedLocale in supportedLocales) {
                    if (supportedLocale.languageCode ==
                        deviceLocale.languageCode) {
                      return supportedLocale;
                    }
                  }
                }
                return supportedLocales.first;
              },
              home: const SplashScreen(),
            );
          },
        );
      },
    );
  }
}
