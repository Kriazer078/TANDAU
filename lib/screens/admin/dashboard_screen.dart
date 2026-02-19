import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/admin_service.dart';
import '../../theme/app_colors.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AdminService _adminService = AdminService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _stats = [];
  String _errorMessage = '';

  // Default range: Last 7 days
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 6));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final stats = await _adminService.getStatistics(
        start: _startDate,
        end: _endDate,
      );

      // Sort by date to ensure charts are correct
      stats.sort(
        (a, b) => (a['date'] as String).compareTo(b['date'] as String),
      );

      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading statistics: $e';
        _isLoading = false;
      });
    }
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
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
            onPressed: _fetchStats,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      backgroundColor: _isDark
          ? AppColors.backgroundDark
          : AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDateFilter(textColor),
                  const SizedBox(height: 24),
                  _buildSummaryCards(),
                  const SizedBox(height: 32),
                  _buildChartSection(
                    title: 'User Growth',
                    child: _buildUserGrowthChart(),
                    textColor: textColor,
                  ),
                  const SizedBox(height: 32),
                  _buildChartSection(
                    title: 'Review Activity',
                    child: _buildReviewActivityChart(),
                    textColor: textColor,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildDateFilter(Color textColor) {
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
                  '${dateFormat.format(_startDate)} - ${dateFormat.format(_endDate)}',
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
                  initialDateRange: DateTimeRange(
                    start: _startDate,
                    end: _endDate,
                  ),
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
                  setState(() {
                    _startDate = picked.start;
                    _endDate = picked.end;
                  });
                  _fetchStats();
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

  Widget _buildSummaryCards() {
    int totalNewUsers = 0;
    int totalNewReviews = 0;

    for (var stat in _stats) {
      totalNewUsers += (stat['new_users'] as int? ?? 0);
      totalNewReviews += (stat['new_reviews'] as int? ?? 0);
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

  Widget _buildUserGrowthChart() {
    // Determine max Y for scaling
    double maxY = 0;
    for (var s in _stats) {
      final val = (s['new_users'] as int? ?? 0).toDouble();
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
                if (index < 0 || index >= _stats.length) {
                  return const SizedBox();
                }

                // Show date every few items to avoid clutter
                if (_stats.length > 7 && index % (_stats.length ~/ 5) != 0) {
                  return const SizedBox();
                }

                final dateStr = _stats[index]['date'] as String;
                final date = DateTime.parse(dateStr);
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
            spots: _stats.asMap().entries.map((e) {
              final index = e.key.toDouble();
              final val = (e.value['new_users'] as int? ?? 0).toDouble();
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

  Widget _buildReviewActivityChart() {
    double maxY = 0;
    for (var s in _stats) {
      final val = (s['new_reviews'] as int? ?? 0).toDouble();
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
                if (index < 0 || index >= _stats.length) {
                  return const SizedBox();
                }

                if (_stats.length > 7 && index % (_stats.length ~/ 5) != 0) {
                  return const SizedBox();
                }

                final dateStr = _stats[index]['date'] as String;
                final date = DateTime.parse(dateStr);
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
        barGroups: _stats.asMap().entries.map((e) {
          final index = e.key;
          final val = (e.value['new_reviews'] as int? ?? 0).toDouble();
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
