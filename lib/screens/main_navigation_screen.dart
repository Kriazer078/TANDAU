import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../widgets/ai_logo_icon.dart';
import '../screens/home_screen.dart';
import '../screens/search_screen.dart';
import '../screens/ai_consultant_screen.dart';
import '../screens/profile_screen.dart';
import '../utils/guest_guard.dart'; // ⭐ Import GuestGuard
import '../widgets/like_review_widgets.dart'; // ⚡ For preloading likes
import '../services/update_service.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // ⚡ Lazy-load tabs — only build a tab widget the first time it's visited
  final Map<int, Widget> _tabCache = {};

  @override
  void initState() {
    super.initState();
    // ⚡ Pre-load all liked IDs once instead of per-card reads
    LikeButton.preloadLikes();
    // ⚡ Pre-cache home tab so it renders immediately
    _getPage(0);

    // ⚡ Check for updates when the main screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        UpdateService().checkForUpdate(context);
      }
    });
  }

  /// Build and cache tab widget on first access
  Widget _getPage(int index) {
    return _tabCache.putIfAbsent(index, () {
      switch (index) {
        case 0:
          return const HomeScreen();
        case 1:
          return const SearchScreen();
        case 2:
          return const AIConsultantScreen();
        case 3:
          return const ProfileScreen();
        default:
          return const HomeScreen();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // ⚡ Build only visited pages for IndexedStack, wrap in RepaintBoundary
    final List<Widget> pages = List.generate(4, (i) {
      if (_tabCache.containsKey(i)) {
        return RepaintBoundary(child: _getPage(i));
      }
      return const SizedBox.shrink(); // Placeholder until visited
    });

    return Scaffold(
      // ⚡ IndexedStack only paints the active child,
      // skips layout for inactive children — much faster than Stack+Offstage
      body: IndexedStack(index: _currentIndex, children: pages),
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
              _getPage(index); // ⚡ Ensure page is cached on first visit
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
