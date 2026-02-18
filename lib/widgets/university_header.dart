import 'package:flutter/material.dart';
import '../../models/university.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

class UniversityHeader extends StatelessWidget {
  final University university;

  const UniversityHeader({super.key, required this.university});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // City Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  university.city,
                  style: GoogleFonts.outfit(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // University Name
          Text(
            university.name,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 20),

          // High-End Info Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                _buildModernChip(
                  context,
                  Icons.people_alt_rounded,
                  AppLocalizations.of(
                        context,
                      )?.universityStudentCount(university.studentCount) ??
                      '${university.studentCount} абитуриентов',
                  AppColors.primary,
                ),
                const SizedBox(width: 12),
                if (university.hasDormitory)
                  _buildModernChip(
                    context,
                    Icons.bedtime_rounded,
                    AppLocalizations.of(context)?.universityDormitory ??
                        'Общежитие',
                    const Color(0xFF10B981), // Emerald 500
                  ),
                const SizedBox(width: 12),
                if (university.hasGrants)
                  _buildModernChip(
                    context,
                    Icons.auto_awesome_rounded,
                    AppLocalizations.of(context)?.universityGrant ?? 'Гранты',
                    AppColors.gold,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernChip(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : AppColors.border.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
