import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// dart:ui removed — BackdropFilter replaced with lightweight frosted glass
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../utils/guest_guard.dart';
import '../widgets/compare_picker_sheet.dart';
import 'filter_screen.dart';
import '../providers/grant_predictor_provider.dart';
import 'grant_wizard_screen.dart';
import 'university_list_screen.dart';
import '../widgets/deadline_banner.dart';
import 'roi_screen.dart';
import 'career_test_hub_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  bool get wantKeepAlive => true; // ⚡ Preserve state across tab switches

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    // ⚡ Stop controller after animation completes to free the Ticker
    _controller.forward().then((_) => _controller.stop());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    // Add haptic feedback for premium feel
    HapticFeedback.lightImpact();
    // Simulate network delay or refresh actual providers
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      ref.invalidate(untScoreProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // ⚡ Required by AutomaticKeepAliveClientMixin
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _handleRefresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              _buildAppBar(theme, isDark),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          _buildGreetingSubtitle(l10n, theme, isDark),
                          const SizedBox(height: 16),
                          const DeadlineBanner(),
                          const SizedBox(height: 16),
                          _buildWizardLauncher(context, isDark, l10n),
                          const SizedBox(height: 24),
                          Text(
                            l10n?.homeTools ?? 'Инструменты',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildToolsRow(context, l10n, isDark),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(ThemeData theme, bool isDark) {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      expandedHeight: 120,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.school_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              AppLocalizations.of(context)?.appTitle ?? 'TANDAU',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolsRow(
    BuildContext context,
    AppLocalizations? l10n,
    bool isDark,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(
        right: 24,
      ), // Extra padding for the last item
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: _buildActionCard(
              context,
              title: l10n?.comparisonTitle ?? 'Сравнение',
              subtitle: l10n?.navComparison ?? 'Университеты',
              icon: Icons.compare_arrows_rounded,
              color: const Color(0xFF10B981),
              isDark: isDark,
              onTap: () {
                if (GuestGuard.check(context)) {
                  showComparePickerSheet(context);
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 160,
            child: _buildActionCard(
              context,
              title: l10n?.homeAdvancedFilter ?? 'Умный фильтр',
              subtitle: l10n?.filterTitle ?? 'Фильтры',
              icon: Icons.tune_rounded,
              color: const Color(0xFFF59E0B),
              isDark: isDark,
              onTap: () {
                if (GuestGuard.check(context)) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FilterScreen()),
                  );
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 160,
            child: _buildActionCard(
              context,
              title: l10n?.homeUniversitySearch ?? 'Поиск ВУЗов',
              subtitle: l10n?.homeUniversities ?? 'Каталог',
              icon: Icons.search_rounded,
              color: const Color(0xFF6366F1),
              isDark: isDark,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const UniversityListScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 160,
            child: _buildActionCard(
              context,
              title: 'Окупаемость',
              subtitle: 'Анализ ROI',
              icon: Icons.trending_up_rounded,
              color: const Color(0xFF3B82F6),
              isDark: isDark,
              onTap: () {
                if (GuestGuard.check(context)) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RoiScreen()),
                  );
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 160,
            child: _buildActionCard(
              context,
              title: 'Профориентация',
              subtitle: 'Тесты RIASEC',
              icon: Icons.psychology_rounded,
              color: const Color(0xFFE91E63),
              isDark: isDark,
              onTap: () {
                if (GuestGuard.check(context)) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CareerTestHubScreen()),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingSubtitle(
    AppLocalizations? l10n,
    ThemeData theme,
    bool isDark,
  ) {
    // ⚡ Removed StreamBuilder — greeting is computed once per build,
    // not via a periodic timer that caused unnecessary 60s rebuilds.
    final hour = DateTime.now().hour;
    String greeting;
    if (hour >= 5 && hour < 12) {
      greeting = l10n?.homeGreetingMorning ?? 'Доброе утро';
    } else if (hour >= 12 && hour < 17) {
      greeting = l10n?.homeGreetingAfternoon ?? 'Добрый день';
    } else if (hour >= 17 && hour < 23) {
      greeting = l10n?.homeGreetingEvening ?? 'Добрый вечер';
    } else {
      greeting = l10n?.homeGreetingNight ?? 'Доброй ночи';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark ? Colors.white60 : Colors.black54,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n?.homeSubtitle ?? 'Найди свой путь в будущее',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
            height: 1.1,
            letterSpacing: -0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildWizardLauncher(BuildContext context, bool isDark, AppLocalizations? l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1.5)
            : Border.all(color: AppColors.border.withValues(alpha: 0.5), width: 1.5),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.pie_chart_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.detailChances ?? 'Оценить шансы',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Точный расчет шансов', // Compact description
                      style: TextStyle(
                        color: isDark ? Colors.white60 : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (GuestGuard.check(context)) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GrantWizardScreen()),
                  );
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Начать расчет',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
          width: 1.5,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isDark ? Colors.white54 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
