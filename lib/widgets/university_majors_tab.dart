import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';

import '../data/ent_specialties_2026.dart';
import '../models/university.dart';
import '../screens/specialty_detail_screen.dart';
import '../services/specialty_description_service.dart';
import '../theme/app_colors.dart';
import 'specialty_info_card.dart';

/// Majors/specialties tab for university detail screen.
class UniversityMajorsTab extends StatelessWidget {
  final University university;
  final bool isDark;

  const UniversityMajorsTab({
    super.key,
    required this.university,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: university.majors.length,
      itemBuilder: (context, index) {
        final String major = university.majors[index];
        final EntSpecialty? matched =
            SpecialtyDescriptionService().findByMajorTitle(major);

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            if (matched != null) {
              _showSpecialtyModal(context, matched);
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withAlpha(13)
                    : AppColors.border.withAlpha(128),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        major,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      if (matched != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                matched.code,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${matched.quotaEmoji} ${l10n.grantsCount(matched.grantQuota2025)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.white38
                                    : Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (matched != null)
                  Icon(
                    Icons.info_outline_rounded,
                    color: isDark ? Colors.white24 : Colors.black26,
                    size: 20,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSpecialtyModal(
    BuildContext context,
    EntSpecialty specialty,
  ) {
    final isDarkMode =
        Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: isDarkMode
                ? AppColors.backgroundDark
                : AppColors.background,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.white24
                      : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      SpecialtyInfoCard(
                        specialty: specialty,
                        compact: false,
                        onTap: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  SpecialtyDetailScreen(
                                specialty: specialty,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      // CTA: подробнее
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    SpecialtyDetailScreen(
                                  specialty: specialty,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.open_in_new_rounded,
                            size: 18,
                          ),
                          label: Text(
                            l10n.moreStats,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDarkMode
                                ? const Color(0xFFA78BFA)
                                : const Color(0xFF6366F1),
                            padding:
                                const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
