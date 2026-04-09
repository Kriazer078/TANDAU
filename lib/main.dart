import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'theme/theme_manager.dart';

import 'screens/splash_screen.dart';
import 'screens/banned_screen.dart';
import 'screens/main_navigation_screen.dart';
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
import 'utils/data_migration_helper.dart';

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
      child: Builder(builder: (context) {
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
      }),
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

  // 🔄 Auto-migrate local data to Firestore if empty
  DataMigrationHelper().migrateUniversitiesToFirestore().then((success) {
    if (success) DataMigrationHelper().syncMetadata();
  });

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

    // Listen for login state changes globally to fix session restoral glitches
    AuthService().isLoggedIn.addListener(_onLoginStateChanged);
  }

  @override
  void dispose() {
    AuthService().bannedReason.removeListener(_onBanStateChanged);
    AuthService().isLoggedIn.removeListener(_onLoginStateChanged);
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

  void _onLoginStateChanged() {
    final bool loggedIn = AuthService().isLoggedIn.value;
    final String? reason = AuthService().bannedReason.value;

    if (reason != null) return; // Handled by _onBanStateChanged

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final NavigatorState? navigator = TandauApp.navigatorKey.currentState;
      if (navigator != null) {
        if (loggedIn) {
          navigator.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
            (route) => false,
          );
        } else {
          navigator.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const SplashScreen()),
            (route) => false,
          );
        }
      }
    });
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
              builder: (context, child) {
                if (kIsWeb && child != null) {
                  final mediaQueryData = MediaQuery.of(context);
                  final screenWidth = mediaQueryData.size.width;
                  final screenHeight = mediaQueryData.size.height;

                  const double maxWidth = 430.0;
                  const double maxHeight = 932.0;

                  final bool constrainWidth = screenWidth > maxWidth;

                  final bool showBezel = constrainWidth;

                  return Container(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1E1E1E)
                        : const Color(0xFFF5F5F7), // Apple-like light gray
                    alignment: Alignment.center,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight > maxHeight + 48 ? 24.0 : 0.0,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: maxWidth,
                          maxHeight: maxHeight,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius:
                                BorderRadius.circular(showBezel ? 42.0 : 0.0),
                            boxShadow: showBezel
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 30,
                                      offset: const Offset(0, 10),
                                    )
                                  ]
                                : null,
                            border: showBezel
                                ? Border.all(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? const Color(0xFF333333)
                                        : const Color(0xFFE0E0E0),
                                    width: 8,
                                  )
                                : null,
                          ),
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(showBezel ? 34.0 : 0.0),
                            child:
                                LayoutBuilder(builder: (context, constraints) {
                              return MediaQuery(
                                data: mediaQueryData.copyWith(
                                  size: Size(constraints.maxWidth,
                                      constraints.maxHeight),
                                  padding: showBezel
                                      ? EdgeInsets.zero
                                      : mediaQueryData.padding,
                                ),
                                child: child,
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return child ?? const SizedBox.shrink();
              },
              home: const SplashScreen(),
            );
          },
        );
      },
    );
  }
}
