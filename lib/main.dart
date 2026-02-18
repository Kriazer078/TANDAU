import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'theme/theme_manager.dart';

import 'screens/splash_screen.dart';
import 'services/locale_manager.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
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

  // System UI overlay will be set dynamically per-screen via AnnotatedRegion
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  runApp(const TandauApp());
}

class TandauApp extends StatelessWidget {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  const TandauApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Pass navigator key to notification service
    NotificationService().setNavigatorKey(navigatorKey);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager().themeMode,
      builder: (context, themeMode, child) {
        return ValueListenableBuilder<Locale?>(
          valueListenable: LocaleManager().locale,
          builder: (context, locale, child) {
            return MaterialApp(
              navigatorKey: navigatorKey,
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
