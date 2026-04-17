import 'package:flutter/material.dart';

import '../data/holland_test_data.dart';
import '../data/klimov_test_data.dart';
import '../models/career_test_result.dart';
import '../services/career_test_service.dart';
import '../theme/app_colors.dart';
import '../data/ent_specialties_2026.dart';
import '../widgets/specialty_info_card.dart';
import '../widgets/icon_3d.dart';
import 'grant_wizard_screen.dart';
import 'specialty_detail_screen.dart';

/// 📊 Экран результатов карьерного теста
///
/// Показывает:
/// - Радар-чарт (bar chart) RIASEC типов
/// - Описание доминирующего типа
/// - Подходящие профессии
/// - Рекомендуемые ГОП (специальности ЕНТ)
/// - CTA-кнопки: GrantWizard, ROI
class CareerTestResultScreen extends StatelessWidget {
  final CareerTestResult result;

  const CareerTestResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isHolland = result.testType == 'holland';
    final topType = isHolland 
        ? (result.topCode.isNotEmpty ? result.topCode[0] : 'R')
        : (result.topCode.isNotEmpty ? result.topCode : 'nature');
    final topColor = Color(
      isHolland
          ? (CareerTestResult.riasecColors[topType] ?? 0xFFE91E63)
          : (CareerTestResult.klimovColors[topType] ?? 0xFF2196F3),
    );
    final emoji = isHolland 
        ? (CareerTestResult.riasecEmojis[topType] ?? '🧭')
        : (CareerTestResult.klimovEmojis[topType] ?? '🔬');
    final typeName = isHolland
        ? (CareerTestResult.riasecNamesRu[topType] ?? 'Неизвестный')
        : (CareerTestResult.klimovNamesRu[topType] ?? 'Неизвестная сфера');

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 🎨 Заголовок с градиентом
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: isDark ? AppColors.cardDark : Colors.white,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      topColor,
                      topColor.withValues(alpha: 0.7),
                      isDark
                          ? topColor.withValues(alpha: 0.3)
                          : topColor.withValues(alpha: 0.4),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 50, 24, 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Emoji + код
                        Icon3D(emoji: emoji, size: 60),
                        const SizedBox(height: 12),
                        Text(
                          'Твой тип: ${isHolland ? result.topCode : typeName}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isHolland ? typeName : 'Сфера деятельности',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 📋 Контент
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 📊 Диаграмма типов
                  _buildScoreChart(isDark, topColor),
                  const SizedBox(height: 24),

                  // 📝 Описание типа
                  _buildTypeDescription(isDark, topType, topColor),
                  const SizedBox(height: 24),

                  // 👔 Подходящие профессии
                  _buildProfessions(isDark, topType, topColor),
                  const SizedBox(height: 24),

                  // 🎓 Рекомендуемые специальности ЕНТ
                  _buildRecommendedSpecialties(context, isDark, topColor),
                  const SizedBox(height: 24),

                  // 🚀 CTA кнопки
                  _buildCTAButtons(context, isDark, topColor),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 📊 Горизонтальная диаграмма баллов по типам
  Widget _buildScoreChart(bool isDark, Color topColor) {
    final isHolland = result.testType == 'holland';
    final maxScore = result.scores.values.fold<int>(
      1,
      (prev, val) => val > prev ? val : prev,
    );

    final sortedEntries = result.scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.border.withValues(alpha: 0.3),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Результаты по типам',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          ...sortedEntries.map((entry) {
            final type = entry.key;
            final score = entry.value;
            final color = Color(
              isHolland
                ? (CareerTestResult.riasecColors[type] ?? 0xFF9E9E9E)
                : (CareerTestResult.klimovColors[type] ?? 0xFF9E9E9E),
            );
            final emoji = isHolland
                ? (CareerTestResult.riasecEmojis[type] ?? '🔵')
                : (CareerTestResult.klimovEmojis[type] ?? '🔵');
            final name = isHolland
                ? (CareerTestResult.riasecNamesRu[type] ?? type)
                : (CareerTestResult.klimovNamesRu[type] ?? type);
            final prefixStr = isHolland ? type : '';
            final percent = maxScore > 0 ? score / maxScore : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                    SizedBox(
                      width: 32,
                      child: Icon3D(emoji: emoji, size: 24),
                    ),
                  const SizedBox(width: 8),
                  if (prefixStr.isNotEmpty) ...[
                    SizedBox(
                      width: 32,
                      child: Text(
                        prefixStr,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white54
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: percent),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return LinearProgressIndicator(
                                value: value,
                                minHeight: 10,
                                backgroundColor: isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.grey.shade100,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(color),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$score',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
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

  /// 📝 Описание типа
  Widget _buildTypeDescription(bool isDark, String topType, Color topColor) {
    final isHolland = result.testType == 'holland';
    final description = isHolland
        ? (CareerTestResult.riasecDescriptions[topType] ?? '')
        : (CareerTestResult.klimovDescriptions[topType] ?? '');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: topColor.withValues(alpha: isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: topColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: topColor, size: 22),
              const SizedBox(width: 8),
              Text(
                'Твой профиль',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  /// 👔 Подходящие профессии
  Widget _buildProfessions(bool isDark, String topType, Color topColor) {
    final isHolland = result.testType == 'holland';
    final professions = isHolland
        ? (riasecProfessions[topType] ?? [])
        : (klimovProfessions[topType] ?? []);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.border.withValues(alpha: 0.3),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.work_outline_rounded, color: topColor, size: 22),
              const SizedBox(width: 8),
              Text(
                'Подходящие профессии',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: professions.map((p) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: topColor.withValues(alpha: isDark ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: topColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  p,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// 🎓 Рекомендуемые специальности ЕНТ
  Widget _buildRecommendedSpecialties(BuildContext context, bool isDark, Color topColor) {
    final service = CareerTestService();
    final specialties =
        service.getSpecialtiesByGopCodes(result.recommendedGops);

    // Берём топ-8 по кол-ву грантов
    final topSpecialties = specialties.toList()
      ..sort((a, b) => b.grantQuota2025.compareTo(a.grantQuota2025));
    final displayList = topSpecialties.take(8).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.border.withValues(alpha: 0.3),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school_rounded, color: topColor, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Рекомендуемые специальности ЕНТ',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Топ ${displayList.length} по количеству грантов',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white54 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ...displayList.map((s) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () {
                  _showSpecialtyModal(context, s, isDark);
                },
                child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.grey.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.grey.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    // Код ГОП
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: topColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        s.code,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: topColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Название
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.titleRu,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s.subjectPair,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white38
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Кол-во грантов
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          s.quotaEmoji,
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          '${s.grantQuota2025}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white70
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// 🚀 CTA-кнопки
  Widget _buildCTAButtons(
    BuildContext context,
    bool isDark,
    Color topColor,
  ) {
    return Column(
      children: [
        // Рассчитать шансы на грант
        _buildCTAButton(
          context: context,
          icon: Icons.pie_chart_rounded,
          title: '🎓 Рассчитать шансы на грант',
          subtitle: 'Узнай вероятность получения гранта',
          gradient: LinearGradient(
            colors: [topColor, topColor.withValues(alpha: 0.7)],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const GrantWizardScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),

        // Поделиться результатом
        _buildCTAButton(
          context: context,
          icon: Icons.share_rounded,
          title: '📤 Поделиться результатом',
          subtitle: 'Отправь друзьям свой тип',
          gradient: LinearGradient(
            colors: [
              Colors.grey.shade600,
              Colors.grey.shade500,
            ],
          ),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  result.testType == 'holland' 
                      ? 'Мой тип по Голланду: ${result.topCode} — ${CareerTestResult.riasecNamesRu[result.topCode.isNotEmpty ? result.topCode[0] : "R"]}! Пройди тест в TANDAU 🧭'
                      : 'Мой тип по Климову: ${CareerTestResult.klimovNamesRu[result.topCode.isNotEmpty ? result.topCode : "nature"]}! Пройди тест в TANDAU 🔬'
                ),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCTAButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white70,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSpecialtyModal(
    BuildContext context,
    EntSpecialty specialty,
    bool isDarkMode,
  ) {
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
                  color: isDarkMode ? Colors.white24 : Colors.black12,
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
                              builder: (_) => SpecialtyDetailScreen(
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
                                builder: (_) => SpecialtyDetailScreen(
                                  specialty: specialty,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.open_in_new_rounded, size: 18),
                          label: const Text('Подробнее о специальности'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDarkMode
                                ? const Color(0xFFA78BFA)
                                : const Color(0xFF6366F1),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
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
