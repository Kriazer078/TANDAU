import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../models/dashboard_stats.dart';
import '../../providers/dashboard_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final dateRange = ref.watch(dashboardDateRangeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return statsAsync.when(
      data: (stats) =>
          _DashboardContent(stats: stats, dateRange: dateRange, isDark: isDark),
      loading: () => _ShimmerLoading(isDark: isDark),
      error: (err, _) => _ErrorView(error: err.toString(), ref: ref),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  MAIN CONTENT
// ═══════════════════════════════════════════════════════════════════════════
class _DashboardContent extends ConsumerWidget {
  final List<DashboardStats> stats;
  final DateTimeRange dateRange;
  final bool isDark;

  const _DashboardContent({
    required this.stats,
    required this.dateRange,
    required this.isDark,
  });

  int get _totalUsers => stats.fold(0, (s, e) => s + e.newUsers);
  int get _totalReviews => stats.fold(0, (s, e) => s + e.newReviews);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bg = isDark ? AppColors.backgroundDark : AppColors.background;

    return Container(
      color: bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──
            _buildHeader(context, ref),
            const SizedBox(height: 24),
            // ── KPI Cards ──
            _buildKpiRow(context),
            const SizedBox(height: 24),
            // ── Realtime Section ──
            const _RealtimeSection(),
            const SizedBox(height: 24),
            // ── Charts row ──
            _buildChartsRow(context),
            const SizedBox(height: 24),
            // ── Bottom row: activity list ──
            _buildActivitySection(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final fmt = DateFormat('d MMM yyyy');
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : AppColors.border;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Добро пожаловать 👋',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Вот что происходит в системе сегодня',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        // Date range picker button
        Consumer(
          builder: (ctx, r, _) {
            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                final picked = await showDateRangePicker(
                  context: ctx,
                  firstDate: DateTime(2024),
                  lastDate: DateTime.now(),
                  initialDateRange: dateRange,
                  builder: (context, child) => Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: AppColors.primary,
                      ),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) {
                  r
                      .read(dashboardDateRangeProvider.notifier)
                      .updateRange(picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${fmt.format(dateRange.start)} – ${fmt.format(dateRange.end)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: isDark ? Colors.white38 : AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ─── KPI Row ─────────────────────────────────────────────────────────────
  Widget _buildKpiRow(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final cols = constraints.maxWidth > 900
            ? 4
            : constraints.maxWidth > 600
            ? 2
            : 1;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _kpi(
              context,
              label: 'Новые пользователи',
              value: _totalUsers.toString(),
              sub: 'За выбранный период',
              gradient: AppColors.primaryGradient,
              icon: Icons.person_add_rounded,
              trend: '+12%',
              trendUp: true,
              width: (constraints.maxWidth - (cols - 1) * 16) / cols,
            ),
            _kpi(
              context,
              label: 'Новые отзывы',
              value: _totalReviews.toString(),
              sub: 'За выбранный период',
              gradient: AppColors.blueGradient,
              icon: Icons.rate_review_rounded,
              trend: '+5%',
              trendUp: true,
              width: (constraints.maxWidth - (cols - 1) * 16) / cols,
            ),
            _kpi(
              context,
              label: 'Активность',
              value: '${stats.length} дн.',
              sub: 'Дней за период',
              gradient: AppColors.greenGradient,
              icon: Icons.trending_up_rounded,
              trend: 'Стабильно',
              trendUp: true,
              width: (constraints.maxWidth - (cols - 1) * 16) / cols,
            ),
            _kpi(
              context,
              label: 'Ср. пользователей/день',
              value: stats.isNotEmpty
                  ? (_totalUsers / stats.length).toStringAsFixed(1)
                  : '0',
              sub: 'Среднесуточный показатель',
              gradient: AppColors.orangeGradient,
              icon: Icons.analytics_rounded,
              trend: 'В среднем',
              trendUp: null,
              width: (constraints.maxWidth - (cols - 1) * 16) / cols,
            ),
          ],
        );
      },
    );
  }

  Widget _kpi(
    BuildContext context, {
    required String label,
    required String value,
    required String sub,
    required LinearGradient gradient,
    required IconData icon,
    required String trend,
    required bool? trendUp,
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Icon box with gradient
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.colors.first.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                // Trend badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: trendUp == null
                        ? (isDark ? Colors.white10 : Colors.grey.shade100)
                        : trendUp
                        ? AppColors.success.withValues(alpha: 0.12)
                        : AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (trendUp != null)
                        Icon(
                          trendUp
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          size: 11,
                          color: trendUp ? AppColors.success : AppColors.error,
                        ),
                      if (trendUp != null) const SizedBox(width: 3),
                      Text(
                        trend,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: trendUp == null
                              ? (isDark
                                    ? Colors.white54
                                    : AppColors.textSecondary)
                              : trendUp
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Charts Row ──────────────────────────────────────────────────────────
  Widget _buildChartsRow(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isWide = constraints.maxWidth > 800;
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _userGrowthCard(context)),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: _reviewActivityCard(context)),
            ],
          );
        }
        return Column(
          children: [
            _userGrowthCard(context),
            const SizedBox(height: 16),
            _reviewActivityCard(context),
          ],
        );
      },
    );
  }

  Widget _userGrowthCard(BuildContext context) {
    return _ChartCard(
      isDark: isDark,
      title: 'Рост пользователей',
      subtitle: 'Новые регистрации за период',
      icon: Icons.show_chart_rounded,
      iconColor: AppColors.primary,
      child: _UserGrowthChart(stats: stats, isDark: isDark),
    );
  }

  Widget _reviewActivityCard(BuildContext context) {
    return _ChartCard(
      isDark: isDark,
      title: 'Активность отзывов',
      subtitle: 'Новые отзывы по дням',
      icon: Icons.bar_chart_rounded,
      iconColor: AppColors.secondary,
      child: _ReviewBarChart(stats: stats, isDark: isDark),
    );
  }

  // ─── Activity Section ────────────────────────────────────────────────────
  Widget _buildActivitySection(BuildContext context) {
    final recentStats = stats.length > 7
        ? stats.sublist(stats.length - 7)
        : stats;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: AppColors.accent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Последняя активность',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Активность за последние 7 дней',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...recentStats.reversed.map((s) => _activityRow(s)),
        ],
      ),
    );
  }

  Widget _activityRow(DashboardStats s) {
    final fmt = DateFormat('d MMM, EEE', 'ru');
    final border = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : AppColors.divider;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              fmt.format(s.date),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
              ),
            ),
          ),
          _statPill(
            Icons.person_add_rounded,
            '${s.newUsers} польз.',
            AppColors.primary,
          ),
          const SizedBox(width: 8),
          _statPill(
            Icons.rate_review_rounded,
            '${s.newReviews} отзывов',
            AppColors.secondary,
          ),
        ],
      ),
    );
  }

  Widget _statPill(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  REALTIME SECTION
// ═══════════════════════════════════════════════════════════════════════════
class _RealtimeSection extends ConsumerWidget {
  const _RealtimeSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCountAsync = ref.watch(activeUsersStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Pulse Indicator
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success,
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.6),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'В реальном времени',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Пользователи, активные за последние 15 минут',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          activeCountAsync.when(
            data: (count) => Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppColors.success,
                    height: 1,
                  ),
                ),
                Text(
                  'онлайн сейчас',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            loading: () => const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(),
            ),
            error: (err, _) => const Icon(Icons.error_outline, color: AppColors.error),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  CHART CARD
// ═══════════════════════════════════════════════════════════════════════════
class _ChartCard extends StatelessWidget {
  final bool isDark;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _ChartCard({
    required this.isDark,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(height: 220, child: child),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  USER GROWTH CHART
// ═══════════════════════════════════════════════════════════════════════════
class _UserGrowthChart extends StatelessWidget {
  final List<DashboardStats> stats;
  final bool isDark;

  const _UserGrowthChart({required this.stats, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return Center(
        child: Text(
          'Нет данных',
          style: TextStyle(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondary,
          ),
        ),
      );
    }

    double maxY = stats
        .map((s) => s.newUsers.toDouble())
        .fold(0, (a, b) => a > b ? a : b);
    if (maxY == 0) maxY = 5;

    final gridColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.grey.withValues(alpha: 0.15);
    final labelColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY > 5 ? maxY / 4 : 1,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: gridColor, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (val, _) {
                final i = val.toInt();
                if (i < 0 || i >= stats.length) return const SizedBox();
                if (stats.length > 7 && i % (stats.length ~/ 5) != 0) {
                  return const SizedBox();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat('MM/dd').format(stats[i].date),
                    style: TextStyle(fontSize: 10, color: labelColor),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: maxY > 5 ? maxY / 4 : 1,
              getTitlesWidget: (val, _) {
                if (val == 0) return const SizedBox();
                return Text(
                  val.toInt().toString(),
                  style: TextStyle(fontSize: 10, color: labelColor),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: maxY * 1.25,
        lineBarsData: [
          LineChartBarData(
            spots: stats.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value.newUsers.toDouble());
            }).toList(),
            isCurved: true,
            curveSmoothness: 0.3,
            color: AppColors.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                    radius: 4,
                    color: AppColors.primary,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.25),
                  AppColors.primary.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  REVIEW BAR CHART
// ═══════════════════════════════════════════════════════════════════════════
class _ReviewBarChart extends StatelessWidget {
  final List<DashboardStats> stats;
  final bool isDark;

  const _ReviewBarChart({required this.stats, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return Center(
        child: Text(
          'Нет данных',
          style: TextStyle(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondary,
          ),
        ),
      );
    }

    double maxY = stats
        .map((s) => s.newReviews.toDouble())
        .fold(0, (a, b) => a > b ? a : b);
    if (maxY == 0) maxY = 5;

    final gridColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.grey.withValues(alpha: 0.15);
    final labelColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY > 5 ? maxY / 4 : 1,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: gridColor, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (val, _) {
                final i = val.toInt();
                if (i < 0 || i >= stats.length) return const SizedBox();
                if (stats.length > 7 && i % (stats.length ~/ 5) != 0) {
                  return const SizedBox();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat('dd').format(stats[i].date),
                    style: TextStyle(fontSize: 10, color: labelColor),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: maxY > 5 ? maxY / 4 : 1,
              getTitlesWidget: (val, _) {
                if (val == 0) return const SizedBox();
                return Text(
                  val.toInt().toString(),
                  style: TextStyle(fontSize: 10, color: labelColor),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        maxY: maxY * 1.25,
        barGroups: stats.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.newReviews.toDouble(),
                gradient: LinearGradient(
                  colors: [AppColors.secondary, AppColors.primary],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: stats.length > 20 ? 6 : 14,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY * 1.25,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.grey.withValues(alpha: 0.08),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  SHIMMER LOADING
// ═══════════════════════════════════════════════════════════════════════════
class _ShimmerLoading extends StatelessWidget {
  final bool isDark;

  const _ShimmerLoading({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final base = isDark ? const Color(0xFF1C1C4A) : Colors.grey.shade200;
    final highlight = isDark ? const Color(0xFF2A2A6A) : Colors.grey.shade100;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _shimmerBox(height: 42, width: 280),
            const SizedBox(height: 24),
            Row(
              children: List.generate(
                4,
                (i) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 3 ? 16 : 0),
                    child: _shimmerBox(height: 140),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(flex: 3, child: _shimmerBox(height: 280)),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: _shimmerBox(height: 280)),
              ],
            ),
            const SizedBox(height: 24),
            _shimmerBox(height: 200),
          ],
        ),
      ),
    );
  }

  Widget _shimmerBox({required double height, double? width}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  ERROR VIEW
// ═══════════════════════════════════════════════════════════════════════════
class _ErrorView extends StatelessWidget {
  final String error;
  final WidgetRef ref;

  const _ErrorView({required this.error, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ошибка загрузки',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.refresh(dashboardStatsProvider),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Попробовать снова'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
