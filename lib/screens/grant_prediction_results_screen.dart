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
import 'university_detail_screen.dart';
import 'ai_agent_screen.dart';

class GrantPredictionResultsScreen extends ConsumerWidget {
  final int entScore;

  const GrantPredictionResultsScreen({super.key, required this.entScore});

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
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final uni = universities[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _ResultUniCard(
                            uni: uni,
                            isDark: isDark,
                            untScore: entScore,
                          ),
                        );
                      }, childCount: universities.length),
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
                  l10n?.homeChanceAnalysis ?? 'Анализ шансов 2025',
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

  const _ResultUniCard({
    required this.uni,
    required this.isDark,
    required this.untScore,
  });

  @override
  State<_ResultUniCard> createState() => _ResultUniCardState();
}

class _ResultUniCardState extends State<_ResultUniCard> {
  bool _isLoadingStrategy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final chanceService = GrantChanceService();
    final chanceResult = chanceService.calculate(
      entScore: widget.untScore,
      universityId: widget.uni.id,
      majorCategory: MajorCategory.other,
    );

    final chanceColor = chanceResult.chancePercent >= 70
        ? Colors.green
        : (chanceResult.chancePercent >= 40 ? Colors.orange : Colors.red);

    return Container(
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
                backgroundColor: widget.isDark
                    ? Colors.white12
                    : Colors.black12,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildActionButton(l10n),
        ],
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
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
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
                Icon(Icons.auto_awesome, color: Colors.white, size: 18),
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

      final strategyData = await aiService.getAIStrategy(
        universityId: widget.uni.id,
        untScore: widget.untScore,
        specialtyId: widget.uni.majors.isNotEmpty
            ? widget.uni.majors.first
            : 'unknown',
        subjectScores: user?.mathScore != null
            ? {'Математика': user!.mathScore!}
            : null,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AIAgentScreen(
              title:
                  strategyData['title'] ??
                  (l10n?.aiStrategyFallbackTitle ?? 'Стратегия поступления'),
              description: strategyData['description'] ?? '',
              alternativeOptions: strategyData['alternative_options'] ?? [],
              targetUniversity: widget.uni,
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
