import 'package:flutter/material.dart';
import '../models/university.dart';
import '../services/comparison_service.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';

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
    _loadComparison();
  }

  Future<void> _loadComparison() async {
    setState(() => _isLoading = true);
    final universities = await _comparisonService.getComparisonUniversities();
    setState(() {
      _universities = universities;
      _isLoading = false;
    });
  }

  Future<void> _removeUniversity(String universityId) async {
    await _comparisonService.removeFromComparison(universityId);
    await _loadComparison();
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)?.comparisonClear ?? 'Clear All',
        ),
        content: Text(
          AppLocalizations.of(context)?.comparisonClearConfirm ??
              'Remove all universities from comparison?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(AppLocalizations.of(context)?.delete ?? 'Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _comparisonService.clearComparison();
      await _loadComparison();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n?.comparisonTitle ?? 'Compare Universities'),
        actions: [
          if (_universities.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearAll,
              tooltip: l10n?.comparisonClear ?? 'Clear All',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _universities.isEmpty
          ? _buildEmptyState(l10n, isDark)
          : _buildComparisonContent(isDark, l10n),
    );
  }

  Widget _buildEmptyState(AppLocalizations? l10n, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.compare_arrows,
              size: 80,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              l10n?.comparisonEmpty ?? 'No universities to compare',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[300] : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l10n?.comparisonEmptyHint ??
                  'Add universities from the list to start comparing',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[500] : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: Text(l10n?.backToList ?? 'Back to List'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonContent(bool isDark, AppLocalizations? l10n) {
    if (_universities.length == 1) {
      return _buildSingleUniversity(isDark, l10n);
    }
    return _buildTwoUniversities(isDark, l10n);
  }

  Widget _buildSingleUniversity(bool isDark, AppLocalizations? l10n) {
    final university = _universities.first;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildUniversityCard(university, isDark, l10n),
            const SizedBox(height: 24),
            Text(
              l10n?.comparisonAddMore ?? 'Add one more university to compare',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[500] : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.add),
              label: Text(l10n?.comparisonAddUniversity ?? 'Add University'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTwoUniversities(bool isDark, AppLocalizations? l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Заголовок
          Text(
            l10n?.comparisonComparing ?? 'Comparing 2 Universities',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Карточки университетов
          _buildUniversityCard(_universities[0], isDark, l10n),

          const SizedBox(height: 16),

          // Разделитель "VS"
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'VS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          _buildUniversityCard(_universities[1], isDark, l10n),
        ],
      ),
    );
  }

  Widget _buildUniversityCard(
    University university,
    bool isDark,
    AppLocalizations? l10n,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок с кнопкой удаления
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // Лого
                if (university.logoUrl.isNotEmpty)
                  Container(
                    width: 50,
                    height: 50,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      university.logoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.school, color: AppColors.primary),
                    ),
                  ),

                // Название
                Expanded(
                  child: Text(
                    university.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),

                // Кнопка удаления
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: AppColors.error,
                  onPressed: () => _removeUniversity(university.id),
                  tooltip: l10n?.delete ?? 'Remove',
                ),
              ],
            ),
          ),

          // Детали
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  Icons.location_city,
                  l10n?.city ?? 'City',
                  university.city,
                  isDark,
                ),
                const Divider(height: 24),

                _buildInfoRow(
                  Icons.attach_money,
                  l10n?.tuition ?? 'Tuition',
                  university.tuitionRange,
                  isDark,
                ),
                const Divider(height: 24),

                _buildInfoRow(
                  Icons.card_giftcard,
                  l10n?.grants ?? 'Grants',
                  university.hasGrants
                      ? (l10n?.available ?? 'Available')
                      : (l10n?.notAvailable ?? 'Not Available'),
                  isDark,
                  valueColor: university.hasGrants
                      ? AppColors.success
                      : AppColors.error,
                ),
                const Divider(height: 24),

                _buildInfoRow(
                  Icons.star,
                  l10n?.rating ?? 'Rating',
                  '${university.rating} / 5.0',
                  isDark,
                  valueColor: _getRatingColor(university.rating),
                ),
                const Divider(height: 24),

                // Специальности
                _buildSpecialtiesSection(university, isDark, l10n),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    bool isDark, {
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color:
                      valueColor ??
                      (isDark ? Colors.white : AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialtiesSection(
    University university,
    bool isDark,
    AppLocalizations? l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.school, size: 20, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(
              l10n?.specialties ?? 'Specialties',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: university.majors.take(5).map((major) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                major,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white : AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
        if (university.majors.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '+${university.majors.length - 5} ${l10n?.more ?? 'more'}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[500] : AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.5) return AppColors.success;
    if (rating >= 3.5) return AppColors.warning;
    return AppColors.error;
  }
}
