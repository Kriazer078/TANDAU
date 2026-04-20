import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/university.dart';
import '../l10n/app_localizations.dart';

/// 🏢 Infrastructure tab for university detail screen (includes dormitory, military department, location).
class UniversityInfrastructureTab extends StatelessWidget {
  final University university;
  final bool isDark;

  const UniversityInfrastructureTab({
    super.key,
    required this.university,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ═══ Военная кафедра ═══
          if (university.hasMilitaryDepartment) ...[
            _buildSectionTitle(
                Icons.shield_rounded, l10n?.militaryDepartment ?? 'Военная кафедра'),
            const SizedBox(height: 16),
            _buildMilitaryDepartmentCard(l10n),
            const SizedBox(height: 24),
          ] else ...[
            _buildMissingFeatureCard(
              Icons.shield_rounded,
              l10n?.militaryNotAvailable ?? 'Нет военной кафедры',
              AppColors.error,
            ),
            const SizedBox(height: 24),
          ],

          // ═══ Общежитие ═══
          _buildSectionTitle(Icons.night_shelter_rounded, l10n?.dormitory ?? 'Общежитие'),
          const SizedBox(height: 16),
          // Статус общежития
          _buildStatusCard(l10n),
          const SizedBox(height: 16),

          if (university.hasDormitory) ...[
            // Детали (цена, расстояние)
            if (university.dormitoryPrice != null ||
                university.dormitoryPriceYear != null ||
                (university.dormitoryDistanceInfo != null &&
                 university.dormitoryDistanceInfo!.isNotEmpty)) ...[
              _buildDetailsCard(l10n),
              const SizedBox(height: 16),
            ],

            // Фото комнат
            if (university.dormitoryPhotoUrls.isNotEmpty) ...[
              _buildPhotoGallery(l10n),
              const SizedBox(height: 16),
            ],

            // Описание условий
            if (university.dormitoryDescription != null &&
                university.dormitoryDescription!.isNotEmpty)
              _buildConditionsCard(l10n),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildMilitaryDepartmentCard(AppLocalizations? l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.gold.withAlpha(30),
            AppColors.gold.withAlpha(10),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.gold.withAlpha(80),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.gold.withAlpha(40),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_police_rounded,
                  color: AppColors.gold,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  l10n?.militaryAvailable ?? 'Есть военная кафедра',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.gold,
                  ),
                ),
              ),
            ],
          ),
          if (university.militaryStartCourse != null ||
              (university.militaryCompetition != null &&
                  university.militaryCompetition!.isNotEmpty)) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 16),
            if (university.militaryStartCourse != null)
              _buildDetailRow(
                Icons.school_rounded,
                l10n?.militaryStartCourseLabel ?? 'С какого курса',
                l10n?.militaryStartCourse(university.militaryStartCourse!) ??
                    'С ${university.militaryStartCourse} курса',
                AppColors.gold,
              ),
            if (university.militaryStartCourse != null &&
                university.militaryCompetition != null &&
                university.militaryCompetition!.isNotEmpty)
              const SizedBox(height: 12),
            if (university.militaryCompetition != null &&
                university.militaryCompetition!.isNotEmpty)
              _buildDetailRow(
                Icons.people_rounded,
                l10n?.militaryCompetitionLabel ?? 'Конкурс',
                university.militaryCompetition!,
                AppColors.gold,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildMissingFeatureCard(IconData icon, String message, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withAlpha(20),
            color.withAlpha(5),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color.withAlpha(180), size: 24),
          const SizedBox(width: 12),
          Text(
            message,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Карточка статуса: есть общежитие или нет
  Widget _buildStatusCard(AppLocalizations? l10n) {
    final bool available = university.hasDormitory;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: available
            ? LinearGradient(
                colors: [
                  AppColors.success.withAlpha(30),
                  AppColors.success.withAlpha(10),
                ],
              )
            : LinearGradient(
                colors: [
                  AppColors.error.withAlpha(30),
                  AppColors.error.withAlpha(10),
                ],
              ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: available
              ? AppColors.success.withAlpha(80)
              : AppColors.error.withAlpha(80),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: available
                  ? AppColors.success.withAlpha(40)
                  : AppColors.error.withAlpha(40),
              shape: BoxShape.circle,
            ),
            child: Icon(
              available
                  ? Icons.night_shelter_rounded
                  : Icons.block_rounded,
              color: available ? AppColors.success : AppColors.error,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  available
                      ? (l10n?.dormitoryAvailable ?? 'Общежитие есть')
                      : (l10n?.dormitoryNotAvailable ?? 'Общежития нет'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: available ? AppColors.success : AppColors.error,
                  ),
                ),
                if (available && university.dormitoryForFreshmen) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.verified_rounded,
                          color: AppColors.gold, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        l10n?.dormitoryForFreshmen ??
                            '100% первокурсникам',
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Карточка с деталями: стоимость, расстояние
  Widget _buildDetailsCard(AppLocalizations? l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          // Стоимость/месяц
          if (university.dormitoryPrice != null)
            _buildDetailRow(
              Icons.payments_rounded,
              l10n?.dormitoryPrice ?? 'Цена общежития',
              '${_formatPrice(university.dormitoryPrice!)} ₸/мес',
              AppColors.primary,
            ),

          // Стоимость/год
          if (university.dormitoryPriceYear != null) ...[
            if (university.dormitoryPrice != null)
              const SizedBox(height: 12),
            _buildDetailRow(
              Icons.calendar_month_rounded,
              l10n?.dormitoryPriceYear ?? 'Стоимость за год',
              '${_formatPrice(university.dormitoryPriceYear!)} ₸/год',
              AppColors.secondary,
            ),
          ],

          // Расстояние
          if (university.dormitoryDistanceInfo != null &&
              university.dormitoryDistanceInfo!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.directions_walk_rounded,
              l10n?.dormitoryDistance ?? 'Расстояние до корпусов',
              university.dormitoryDistanceInfo!,
              AppColors.gold,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Галерея фото комнат
  Widget _buildPhotoGallery(AppLocalizations? l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.photo_library_rounded,
                color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              l10n?.dormitoryPhotos ?? 'Фото комнат',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: university.dormitoryPhotoUrls.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  university.dormitoryPhotoUrls[index],
                  width: 260,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 260,
                    height: 180,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.cardDark
                          : AppColors.border.withAlpha(50),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.broken_image_rounded,
                      size: 40,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Карточка с описанием условий
  Widget _buildConditionsCard(AppLocalizations? l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withAlpha(13)
              : AppColors.border.withAlpha(128),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n?.dormitoryConditions ?? 'Условия проживания',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            university.dormitoryDescription!,
            style: TextStyle(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
              height: 1.6,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(int price) {
    final String str = price.toString();
    final StringBuffer buf = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buf.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) buf.write(' ');
    }
    return buf.toString().split('').reversed.join();
  }
}
