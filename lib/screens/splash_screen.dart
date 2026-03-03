import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tandau/services/update_service.dart'; // Import UpdateService
import 'legal/terms_screen.dart';
import '../../screens/main_navigation_screen.dart';
import 'banned_screen.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'onboarding_screen.dart';
// permission_handler — deferred to first use (camera/gallery)

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            Brightness.dark, // Dark icons for white background
      ),
    );

    // Initialize Remote Config settings
    UpdateService().init();

    // Navigate based on auth state after some time
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // ⚡ Minimal delay — just prevent flashing if auth resolves instantly
    await Future.delayed(const Duration(milliseconds: 100));

    if (mounted) {
      // Check for updates BEFORE navigating anywhere else
      // await UpdateService().checkForUpdate(context);
      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();
      final bool termsAccepted = prefs.getBool('terms_accepted') ?? false;
      final bool onboardingDone = prefs.getBool('onboarding_done') ?? false;
      final bool loggedIn = AuthService().isLoggedIn.value;

      // 🚫 Check if user was banned during session restore
      final String? banReason = AuthService().bannedReason.value;

      if (mounted) {
        if (banReason != null) {
          // User is banned — show ban screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => BannedScreen(reason: banReason),
            ),
          );
        } else if (loggedIn) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const MainNavigationScreen(),
            ),
          );
        } else if (!onboardingDone && !termsAccepted) {
          // 🎉 First launch — show beautiful onboarding
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          );
        } else if (!termsAccepted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const TermsScreen()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const RegisterScreen()),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Image.asset(
              'assets/images/icon.jpg',
              width: 120,
              height: 120,
              cacheWidth: 360, // 120 * 3 for retina
              cacheHeight: 360,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 32),
            // Loading Indicator
            const CircularProgressIndicator(color: Colors.black),
          ],
        ),
      ),
    );
  }
}
