import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../widgets/ai_logo_icon.dart';
import '../screens/home_screen.dart';
import '../screens/search_screen.dart';
import '../screens/ai_consultant_screen.dart';
import '../screens/profile_screen.dart';
import '../utils/guest_guard.dart'; // ⭐ Import GuestGuard
import '../widgets/like_review_widgets.dart'; // ⚡ For preloading likes

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // ⚡ Track which tabs have been visited for lazy loading
  final Set<int> _visitedTabs = {0}; // Home is visited by default

  @override
  void initState() {
    super.initState();
    // ⚡ Pre-load all liked IDs once instead of per-card reads
    LikeButton.preloadLikes();
  }

  void setIndex(int index) {
    setState(() {
      _currentIndex = index;
      _visitedTabs.add(index);
    });
  }

  /// Build a tab only if it has been visited; otherwise show empty
  Widget _buildTab(int index, Widget child) {
    if (!_visitedTabs.contains(index)) {
      return const SizedBox.shrink();
    }
    return Offstage(
      offstage: _currentIndex != index,
      child: TickerMode(enabled: _currentIndex == index, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildTab(0, const HomeScreen()),
          _buildTab(1, const SearchScreen()),
          _buildTab(2, const AIConsultantScreen()),
          _buildTab(3, const ProfileScreen()),
        ],
      ),
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
              _visitedTabs.add(index);
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
              icon: const Opacity(opacity: 0.6, child: AILogoIcon(size: 24)),
              selectedIcon: const AILogoIcon(size: 24),
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
