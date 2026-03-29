import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../models/university.dart';
import '../providers/grant_predictor_provider.dart';
import '../services/grant_chance_service.dart';
import '../services/auth_service.dart';
import '../services/ai_consultant_service.dart';
import '../services/university_service.dart';
import 'university_detail_screen.dart';
import 'ai_agent_screen.dart';
import '../widgets/ai_logo_icon.dart';
import '../data/ent_specialties_2026.dart';

class GrantPredictionResultsScreen extends ConsumerWidget {
  final int entScore;
  final EntSpecialty? specialty;

  const GrantPredictionResultsScreen({
    super.key,
    required this.entScore,
    this.specialty,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final universitiesAsync = ref.watch(universitiesProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Premium Background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF0F172A), const Color(0xFF1E1B4B)]
                      : [const Color(0xFFF0F9FF), const Color(0xFFE0E7FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(context, l10n, isDark),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: _buildHeaderCard(context, entScore, isDark, l10n),
                ),
              ),
              universitiesAsync.when(
                data: (universities) {
                  if (universities.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Text(
                          l10n?.homeNoUniversitiesFound ??
                              'Университеты не найдены',
                        ),
                      ),
                    );
                  }

                  // 🔥 Оптимизация: 미리 вычисляем шансы, чтобы не лагало при сортировке (O(N) вместо O(N log N))
                  final chanceService = GrantChanceService();
                  final user = AuthService().currentUser.value;

                  final sortedUniversities = List<University>.from(
                    universities,
                  );

                  // 1. Кешируем полные результаты вычислений (не только %, а весь GrantChanceResult)
                  final Map<String, GrantChanceResult> chanceCache = {};
                  for (final uni in sortedUniversities) {
                    if (specialty != null) {
                      // 🎯 Новый расчёт по ГОП
                      chanceCache[uni.id] = chanceService.calculateBySpecialty(
                        entScore: entScore,
                        minPassingScore: specialty!.predictedMin2026,
                        grantQuota: specialty!.grantQuota2025,
                        trendName: specialty!.trend.name,
                        universityId: uni.id,
                        universityPassingScore: uni.passingScore,
                        gpa: user?.gpa,
                        ieltsScore: user?.ieltsScore,
                        achievements: user?.achievements ?? [],
                        hasDisability: user?.hasDisability ?? false,
                        isOrphan: user?.isOrphan ?? false,
                        isRural: user?.isRural ?? false,
                      );
                    } else {
                      // Старый расчёт
                      final cat = uni.majors.isNotEmpty
                          ? chanceService.detectCategory(uni.majors.first)
                          : MajorCategory.other;
                      chanceCache[uni.id] = chanceService.calculate(
                        entScore: entScore,
                        universityId: uni.id,
                        universityPassingScore: uni.passingScore,
                        majorCategory: cat,
                        gpa: user?.gpa,
                        ieltsScore: user?.ieltsScore,
                        achievements: user?.achievements ?? [],
                        userCity: user?.city,
                        universityCity: uni.city,
                      );
                    }
                  }

                  // 2. Сортируем используя кэш
                  sortedUniversities.sort((a, b) {
                    final chanceA = chanceCache[a.id]?.chancePercent ?? 0;
                    final chanceB = chanceCache[b.id]?.chancePercent ?? 0;
                    return chanceB.compareTo(chanceA);
                  });

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final uni = sortedUniversities[index];
                        // ⚡ Используем кэш вместо повторного вычисления
                        final chanceResult = chanceCache[uni.id]!;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _ResultUniCard(
                            uni: uni,
                            isDark: isDark,
                            untScore: entScore,
                            chanceResult: chanceResult,
                          ),
                        );
                      }, childCount: sortedUniversities.length),
                    ),
                  );
                },
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, st) => SliverFillRemaining(
                  child: Center(
                    child: Text(
                      l10n?.commonError(e.toString()) ?? 'Ошибка: $e',
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    AppLocalizations? l10n,
    bool isDark,
  ) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new,
          color: isDark ? Colors.white : Colors.black,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          color: isDark
              ? Colors.black.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.65),
        ),
        child: FlexibleSpaceBar(
          title: Text(
            l10n?.homeChanceEstimation ?? 'Результаты анализа',
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
      ),
    );
  }

  Widget _buildHeaderCard(
    BuildContext context,
    int score,
    bool isDark,
    AppLocalizations? l10n,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.homeChanceAnalysis ?? 'Анализ шансов 2026',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n?.homeYourScore(score) ?? 'Ваш актуальный балл: $score',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                // 🏷️ Source indicator
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calculate_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                      SizedBox(width: 5),
                      Text(
                        '🧮 Расчёт МОН РК 2026',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.analytics_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultUniCard extends StatefulWidget {
  final University uni;
  final bool isDark;
  final int untScore;
  final GrantChanceResult chanceResult;

  const _ResultUniCard({
    required this.uni,
    required this.isDark,
    required this.untScore,
    required this.chanceResult,
  });

  @override
  State<_ResultUniCard> createState() => _ResultUniCardState();
}

class _ResultUniCardState extends State<_ResultUniCard> {
  bool _isLoadingStrategy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final chanceResult = widget.chanceResult;

    final chanceColor = chanceResult.chancePercent >= 70
        ? Colors.green
        : (chanceResult.chancePercent >= 40 ? Colors.orange : Colors.red);

    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: widget.isDark
                ? Colors.white.withValues(alpha: 0.05)
                : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            UniversityDetailScreen(university: widget.uni),
                      ),
                    );
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                    child: const Icon(
                      Icons.account_balance,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.uni.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: widget.isDark
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.uni.city,
                        style: TextStyle(
                          fontSize: 13,
                          color: widget.isDark
                              ? Colors.white54
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                CircularPercentIndicator(
                  radius: 26.0,
                  lineWidth: 5.0,
                  animation: true,
                  percent: chanceResult.chancePercent / 100,
                  center: Text(
                    '${chanceResult.chancePercent}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  circularStrokeCap: CircularStrokeCap.round,
                  progressColor: chanceColor,
                  backgroundColor:
                      widget.isDark ? Colors.white12 : Colors.black12,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildActionButton(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(AppLocalizations? l10n) {
    if (_isLoadingStrategy) {
      return Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            _AnimatedTypingIndicator(isDark: widget.isDark),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _launchAIStrategy,
          borderRadius: BorderRadius.circular(16),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AILogoIcon(size: 18, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'AI Strategy',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchAIStrategy() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isLoadingStrategy = true);

    try {
      final user = AuthService().currentUser.value;
      final aiService = AIConsultantService();
      final chanceService = GrantChanceService();

      // Генерация альтернатив заранее для обоих случаев (онлайн и оффлайн)
      final MajorCategory category = widget.uni.majors.isNotEmpty
          ? chanceService.detectCategory(widget.uni.majors.first)
          : MajorCategory.other;

      final result = chanceService.calculate(
        entScore: widget.untScore,
        universityId: widget.uni.id,
        majorCategory: category,
        gpa: user?.gpa,
        ieltsScore: user?.ieltsScore,
        achievements: user?.achievements ?? [],
        userCity: user?.city,
        universityCity: widget.uni.city,
      );

      final List<Map<String, dynamic>> alternatives = [];
      final allUniversities = (await UniversityService().getAllUniversities())
          .where((u) => u.id != widget.uni.id)
          .toList();

      for (final altUni in allUniversities) {
        final altCategory = altUni.majors.isNotEmpty
            ? chanceService.detectCategory(altUni.majors.first)
            : MajorCategory.other;

        final altResult = chanceService.calculate(
          entScore: widget.untScore,
          universityId: altUni.id,
          majorCategory: altCategory,
          gpa: user?.gpa,
          ieltsScore: user?.ieltsScore,
          achievements: user?.achievements ?? [],
          userCity: user?.city,
          universityCity: altUni.city,
        );

        if (altResult.chancePercent > result.chancePercent) {
          alternatives.add({
            'university': altUni,
            'university_name': altUni.name,
            'specialty_name':
                altUni.majors.isNotEmpty ? altUni.majors.first : 'Жалпы',
            'probability': altResult.chancePercent,
          });
        }
      }

      alternatives.sort(
        (a, b) => (b['probability'] as int).compareTo(a['probability'] as int),
      );
      final topAlternatives = alternatives.take(3).toList();

      // Попытка получить стратегию от бэкенда
      try {
        final strategyData = await aiService.getAIStrategy(
          universityId: widget.uni.id,
          untScore: widget.untScore,
          specialtyId: widget.uni.majors.isNotEmpty
              ? widget.uni.majors.first
              : 'unknown',
          subjectScores:
              user?.mathScore != null ? {'Математика': user!.mathScore!} : null,
        );

        if (strategyData['description'] != null &&
            strategyData['description'].toString().contains(
                  'сервис временно недоступен',
                )) {
          throw Exception('Backend returned explicit unavailable message');
        }

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AIAgentScreen(
                title: strategyData['title'] ??
                    (l10n?.aiStrategyFallbackTitle ?? 'Стратегия поступления'),
                description: strategyData['description'] ?? '',
                alternativeOptions: topAlternatives,
                targetUniversity: widget.uni,
              ),
            ),
          );
          return;
        }
      } catch (_) {
        // Бэкенд недоступен или токены закончились → используем локальную стратегию
        debugPrint(
          '⚠️ Backend unavailable or out of tokens, using local strategy',
        );
      }

      // ═══════════════════════════════════════════
      // 🔄 ЛОКАЛЬНАЯ СТРАТЕГИЯ (без бэкенда)
      // Использует верифицированные данные МОН РК 2026
      // ═══════════════════════════════════════════
      // Использует верифицированные данные МОН РК 2026
      // ═══════════════════════════════════════════

      // Формируем описание стратегии из данных СВД
      final StringBuffer strategy = StringBuffer();

      strategy.writeln('## 📌 Анализ вашего профиля\n');
      strategy.writeln('- **Ваш балл ЕНТ:** ${widget.untScore} из 140');
      strategy.writeln(
        '- **Пороговый балл:** ${result.entThreshold} (${category.displayName})',
      );
      strategy.writeln('- **Шанс на грант:** ${result.chancePercent}%');
      strategy.writeln(
        '- **Уровень риска:** ${result.riskLevel.emoji} ${result.riskLevel.displayName}',
      );
      if (user?.gpa != null) {
        strategy.writeln('- **GPA:** ${user!.gpa}');
      }
      if (user?.ieltsScore != null) {
        strategy.writeln('- **IELTS:** ${user!.ieltsScore}');
      }

      strategy.writeln(
        '\n## 📊 Детальный анализ (данные МОН РК ${result.dataYear})\n',
      );
      for (final detail in result.details) {
        strategy.writeln('- $detail');
      }

      strategy.writeln('\n## 🎯 Вердикт\n');
      strategy.writeln('**${result.verdict}**');

      if (result.recommendations.isNotEmpty) {
        strategy.writeln('\n## 🚀 Рекомендации\n');
        for (int i = 0; i < result.recommendations.length; i++) {
          strategy.writeln('${i + 1}. ${result.recommendations[i]}');
        }
      }

      // Добавляем информацию о университете
      strategy.writeln('\n## 🏛️ О ${widget.uni.name}\n');
      strategy.writeln('- **Город:** ${widget.uni.city}');
      strategy.writeln('- **Стоимость:** ${widget.uni.tuitionRange}');
      strategy.writeln(
        '- **Общежитие:** ${widget.uni.hasDormitory ? "✅ Есть" : "❌ Нет"}',
      );
      strategy.writeln(
        '- **Гранты:** ${widget.uni.hasGrants ? "✅ Доступны" : "❌ Не доступны"}',
      );
      if (widget.uni.studentCount > 0) {
        strategy.writeln('- **Студенты:** ${widget.uni.studentCount}');
      }
      strategy.writeln(
        '- **Специальности:** ${widget.uni.majors.take(5).join(", ")}',
      );

      // Альтернативные варианты уже сгенерированы выше

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AIAgentScreen(
              title: 'Стратегия: ${widget.uni.name}',
              description: strategy.toString(),
              alternativeOptions: topAlternatives,
              targetUniversity: widget.uni,
              isLocalStrategy: true,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.commonError(e.toString()) ?? 'Ошибка: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingStrategy = false);
    }
  }
}

// ═══════════════════════════════════════════
//  ANIMATED TYPING INDICATOR
// ═══════════════════════════════════════════
class _AnimatedTypingIndicator extends StatefulWidget {
  final bool isDark;
  const _AnimatedTypingIndicator({required this.isDark});

  @override
  State<_AnimatedTypingIndicator> createState() =>
      _AnimatedTypingIndicatorState();
}

class _AnimatedTypingIndicatorState extends State<_AnimatedTypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final val = _controller.value;
        String dots = '';
        if (val < 0.25) {
          dots = '';
        } else if (val < 0.5) {
          dots = '.';
        } else if (val < 0.75) {
          dots = '..';
        } else {
          dots = '...';
        }

        return Text(
          'Создаю AI стратегию$dots',
          style: TextStyle(
            color: widget.isDark ? Colors.white54 : AppColors.primary,
            fontSize: 13,
            fontStyle: FontStyle.italic,
          ),
        );
      },
    );
  }
}
