import 'package:flutter/material.dart';
import '../../models/university.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

class UniversityHeader extends StatelessWidget {
  final University university;

  const UniversityHeader({super.key, required this.university});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            university.name,
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_on,
                size: 20,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  university.city,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quick Info
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip(
                context,
                Icons.people,
                AppLocalizations.of(
                      context,
                    )?.universityStudentCount(university.studentCount) ??
                    '${university.studentCount} students',
              ),
              if (university.hasDormitory)
                _buildInfoChip(
                  context,
                  Icons.home,
                  AppLocalizations.of(context)?.universityDormitory ??
                      'Dormitory',
                ),
              if (university.hasGrants)
                _buildInfoChip(
                  context,
                  Icons.card_giftcard,
                  AppLocalizations.of(context)?.universityGrant ?? 'Grant',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest
            : AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isDark ? theme.colorScheme.primary : AppColors.primary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? theme.colorScheme.onSurface
                  : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
