import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../theme/app_colors.dart';
import '../models/university.dart';
import '../models/student_profile.dart';
import '../services/ai_consultant_service.dart';
import '../services/grant_chance_service.dart';
import '../l10n/app_localizations.dart';
import 'ai_logo_icon.dart';

/// Grid painter used for decorative background pattern.
class GridPainter extends CustomPainter {
  final Color color;
  GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..strokeWidth = 1;

    for (var i = 0; i < size.width; i += 40) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(i.toDouble(), size.height),
        paint,
      );
    }
    for (var i = 0; i < size.height; i += 40) {
      canvas.drawLine(
        Offset(0, i.toDouble()),
        Offset(size.width, i.toDouble()),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// SVD Result Bottom Sheet — shows grant chance analytics + AI strategy.
class SvdResultSheet extends StatefulWidget {
  final GrantChanceResult svdResult;
  final bool isDark;
  final University university;
  final StudentProfile profile;

  const SvdResultSheet({
    super.key,
    required this.svdResult,
    required this.isDark,
    required this.university,
    required this.profile,
  });

  @override
  State<SvdResultSheet> createState() => _SvdResultSheetState();
}

class _SvdResultSheetState extends State<SvdResultSheet> {
  bool _isLoadingAiStrategy = false;
  String? _aiStrategy;

  AppLocalizations? get l10n => AppLocalizations.of(context);

  Color get _riskColor {
    switch (widget.svdResult.riskLevel) {
      case RiskLevel.low:
        return Colors.green;
      case RiskLevel.medium:
        return Colors.orange;
      case RiskLevel.high:
        return Colors.deepOrange;
      case RiskLevel.critical:
        return AppColors.error;
      case RiskLevel.unknown:
        return Colors.grey;
    }
  }

  Future<void> _loadAiStrategy() async {
    setState(() => _isLoadingAiStrategy = true);
    try {
      final String strategy = await AIConsultantService().getAdmissionStrategy(
        profile: widget.profile,
        university: widget.university,
      );
      if (mounted) {
        setState(() {
          _aiStrategy = strategy;
          _isLoadingAiStrategy = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAiStrategy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.commonError(e.toString()) ?? 'Ошибка: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final GrantChanceResult r = widget.svdResult;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.backgroundDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: widget.isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.analytics_rounded,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n?.svdAnalyticsTitle ?? 'СВД Аналитика',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(26),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n?.svdDataSource(r.dataYear) ??
                                  'Данные: МОН РК, ${r.dataYear}',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.help_outline,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(
                                l10n?.svdHowWeCalculateTitle ??
                                    'Как мы считаем? 📝',
                              ),
                              content: Text(
                                l10n?.svdHowWeCalculateBody ??
                                    'Алгоритм 4-х вузов анализирует ваш балл ЕНТ, выбранные профильные предметы и статистику пороговых баллов МОН РК за прошлые годы.\n\nМы учитываем конкуренцию на вашей специальности и распределяем шансы по зонам риска (от "Высокого" до "Низкого").\n\nЭто позволяет подобрать оптимальную стратегию распределения 4-х вузов при подаче документов.',
                                style: const TextStyle(height: 1.5),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(l10n?.svdUnderstood ?? 'Понятно'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withAlpha(50)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n?.svdDisclaimer ??
                                '⚠️ Расчёт рекомендательный, итоговое решение о присуждении гранта всегда остается за приёмной комиссией МОН РК.',
                            style: TextStyle(
                              fontSize: 13,
                              color: widget.isDark
                                  ? Colors.orange[200]
                                  : Colors.orange[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _riskColor.withAlpha(77),
                          width: 6,
                        ),
                        color: _riskColor.withAlpha(26),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${r.chancePercent}%',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: _riskColor,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n?.aiChancesGrant ?? 'шанс на грант',
                            style: TextStyle(
                              fontSize: 13,
                              color: widget.isDark
                                  ? Colors.white70
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _riskColor.withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            r.riskLevel.emoji,
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n?.aiChancesRisk(r.riskLevel.displayName) ??
                                'Риск: ${r.riskLevel.displayName}',
                            style: TextStyle(
                              color: _riskColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      r.verdict,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.4,
                        color: widget.isDark
                            ? Colors.white70
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      l10n?.aiChancesEntThreshold(r.entThreshold) ??
                          'Порог ЕНТ для этого направления: ${r.entThreshold} баллов',
                      style: TextStyle(
                        fontSize: 13,
                        color: widget.isDark
                            ? Colors.white38
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (r.details.isNotEmpty) ...[
                    Text(
                      l10n?.aiChancesDetails ?? 'Детали расчёта',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...r.details.map(
                      (d) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          d,
                          style: const TextStyle(fontSize: 15, height: 1.4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (r.recommendations.isNotEmpty) ...[
                    Text(
                      l10n?.detailRecommendations ?? '💡 Рекомендации',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...r.recommendations.map(
                      (rec) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                rec,
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (_aiStrategy == null && !_isLoadingAiStrategy)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _loadAiStrategy,
                        icon: const AILogoIcon(color: Colors.white),
                        label: Text(
                          l10n?.aiChancesDetailedStrategy ??
                              'Подробная AI стратегия',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  if (_isLoadingAiStrategy)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Column(
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              l10n?.detailAiThinking ??
                                  'AI формирует стратегию...',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_aiStrategy != null) ...[
                    const Divider(height: 32),
                    Row(
                      children: [
                        const AILogoIcon(color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          l10n?.detailAiStrategySubtitle ??
                              'AI Стратегия TANDAU',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    MarkdownBody(
                      data: _aiStrategy!,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: widget.isDark ? Colors.white : Colors.black87,
                        ),
                        h1: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 20,
                        ),
                        h2: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        listBullet: TextStyle(
                          color: widget.isDark
                              ? Colors.white70
                              : Colors.black54,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
