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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Pre-load Google Fonts before building any widget
  await AppTheme.preloadFonts();

  await ThemeManager().init();
  await LocaleManager().init();
  await AuthService().init();
  await NotificationService().init();
  AIConsultantService().init(); // Fire-and-forget warm-up

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
