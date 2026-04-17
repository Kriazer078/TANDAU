import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../models/university.dart';
import '../services/comparison_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

class ComparisonScreen extends StatefulWidget {
  const ComparisonScreen({super.key});

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  final ComparisonService _comparisonService = ComparisonService();
  List<University> _universities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUniversities();
  }

  Future<void> _loadUniversities() async {
    try {
      final universities = await _comparisonService.getComparisonUniversities();
      if (mounted) {
        setState(() {
          _universities = universities;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _clearComparison() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.comparisonClearTitle ?? 'Clear comparison?'),
        content: Text(
          l10n?.comparisonClearMessage ??
              'All universities will be removed from comparison',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n?.comparisonClear ?? 'Clear',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _comparisonService.clearComparison();
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.comparisonTitle ?? 'University Comparison'),
        actions: [
          if (_universities.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: l10n?.comparisonClear ?? 'Clear',
              onPressed: _clearComparison,
            ),
        ],
      ),
      body: _isLoading
          ? _buildShimmerLoading(isDark)
          : _universities.isEmpty
              ? _buildEmptyState(l10n, isDark)
              : _buildComparisonContent(l10n, isDark),
    );
  }

  // ═══════════════════════════════════════════
  // SHIMMER SKELETON
  // ═══════════════════════════════════════════
  Widget _buildShimmerLoading(bool isDark) {
    final baseColor =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final highlightColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Three university header card placeholders
            Row(
              children: List.generate(
                3,
                (_) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Table row skeletons
            ...List.generate(
              10,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // EMPTY STATE
  // ═══════════════════════════════════════════
  Widget _buildEmptyState(AppLocalizations? l10n, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.compare_arrows_rounded,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n?.comparisonEmpty ?? 'Comparison list is empty',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n?.comparisonEmptyHint ??
                  'Add universities from the list to start comparing',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // COMPARISON CONTENT
  // ═══════════════════════════════════════════
  Widget _buildComparisonContent(AppLocalizations? l10n, bool isDark) {
    // 💡 If we have more than 2 universities, we use horizontal scrolling for the data columns
    final bool useScroll = _universities.length > 2;
    final double columnWidth = useScroll ? 140 : MediaQuery.of(context).size.width * 0.4;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header section with scrolling capability for university cards
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _universities.map((uni) {
                return Container(
                  width: columnWidth,
                  margin: const EdgeInsets.only(right: 12),
                  child: _buildUniversityCard(uni, isDark),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 8),

          // Main Comparison Table
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildComparisonTable(l10n, isDark, columnWidth),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildUniversityCard(University uni, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.border,
          width: 1,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              // Logo
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                clipBehavior: Clip.antiAlias,
                child: uni.logoUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: uni.logoUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const Icon(Icons.school, size: 24, color: AppColors.primary),
                      )
                    : const Icon(Icons.school, size: 24, color: AppColors.primary),
              ),
              const SizedBox(height: 10),
              // Name
              Text(
                uni.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              // City
              Text(
                uni.city,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Positioned(
            top: -8,
            right: -8,
            child: GestureDetector(
              onTap: () async {
                await _comparisonService.removeFromComparison(uni.id);
                _loadUniversities();
                final count = await _comparisonService.getComparisonCount();
                if (count < 2 && mounted) {
                  Navigator.pop(context);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.grey,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable(AppLocalizations? l10n, bool isDark, double columnWidth) {
    // Determine winners for highlighting
    int? tuitionWinner;
    int? ratingWinner;
    int? specialtiesWinner;

    if (_universities.length > 1) {
      // 💰 Tuition winner (Lowest max)
      double minTuition = double.infinity;
      for (int i = 0; i < _universities.length; i++) {
        final val = _universities[i].maxTuitionValue;
        if (val > 0 && val < minTuition) {
          minTuition = val;
          tuitionWinner = i;
        }
      }

      // ⭐ Rating winner (Highest)
      double maxRating = -1;
      for (int i = 0; i < _universities.length; i++) {
        if (_universities[i].rating > maxRating) {
          maxRating = _universities[i].rating;
          ratingWinner = i;
        }
      }

      // 📚 Specialties winner (Most)
      int maxMajors = -1;
      for (int i = 0; i < _universities.length; i++) {
        if (_universities[i].majors.length > maxMajors) {
          maxMajors = _universities[i].majors.length;
          specialtiesWinner = i;
        }
      }
    }

    final List<_ComparisonRow> rows = [
      _ComparisonRow(
        icon: Icons.location_city_rounded,
        label: l10n?.comparisonParamCity ?? 'City',
        values: _universities.map((u) => u.city).toList(),
      ),
      _ComparisonRow(
        icon: Icons.payments_rounded,
        label: l10n?.comparisonParamTuition ?? 'Tuition Cost',
        values: _universities.map((u) => u.tuitionRange).toList(),
        winnerIndex: tuitionWinner,
      ),
      _ComparisonRow(
        icon: Icons.star_rounded,
        label: l10n?.comparisonParamRating ?? 'Rating',
        values: _universities.map((u) => u.rating.toStringAsFixed(1)).toList(),
        winnerIndex: ratingWinner,
      ),
      _ComparisonRow(
        icon: Icons.score_rounded,
        label: l10n?.comparisonParamPassingScore ?? 'Passing Score',
        values: _universities.map((u) => u.passingScore.toString()).toList(),
      ),
      _ComparisonRow(
        icon: Icons.school_rounded,
        label: l10n?.comparisonParamGrants ?? 'Grants/Budget',
        values: _universities.map((u) => u.hasGrants).toList(),
        isBool: true,
      ),
      _ComparisonRow(
        icon: Icons.apartment_rounded,
        label: l10n?.comparisonParamDormitory ?? 'Dormitory',
        values: _universities.map((u) => u.hasDormitory).toList(),
        isBool: true,
      ),
      _ComparisonRow(
        icon: Icons.price_change_rounded,
        label: l10n?.comparisonParamDormPrice ?? 'Dorm Price',
        values: _universities.map((u) => u.dormitoryPrice != null ? '${u.dormitoryPrice} ₸' : '-').toList(),
      ),
      _ComparisonRow(
        icon: Icons.shield_rounded,
        label: l10n?.comparisonParamMilitary ?? 'Military Dept',
        values: _universities.map((u) => u.hasMilitaryDepartment).toList(),
        isBool: true,
      ),
      _ComparisonRow(
        icon: Icons.event_rounded,
        label: l10n?.comparisonParamDeadline ?? 'Deadline',
        values: _universities.map((u) => u.applicationDeadline).toList(),
      ),
      _ComparisonRow(
        icon: Icons.people_rounded,
        label: l10n?.comparisonParamStudents ?? 'Students',
        values: _universities.map((u) => _formatNumber(u.studentCount)).toList(),
      ),
      _ComparisonRow(
        icon: Icons.menu_book_rounded,
        label: l10n?.comparisonParamSpecialties ?? 'Specialties',
        values: _universities.map((u) => u.majors.length.toString()).toList(),
        winnerIndex: specialtiesWinner,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Table Header
          _buildTableHeader(l10n, isDark),
          
          // Rows
          ...rows.asMap().entries.map((entry) {
            return _buildRow(entry.value, isDark, entry.key.isEven, columnWidth);
          }),
        ],
      ),
    );
  }

  Widget _buildTableHeader(AppLocalizations? l10n, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.primary.withValues(alpha: 0.05),
      ),
      child: Row(
        children: [
          const Icon(Icons.analytics_rounded, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            l10n?.comparisonParameters ?? 'Parameters',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(_ComparisonRow row, bool isDark, bool isEven, double columnWidth) {
    return Container(
      decoration: BoxDecoration(
        color: isEven ? (isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.withValues(alpha: 0.02)) : Colors.transparent,
        border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : AppColors.border, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title of parameter
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Icon(row.icon, size: 14, color: AppColors.primary.withValues(alpha: 0.7)),
                const SizedBox(width: 6),
                Text(
                  row.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          // Scrollable values
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: row.values.asMap().entries.map((e) {
                final bool isWinner = e.key == row.winnerIndex;
                return Container(
                  width: columnWidth,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: isWinner 
                      ? Colors.green.withValues(alpha: isDark ? 0.15 : 0.1) 
                      : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.withValues(alpha: 0.05)),
                    borderRadius: BorderRadius.circular(12),
                    border: isWinner ? Border.all(color: Colors.green.withValues(alpha: 0.5)) : null,
                  ),
                  child: row.isBool 
                    ? _buildBoolValue(e.value as bool, isDark)
                    : Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            e.value.toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isWinner ? FontWeight.w800 : FontWeight.bold,
                              color: isWinner ? Colors.green : (isDark ? Colors.white : AppColors.textPrimary),
                            ),
                          ),
                          if (isWinner)
                            const Positioned(
                              right: -4,
                              top: -4,
                              child: Icon(Icons.auto_awesome, size: 10, color: Colors.green),
                            ),
                        ],
                      ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoolValue(bool value, bool isDark) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: value
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                value ? Icons.check_circle_rounded : Icons.cancel_rounded,
                size: 16,
                color: value ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 4),
              Text(
                value ? (l10n?.commonYes ?? 'Yes') : (l10n?.commonNo ?? 'No'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: value ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

// ═══════════════════════════════════════════
// DATA CLASS FOR TABLE ROWS
// ═══════════════════════════════════════════
class _ComparisonRow {
  final IconData icon;
  final String label;
  final List<dynamic> values;
  final bool isBool;
  final int? winnerIndex;

  const _ComparisonRow({
    required this.icon,
    required this.label,
    required this.values,
    this.isBool = false,
    this.winnerIndex,
  });
}
