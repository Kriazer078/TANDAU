import 'package:flutter/material.dart';

import '../data/ent_specialties_2026.dart';
import '../services/specialty_description_service.dart';
import '../theme/app_colors.dart';
import 'icon_3d.dart';

/// 💬 Карточка специальности с человеческим описанием
///
/// Показывает:
/// - Код + название ГОП
/// - Описание простым языком
/// - Кем работать + зарплата
/// - Где работают выпускники
/// - Грантов / балл / тренд
class SpecialtyInfoCard extends StatefulWidget {
  final EntSpecialty specialty;
  final bool compact;
  final VoidCallback? onTap;

  const SpecialtyInfoCard({
    super.key,
    required this.specialty,
    this.compact = false,
    this.onTap,
  });

  @override
  State<SpecialtyInfoCard> createState() => _SpecialtyInfoCardState();
}

class _SpecialtyInfoCardState extends State<SpecialtyInfoCard> {
  final SpecialtyDescriptionService _service =
      SpecialtyDescriptionService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadIfNeeded();
  }

  void _loadIfNeeded() {
    if (!_service.hasDescription(widget.specialty.code)) {
      setState(() => _isLoading = true);
      _service.loadDescription(widget.specialty).then((_) {
        if (mounted) setState(() => _isLoading = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final langCode = Localizations.localeOf(context).languageCode;
    final desc = _service.getDescription(widget.specialty.code);

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : AppColors.border,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🎯 Заголовок: код + название
            _buildHeader(isDark, langCode),

            if (desc != null) ...[
              const SizedBox(height: 12),
              // 💬 Описание простым языком
              _buildDescription(desc, isDark, langCode),

              if (!widget.compact) ...[
                const SizedBox(height: 16),
                // 👔 Кем буду работать
                _buildCareerSection(desc, isDark),

                const SizedBox(height: 12),
                // 🏢 Где работают
                _buildWorkplacesSection(desc, isDark),
              ],
            ] else if (_isLoading) ...[
              const SizedBox(height: 12),
              _buildLoadingState(isDark),
            ] else ...[
              const SizedBox(height: 12),
              _buildErrorState(isDark),
            ],

            const SizedBox(height: 12),
            // 📊 Статистика
            _buildStats(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, String langCode) {
    final s = widget.specialty;
    final trendIcon = switch (s.trend) {
      CompetitionTrend.rising => '⬆️',
      CompetitionTrend.falling => '⬇️',
      CompetitionTrend.stable => '➡️',
    };

    return Row(
      children: [
        // Код ГОП badge
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            s.code,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            s.getTitle(langCode),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Icon3D(emoji: trendIcon, size: 24),
      ],
    );
  }

  Widget _buildDescription(
    SpecialtyDescription desc,
    bool isDark,
    String langCode,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF6366F1).withValues(alpha: 0.1)
            : const Color(0xFF6366F1).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon3D(emoji: '💡', size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              desc.getDescription(langCode),
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareerSection(
    SpecialtyDescription desc,
    bool isDark,
  ) {
    if (desc.careerExamples.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon3D(emoji: '👔', size: 16),
            const SizedBox(width: 6),
            Text(
              'Кем буду работать:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...desc.careerExamples.map(
          (career) => Padding(
            padding: const EdgeInsets.only(left: 28, bottom: 4),
            child: Row(
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    career,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkplacesSection(
    SpecialtyDescription desc,
    bool isDark,
  ) {
    if (desc.workplaces.isEmpty) return const SizedBox();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon3D(emoji: '🏢', size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Где работают: ',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                TextSpan(
                  text: desc.workplaces.join(' · '),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStats(bool isDark) {
    final s = widget.specialty;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem(
            '${s.quotaEmoji} Грантов',
            '${s.grantQuota2025}',
            isDark,
          ),
          _buildStatItem(
            '📈 Балл 2025',
            '${s.minScore2025}',
            isDark,
          ),
          _buildStatItem(
            '🎯 Прогноз',
            '${s.predictedMin2026}',
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: isDark ? Colors.white38 : Colors.black26,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Загружаю описание от AI...',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.redAccent.withValues(alpha: 0.1)
            : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: isDark ? Colors.redAccent : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Не удалось загрузить описание. Сервер перезапускается (до 1 мин).',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.redAccent.shade100 : Colors.red.shade800,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            color: isDark ? Colors.redAccent : Colors.red,
            onPressed: () {
              setState(() => _isLoading = true);
              _service.loadDescription(widget.specialty).then((_) {
                if (mounted) setState(() => _isLoading = false);
              });
            },
            tooltip: 'Повторить',
          ),
        ],
      ),
    );
  }
}
