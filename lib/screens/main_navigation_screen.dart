import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../screens/home_screen.dart';
import '../screens/search_screen.dart';
import '../screens/ai_consultant_screen.dart';
import '../screens/profile_screen.dart';
import '../utils/guest_guard.dart'; // ⭐ Import GuestGuard

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void setIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  final List<Widget> _screens = const [
    HomeScreen(),
    SearchScreen(),
    AIConsultantScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.06)
                  : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            // Guest access: Allow Home (0), Search (1), Profile (3).
            // Block AI Agent (2).
            if (index == 2) {
              if (!GuestGuard.check(context)) return;
            }

            setState(() {
              _currentIndex = index;
            });
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: AppLocalizations.of(context)?.navHome ?? 'Home',
            ),
            NavigationDestination(
              icon: const Icon(Icons.search),
              selectedIcon: const Icon(Icons.search),
              label: AppLocalizations.of(context)?.navSearch ?? 'Search',
            ),
            NavigationDestination(
              icon: const Icon(Icons.smart_toy_outlined),
              selectedIcon: const Icon(Icons.smart_toy),
              label: AppLocalizations.of(context)?.navAgent ?? 'AI',
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: AppLocalizations.of(context)?.navProfile ?? 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
