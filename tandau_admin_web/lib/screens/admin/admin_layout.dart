import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';


// Screens
import 'dashboard_screen.dart';
import 'user_management_screen.dart';
import 'review_moderation_screen.dart';
import 'university_management_screen.dart';
import 'feedback_management_screen.dart';
import 'send_notification_screen.dart';
import 'audit_log_screen.dart';
import 'dart:ui'; // Add at the top for ImageFilter

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  int _selectedIndex = 0;
  bool _isSyncing = false;
  bool _isSidebarExpanded = true;

  List<Widget> get _screens {
    final screens = <Widget>[
      const DashboardScreen(),
    ];
    if (AuthService().isAdmin) {
      screens.add(const UserManagementScreen());
    }
    screens.addAll([
      const ReviewModerationScreen(),
      const UniversityManagementScreen(),
      const FeedbackManagementScreen(),
    ]);
    if (AuthService().isAdmin) {
      screens.addAll([const SendNotificationScreen(), const AuditLogScreen()]);
    }
    return screens;
  }

  List<_NavItem> get _navItems {
    final items = <_NavItem>[
      const _NavItem(
        Icons.dashboard_rounded,
        Icons.dashboard,
        'Дашборд',
        'Обзор системы',
      ),
    ];
    if (AuthService().isAdmin) {
      items.add(
        const _NavItem(
          Icons.people_alt_rounded,
          Icons.people_alt,
          'Пользователи',
          'Управление',
        ),
      );
    }
    items.addAll([
      const _NavItem(Icons.shield_rounded, Icons.shield, 'Модерация', 'Отзывы'),
      const _NavItem(
        Icons.school_rounded,
        Icons.school,
        'ВУЗы',
        'Каталог',
      ),
      const _NavItem(
        Icons.feedback_rounded,
        Icons.feedback,
        'Фидбэк',
        'Обратная связь',
      ),
    ]);
    if (AuthService().isAdmin) {
      items.addAll([
        const _NavItem(
          Icons.campaign_rounded,
          Icons.campaign,
          'Уведомления',
          'Рассылки',
        ),
        const _NavItem(
          Icons.receipt_long_rounded,
          Icons.receipt_long,
          'Логи',
          'Журнал аудита',
        ),
      ]);
    }
    return items;
  }

  Future<void> _handleSync() async {
    setState(() => _isSyncing = true);
    final success = await FirestoreService().syncAggregationMetadata();
    if (mounted) {
      setState(() => _isSyncing = false);
      _showSnack(
        success ? '✓ Синхронизация завершена' : '✗ Ошибка синхронизации',
        success ? AppColors.success : AppColors.error,
      );
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _logout() async {
    await AuthService().logout();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLarge = screenWidth >= 1100;
    final isMedium = screenWidth >= 700;

    // Auto-collapse on small screens
    if (!isMedium && _isSidebarExpanded) {
      _isSidebarExpanded = false;
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Row(
        children: [
          _buildSidebar(isLarge, isMedium),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) =>
                        FadeTransition(opacity: anim, child: child),
                    child: KeyedSubtree(
                      key: ValueKey(_selectedIndex),
                      child: _screens[_selectedIndex],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(bool isLarge, bool isMedium) {
    final expanded = _isSidebarExpanded && isMedium;
    final sidebarWidth = expanded ? 260.0 : 70.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: sidebarWidth,
      decoration: const BoxDecoration(
        gradient: AppColors.sidebarGradient,
        boxShadow: [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 20,
            offset: Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Brand ──
          _buildSidebarBrand(expanded),
          const SizedBox(height: 8),
          // ── Nav Items ──
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              itemCount: _navItems.length,
              itemBuilder: (context, index) => _buildNavItem(index, expanded),
            ),
          ),
          // ── Bottom ──
          _buildSidebarBottom(expanded),
        ],
      ),
    );
  }

  Widget _buildSidebarBrand(bool expanded) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // Logo icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.space_dashboard_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          if (expanded) ...[
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TANDAU',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Admin Portal',
                    style: TextStyle(
                      color: AppColors.sidebarSubtext,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, bool expanded) {
    final item = _navItems[index];
    final isSelected = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _selectedIndex = index),
          hoverColor: AppColors.sidebarHover.withValues(alpha: 0.5),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: expanded ? 12 : 14,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isSelected
                  ? AppColors.sidebarSelected.withValues(alpha: 0.9)
                  : Colors.transparent,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? item.selectedIcon : item.icon,
                  color: isSelected
                      ? Colors.white
                      : AppColors.sidebarText.withValues(alpha: 0.7),
                  size: 20,
                ),
                if (expanded) ...[
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.sidebarText.withValues(alpha: 0.9),
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.7)
                              : AppColors.sidebarSubtext,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarBottom(bool expanded) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppColors.blueGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 18),
          ),
          if (expanded) ...[
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AuthService().currentUser.value?.name ?? 'Admin',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    AuthService().isAdmin ? 'Администратор' : 'Модератор',
                    style: const TextStyle(
                      color: AppColors.sidebarSubtext,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.logout_rounded,
                size: 18,
                color: AppColors.sidebarSubtext,
              ),
              onPressed: _logout,
              tooltip: 'Выйти',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    final titles = <String>['Дашборд'];
    if (AuthService().isAdmin) titles.add('Пользователи');
    titles.addAll(['Модерация', 'ВУЗы', 'Фидбэк']);
    if (AuthService().isAdmin) {
      titles.addAll(['Уведомления', 'Журнал аудита']);
    }

    final isAdmin = AuthService().isAdmin;
    final roleLabel = isAdmin ? 'Admin' : 'Модератор';

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.surfaceDark.withValues(alpha: 0.7),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            // Sidebar toggle
            IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () =>
                  setState(() => _isSidebarExpanded = !_isSidebarExpanded),
              color: Colors.white60,
              tooltip: 'Свернуть меню',
            ),
            const SizedBox(width: 8),
            // Breadcrumb
            Text(
              'TANDAU Admin',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 13,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('/', style: TextStyle(color: Colors.grey)),
            ),
            Text(
              titles[_selectedIndex],
              style: TextStyle(
                color: AppColors.textPrimaryDark,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            // Sync button — allow for admin and moderator
            if (AuthService().hasAdminAccess) ...[
              _isSyncing
                  ? Container(
                      width: 36,
                      height: 36,
                      padding: const EdgeInsets.all(8),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    )
                  : _topBarIconButton(
                      icon: Icons.sync_rounded,
                      tooltip: 'Синхронизация БД',
                      onTap: _handleSync,
                    ),
              const SizedBox(width: 4),
            ],
            const SizedBox(width: 8),
            // Avatar with logout popup
            PopupMenuButton<String>(
              tooltip: 'Аккаунт',
              offset: const Offset(0, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: AppColors.surfaceDark,
              onSelected: (v) {
                if (v == 'logout') _logout();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          color: AppColors.error,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Выйти',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      roleLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white70,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
        ),
      ),
    );
  }

  Widget _topBarIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white.withValues(alpha: 0.06),
              border: Border.all(
                color: Colors.white12,
              ),
            ),
            child: Icon(
              icon,
              size: 18,
              color: Colors.white60,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Data class ─────────────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String subtitle;

  const _NavItem(this.icon, this.selectedIcon, this.label, this.subtitle);
}
