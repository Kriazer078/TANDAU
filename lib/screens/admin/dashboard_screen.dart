import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart'; // Make sure this package is added
import '../../providers/dashboard_provider.dart';
import '../../models/dashboard_stats.dart';
import '../../theme/app_colors.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  // We no longer need local state for loading/error/stats since Riverpod handles it

  @override
  void initState() {
    super.initState();
    // Use Future.microtask to avoid build phase issues if needed,
    // but AsyncNotifierProvider auto-inits on watch/read.
    // We can explicitly refresh if we want fresh data on every open.
    // ref.refresh(dashboardStatsProvider);
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final dateRange = ref.watch(dashboardDateRangeProvider);

    final textColor = _isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics Dashboard'),
        centerTitle: true,
        backgroundColor: _isDark
            ? AppColors.backgroundDark
            : AppColors.background,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(dashboardStatsProvider.notifier).refresh(),
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      backgroundColor: _isDark
          ? AppColors.backgroundDark
          : AppColors.background,
      body: statsAsync.when(
        data: (stats) => _buildContent(stats, dateRange, textColor),
        loading: () => _buildShimmerLoading(),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  'Error loading statistics:\n$err',
                  style: TextStyle(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () =>
                      ref.read(dashboardStatsProvider.notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    List<DashboardStats> stats,
    DateTimeRange dateRange,
    Color textColor,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateFilter(dateRange, textColor),
          const SizedBox(height: 24),
          _buildSummaryCards(stats),
          const SizedBox(height: 32),
          _buildChartSection(
            title: 'User Growth',
            child: _buildUserGrowthChart(stats),
            textColor: textColor,
          ),
          const SizedBox(height: 32),
          _buildChartSection(
            title: 'Review Activity',
            child: _buildReviewActivityChart(stats),
            textColor: textColor,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    final baseColor = _isDark ? Colors.white10 : Colors.grey[300]!;
    final highlightColor = _isDark ? Colors.white24 : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Filter Shimmer
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 24),
            // Cards Shimmer
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Chart 1 Shimmer
            Container(
              height: 350,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            const SizedBox(height: 32),
            // Chart 2 Shimmer
            Container(
              height: 350,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilter(DateTimeRange dateRange, Color textColor) {
    final dateFormat = DateFormat('MMM d, yyyy');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 20,
                color: _isDark ? Colors.white70 : Colors.grey[700],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${dateFormat.format(dateRange.start)} - ${dateFormat.format(dateRange.end)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2024),
                  lastDate: DateTime.now(),
                  initialDateRange: dateRange,
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: _isDark
                            ? const ColorScheme.dark(
                                primary: AppColors.primary,
                                onPrimary: Colors.white,
                                surface: AppColors.surfaceDark,
                                onSurface: Colors.white,
                              )
                            : const ColorScheme.light(
                                primary: AppColors.primary,
                              ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  ref
                      .read(dashboardDateRangeProvider.notifier)
                      .updateRange(picked);
                  // AsyncNotifier automatically refreshes when dependency changes if valid,
                  // but dashboardStatsProvider depends on ref.watch(dateRangeProvider).
                  // So it should trigger update automatically.
                }
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: _isDark ? Colors.white24 : Colors.grey[300]!,
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Change Range'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(List<DashboardStats> stats) {
    int totalNewUsers = 0;
    int totalNewReviews = 0;

    for (var stat in stats) {
      totalNewUsers += stat.newUsers;
      totalNewReviews += stat.newReviews;
    }

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'New Users',
            totalNewUsers.toString(),
            Icons.person_add,
            Colors.blue,
            _isDark
                ? Colors.blue.withValues(alpha: 0.2)
                : Colors.blue.withValues(alpha: 0.1),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'New Reviews',
            totalNewReviews.toString(),
            Icons.rate_review,
            Colors.orange,
            _isDark
                ? Colors.orange.withValues(alpha: 0.2)
                : Colors.orange.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color iconColor,
    Color bgIconColor,
  ) {
    final cardBg = _isDark ? AppColors.surfaceDark : Colors.white;
    final textColor = _isDark ? Colors.white : AppColors.textPrimary;
    final subTextColor = _isDark ? Colors.white70 : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: _isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgIconColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: subTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection({
    required String title,
    required Widget child,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(height: 250, child: child),
        ],
      ),
    );
  }

  Widget _buildUserGrowthChart(List<DashboardStats> stats) {
    // Determine max Y for scaling
    double maxY = 0;
    for (var s in stats) {
      final val = s.newUsers.toDouble();
      if (val > maxY) maxY = val;
    }
    if (maxY == 0) maxY = 5; // Default scale if empty

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY > 5 ? maxY / 5 : 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: _isDark
                  ? Colors.white10
                  : Colors.grey.withValues(alpha: 0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= stats.length) {
                  return const SizedBox();
                }

                // Show date every few items to avoid clutter
                if (stats.length > 7 && index % (stats.length ~/ 5) != 0) {
                  return const SizedBox();
                }

                final date = stats[index].date;
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    DateFormat('MM/dd').format(date),
                    style: TextStyle(
                      fontSize: 10,
                      color: _isDark ? Colors.white54 : AppColors.textSecondary,
                    ),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxY > 5 ? maxY / 5 : 1,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox(); // Don't show 0
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    fontSize: 10,
                    color: _isDark ? Colors.white54 : AppColors.textSecondary,
                  ),
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
        maxY: maxY * 1.2, // Add some headroom
        lineBarsData: [
          LineChartBarData(
            spots: stats.asMap().entries.map((e) {
              final index = e.key.toDouble();
              final val = e.value.newUsers.toDouble();
              return FlSpot(index, val);
            }).toList(),
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewActivityChart(List<DashboardStats> stats) {
    double maxY = 0;
    for (var s in stats) {
      final val = s.newReviews.toDouble();
      if (val > maxY) maxY = val;
    }
    if (maxY == 0) maxY = 5;

    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY > 5 ? maxY / 5 : 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: _isDark
                  ? Colors.white10
                  : Colors.grey.withValues(alpha: 0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= stats.length) {
                  return const SizedBox();
                }

                if (stats.length > 7 && index % (stats.length ~/ 5) != 0) {
                  return const SizedBox();
                }

                final date = stats[index].date;
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    DateFormat('MM/dd').format(date),
                    style: TextStyle(
                      fontSize: 10,
                      color: _isDark ? Colors.white54 : AppColors.textSecondary,
                    ),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: maxY > 5 ? maxY / 5 : 1,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox();
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    fontSize: 10,
                    color: _isDark ? Colors.white54 : AppColors.textSecondary,
                  ),
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
        maxY: maxY * 1.2,
        barGroups: stats.asMap().entries.map((e) {
          final index = e.key;
          final val = e.value.newReviews.toDouble();
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: val,
                color: Colors.orange,
                width: 12,
                borderRadius: BorderRadius.circular(4),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY * 1.2,
                  color: _isDark
                      ? Colors.white10
                      : Colors.grey.withValues(alpha: 0.1),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
