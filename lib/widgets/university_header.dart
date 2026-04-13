import 'package:flutter/material.dart';
import '../../models/university.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ai_logo_icon.dart';

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
                  Icon(
                    Icons.people_alt_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
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
                    const Icon(
                      Icons.bedtime_rounded,
                      size: 14,
                      color: Color(0xFF10B981),
                    ),
                    AppLocalizations.of(context)?.universityDormitory ??
                        'Общежитие',
                    const Color(0xFF10B981), // Emerald 500
                  ),
                const SizedBox(width: 12),
                if (university.hasGrants)
                  _buildModernChip(
                    context,
                    const AILogoIcon(size: 14, color: AppColors.gold),
                    AppLocalizations.of(context)?.universityGrant ?? 'Гранты',
                    AppColors.gold,
                  ),
                if (university.hasMilitaryDepartment) ...[
                  const SizedBox(width: 12),
                  _buildModernChip(
                    context,
                    const Icon(
                      Icons.shield_rounded,
                      size: 14,
                      color: Color(0xFF6366F1),
                    ),
                    AppLocalizations.of(context)?.militaryDepartment ??
                        'Военная кафедра',
                    const Color(0xFF6366F1), // Indigo
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernChip(
    BuildContext context,
    Widget icon,
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
            child: icon,
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
