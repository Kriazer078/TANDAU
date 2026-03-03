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
            // Two university header card placeholders
            Row(
              children: List.generate(
                2,
                (_) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Container(
                      height: 200,
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
              6,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  height: 52,
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // University header cards
          _buildUniversityHeaders(isDark),
          const SizedBox(height: 20),
          // Comparison table
          _buildComparisonTable(l10n, isDark),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // UNIVERSITY HEADER CARDS
  // ═══════════════════════════════════════════
  Widget _buildUniversityHeaders(bool isDark) {
    final List<Widget> children = [];
    for (int i = 0; i < _universities.length; i++) {
      if (i > 0) {
        children.add(const SizedBox(width: 12));
      }
      children.add(
        Expanded(child: _buildUniversityCard(_universities[i], isDark)),
      );
    }
    return Row(children: children);
  }

  Widget _buildUniversityCard(University uni, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
        border: Border.all(color: isDark ? Colors.white10 : AppColors.border),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              // Logo
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                clipBehavior: Clip.antiAlias,
                child: uni.logoUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: uni.logoUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Icon(
                          Icons.school_rounded,
                          color: AppColors.primary,
                          size: 28,
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.school_rounded,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      )
                    : const Icon(
                        Icons.school_rounded,
                        color: AppColors.primary,
                        size: 28,
                      ),
              ),
              const SizedBox(height: 12),
              // Name
              Text(
                uni.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              // City
              Text(
                uni.city,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Positioned(
            top: -12,
            right: -12,
            child: IconButton(
              onPressed: () async {
                await _comparisonService.removeFromComparison(uni.id);
                // Reload or navigate back if less than 2
                _loadUniversities();
                final count = await _comparisonService.getComparisonCount();
                if (count < 2 && mounted) {
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.cancel, color: Colors.grey),
              tooltip: 'Удалить из сравнения',
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // COMPARISON TABLE
  // ═══════════════════════════════════════════
  Widget _buildComparisonTable(AppLocalizations? l10n, bool isDark) {
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
      ),
      _ComparisonRow(
        icon: Icons.score_rounded,
        label: l10n?.comparisonParamPassingScore ?? 'Passing Score',
        values: _universities.map((u) => u.passingScore.toString()).toList(),
      ),
      _ComparisonRow(
        icon: Icons.star_rounded,
        label: l10n?.comparisonParamRating ?? 'Rating',
        values: _universities.map((u) => u.rating.toStringAsFixed(1)).toList(),
        highlightBetter: true,
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
        icon: Icons.people_rounded,
        label: l10n?.comparisonParamStudents ?? 'Students',
        values:
            _universities.map((u) => _formatNumber(u.studentCount)).toList(),
      ),
      _ComparisonRow(
        icon: Icons.menu_book_rounded,
        label: l10n?.comparisonParamSpecialties ?? 'Specialties',
        values: _universities.map((u) => u.majors.take(3).join(', ')).toList(),
        isMultiLine: true,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
        border: Border.all(color: isDark ? Colors.white10 : AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : AppColors.primary.withValues(alpha: 0.05),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.analytics_rounded,
                  size: 18,
                  color: isDark ? Colors.white70 : AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n?.comparisonParameters ?? 'Parameters',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          // Rows
          ...rows.asMap().entries.map((entry) {
            final int index = entry.key;
            final _ComparisonRow row = entry.value;
            final bool isEven = index.isEven;

            return _buildTableRow(row, isDark, isEven);
          }),
        ],
      ),
    );
  }

  Widget _buildTableRow(_ComparisonRow row, bool isDark, bool isEven) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isEven
            ? (isDark
                ? Colors.white.withValues(alpha: 0.02)
                : Colors.grey.withValues(alpha: 0.03))
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white10 : AppColors.border,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label row
          Row(
            children: [
              Icon(
                row.icon,
                size: 16,
                color: isDark ? Colors.white54 : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  row.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white54 : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Values row
          Row(
            children: row.values.asMap().entries.map((entry) {
              final int i = entry.key;
              final dynamic val = entry.value;

              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: i < row.values.length - 1 ? 6 : 0,
                    left: i > 0 ? 6 : 0,
                  ),
                  child: row.isBool
                      ? _buildBoolValue(val as bool, isDark)
                      : Text(
                          val.toString(),
                          textAlign: TextAlign.center,
                          maxLines: row.isMultiLine ? 3 : 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark ? Colors.white : AppColors.textPrimary,
                            height: row.isMultiLine ? 1.4 : 1.2,
                          ),
                        ),
                ),
              );
            }).toList(),
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
  final bool isMultiLine;
  final bool highlightBetter;

  const _ComparisonRow({
    required this.icon,
    required this.label,
    required this.values,
    this.isBool = false,
    this.isMultiLine = false,
    this.highlightBetter = false,
  });
}
