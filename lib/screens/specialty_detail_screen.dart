import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/ent_specialties_2026.dart';
import '../services/specialty_description_service.dart';
import '../theme/app_colors.dart';
import '../widgets/icon_3d.dart';
import 'ai_consultant_screen.dart';
import 'grant_wizard_screen.dart';

/// 📖 Полноэкранная карточка специальности
///
/// Показывает:
/// - Градиентный заголовок
/// - Человеческое описание
/// - Кем работать + зарплаты
/// - Где работают выпускники
/// - Статистика (гранты, баллы, тренд)
/// - CTA: Рассчитать шансы / Спросить AI
class SpecialtyDetailScreen extends StatefulWidget {
  final EntSpecialty specialty;

  const SpecialtyDetailScreen({super.key, required this.specialty});

  @override
  State<SpecialtyDetailScreen> createState() =>
      _SpecialtyDetailScreenState();
}

class _SpecialtyDetailScreenState extends State<SpecialtyDetailScreen> {
  final SpecialtyDescriptionService _service =
      SpecialtyDescriptionService();
  bool _isLoading = false;
  SpecialtyDescription? _desc;

  @override
  void initState() {
    super.initState();
    _desc = _service.getDescription(widget.specialty.code);
    if (_desc == null) {
      _isLoading = true;
      _service.loadDescription(widget.specialty).then((desc) {
        if (mounted) {
          setState(() {
            _desc = desc;
            _isLoading = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final langCode = Localizations.localeOf(context).languageCode;
    final s = widget.specialty;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 🎨 Градиентный заголовок
          _buildAppBar(s, isDark, langCode),

          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 💬 Описание
                if (_isLoading) _buildLoadingCard(isDark),
                if (!_isLoading && _desc == null) _buildErrorCard(isDark),
                if (_desc != null) ...[
                  _buildDescriptionCard(_desc!, isDark, langCode),
                  const SizedBox(height: 16),
                  _buildCareerCard(_desc!, isDark),
                  const SizedBox(height: 16),
                  _buildWorkplacesCard(_desc!, isDark),
                ],

                const SizedBox(height: 16),
                // 📊 Статистика
                _buildStatsCard(s, isDark),

                const SizedBox(height: 16),
                // 📚 Предметы
                _buildSubjectsCard(s, isDark),

                const SizedBox(height: 24),
                // 🚀 CTA
                _buildCTAButtons(s, isDark),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(
    EntSpecialty s,
    bool isDark,
    String langCode,
  ) {
    final trendText = switch (s.trend) {
      CompetitionTrend.rising => 'Конкурс растёт ⬆️',
      CompetitionTrend.falling => 'Конкурс падает ⬇️',
      CompetitionTrend.stable => 'Конкурс стабилен ➡️',
    };

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: isDark ? AppColors.cardDark : Colors.white,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: isDark ? Colors.white : Colors.white,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6366F1),
                Color(0xFF8B5CF6),
                Color(0xFFA78BFA),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Код badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      s.code,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Название
                  Text(
                    s.getTitle(langCode),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 6),
                  // Тренд
                  Text(
                    trendText,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionCard(
    SpecialtyDescription desc,
    bool isDark,
    String langCode,
  ) {
    return _card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('💡', 'Простыми словами', isDark),
          const SizedBox(height: 10),
          Text(
            desc.getDescription(langCode),
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: isDark ? Colors.white.withValues(alpha: 0.85) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareerCard(SpecialtyDescription desc, bool isDark) {
    if (desc.careerExamples.isEmpty) return const SizedBox();

    return _card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('👔', 'Кем буду работать?', isDark),
          const SizedBox(height: 12),
          ...desc.careerExamples.map((career) {
            final parts = career.split(' — ');
            final title = parts.first;
            final salary = parts.length > 1 ? parts.last : '';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF10B981).withValues(alpha: 0.08)
                    : const Color(0xFF10B981).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.work_outline_rounded,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  if (salary.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        salary,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWorkplacesCard(
    SpecialtyDescription desc,
    bool isDark,
  ) {
    if (desc.workplaces.isEmpty) return const SizedBox();

    return _card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('🏢', 'Где работают выпускники', isDark),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: desc.workplaces.map((place) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF3B82F6).withValues(alpha: 0.12)
                      : const Color(0xFF3B82F6).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF3B82F6)
                        .withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  place,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFF93C5FD)
                        : const Color(0xFF2563EB),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(EntSpecialty s, bool isDark) {
    return _card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('📊', 'Статистика', isDark),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _statTile(
                  label: 'Грантов 2025',
                  value: '${s.grantQuota2025}',
                  emoji: s.quotaEmoji,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statTile(
                  label: 'Проходной 2025',
                  value: '${s.minScore2025}',
                  emoji: '📈',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statTile(
                  label: 'Прогноз 2026',
                  value: '${s.predictedMin2026}',
                  emoji: '🎯',
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectsCard(EntSpecialty s, bool isDark) {
    return _card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('📚', 'Профильные предметы', isDark),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  color: isDark ? Colors.white38 : Colors.black38,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  s.subjectPair,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCTAButtons(EntSpecialty s, bool isDark) {
    return Column(
      children: [
        // 🌟 Premium Button: Рассчитать шансы
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GrantWizardScreen(),
                  ),
                );
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.insights_rounded, color: Colors.white, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Рассчитать шансы на грант',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // 🤖 Premium Outlined Button: Спросить AI
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF8B5CF6).withValues(alpha: 0.08)
                : const Color(0xFF8B5CF6).withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? const Color(0xFFA78BFA).withValues(alpha: 0.5)
                  : const Color(0xFF6366F1).withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AIConsultantScreen(
                      initialQuery:
                          'Расскажи подробнее о специальности '
                          '${s.titleRu} (${s.code}). '
                          'Какие перспективы на рынке труда Казахстана?',
                    ),
                  ),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: isDark
                        ? const Color(0xFFA78BFA)
                        : const Color(0xFF6366F1),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Спросить AI-консультанта',
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFFA78BFA)
                          : const Color(0xFF6366F1),
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Helper widgets ---

  Widget _card({required bool isDark, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.border,
        ),
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String emoji, String title, bool isDark) {
    return Row(
      children: [
        Icon3D(emoji: emoji, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _statTile({
    required String label,
    required String value,
    required String emoji,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon3D(emoji: emoji, size: 28),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white38 : Colors.black45,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard(bool isDark) {
    return _card(
      isDark: isDark,
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: isDark ? Colors.white38 : Colors.black26,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'AI генерирует описание...',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white38 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(bool isDark) {
    return _card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: isDark ? Colors.redAccent : Colors.red,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Ошибка загрузки',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.redAccent : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Не удалось сгенерировать описание от AI. Сервер может перезапускаться (до 1 минуты).',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() => _isLoading = true);
                _service.loadDescription(widget.specialty).then((desc) {
                  if (mounted) {
                    setState(() {
                      _desc = desc;
                      _isLoading = false;
                    });
                  }
                });
              },
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Повторить попытку'),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? Colors.redAccent : Colors.red,
                side: BorderSide(
                  color: isDark ? Colors.redAccent.withValues(alpha: 0.5) : Colors.red.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
