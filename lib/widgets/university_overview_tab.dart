import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/university.dart';
import '../l10n/app_localizations.dart';

/// Overview tab for university detail screen.
class UniversityOverviewTab extends StatelessWidget {
  final University university;
  final bool isDark;

  const UniversityOverviewTab({
    super.key,
    required this.university,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? Colors.white.withAlpha(13)
                : AppColors.border.withAlpha(128),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n?.detailAboutUniversity ?? 'About University',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              university.description,
              style: TextStyle(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
                height: 1.6,
                fontSize: 15,
              ),
            ),

            // ═══ Инфраструктура ═══
            if (university.hasMilitaryDepartment ||
                university.hasDormitory) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.apartment_rounded,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    l10n?.moderatorSectionInfra ?? 'Инфраструктура',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (university.hasMilitaryDepartment)
                _buildInfoRow(
                  Icons.shield_rounded,
                  l10n?.militaryDepartment ?? 'Военная кафедра',
                  '✅ ${l10n?.detailAvailable ?? 'Есть'}',
                  AppColors.gold,
                  isDark,
                ),
              if (university.hasDormitory) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.night_shelter_rounded,
                  l10n?.dormitory ?? 'Общежитие',
                  university.dormitoryPrice != null
                      ? '${university.dormitoryPrice} ₸/мес'
                      : '✅ ${l10n?.detailAvailable ?? 'Есть'}',
                  AppColors.success,
                  isDark,
                ),
              ],
            ],

            // ═══ Местоположение ═══
            if (university.address.isNotEmpty ||
                (university.latitude != null &&
                    university.longitude != null)) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.place_rounded,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    l10n?.location ?? 'Местоположение',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (university.address.isNotEmpty)
                _buildInfoRow(
                  Icons.home_rounded,
                  l10n?.detailAddress ?? 'Адрес',
                  university.address,
                  AppColors.primary,
                  isDark,
                ),
              if (university.latitude != null &&
                  university.longitude != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.map_rounded,
                  'Google Maps',
                  '${university.latitude}, ${university.longitude}',
                  AppColors.secondary,
                  isDark,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    Color iconColor,
    bool isDark,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
