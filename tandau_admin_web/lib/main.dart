import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'services/locale_manager.dart';
import 'services/auth_service.dart';
import 'screens/admin/admin_layout.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await AuthService().init();
  await LocaleManager().init();

  runApp(const ProviderScope(child: AdminWebApp()));
}

class AdminWebApp extends StatelessWidget {
  const AdminWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TANDAU Admin',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: ValueListenableBuilder<bool>(
        valueListenable: AuthService().isLoggedIn,
        builder: (context, isLoggedIn, _) {
          return isLoggedIn ? const AdminLayout() : const LoginScreen();
        },
      ),
    );
  }
}
