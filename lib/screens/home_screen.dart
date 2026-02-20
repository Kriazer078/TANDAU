import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../utils/guest_guard.dart';
import '../widgets/compare_picker_sheet.dart';
import '../widgets/premium_button.dart';
import 'filter_screen.dart';
import '../providers/grant_predictor_provider.dart';
import 'grant_prediction_results_screen.dart';
import 'university_list_screen.dart';
import '../widgets/premium_background.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
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

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final untScore = ref.watch(untScoreProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: Stack(
          children: [
            // Premium Design Background
            Positioned.fill(child: PremiumBackground(isDark: isDark)),

            // Background Blobs Decor
            Positioned(
              top: -50,
              left: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
              ),
            ),

            // Main Content
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
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
                            const SizedBox(height: 24),
                            _buildScoreInput(untScore, isDark, l10n),
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
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(ThemeData theme, bool isDark) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FilterScreen()),
                );
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
        ],
      ),
    );
  }

  Widget _buildGreetingSubtitle(
    AppLocalizations? l10n,
    ThemeData theme,
    bool isDark,
  ) {
    final hour = DateTime.now().hour;
    final greeting = (hour < 12)
        ? (l10n?.homeGreetingMorning ?? 'Доброе утро')
        : (hour < 18)
        ? (l10n?.homeGreetingAfternoon ?? 'Добрый день')
        : (l10n?.homeGreetingEvening ?? 'Добрый вечер');

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

  Widget _buildScoreInput(int untScore, bool isDark, AppLocalizations? l10n) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ваш балл ЕНТ:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      letterSpacing: 0.3,
                    ),
                  ),
                  Container(
                    width: 70,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E40AF).withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '$untScore',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF60A5FA),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: const Color(0xFF38BDF8),
                  inactiveTrackColor: isDark ? Colors.white12 : Colors.black12,
                  thumbColor: const Color(0xFF38BDF8),
                  overlayColor: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                  trackHeight: 4.0,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 10,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 20,
                  ),
                ),
                child: Slider(
                  value: untScore.toDouble(),
                  min: 0,
                  max: 140,
                  divisions: 140,
                  onChanged: (value) {
                    ref.read(untScoreProvider.notifier).state = value.toInt();
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        PremiumButton(
          text: l10n?.detailChances ?? 'Оценить шансы',
          icon: Icons.auto_awesome,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    GrantPredictionResultsScreen(entScore: untScore),
              ),
            );
          },
        ),
      ],
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
                        color: isDark
                            ? Colors.white54
                            : AppColors.textSecondary,
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
