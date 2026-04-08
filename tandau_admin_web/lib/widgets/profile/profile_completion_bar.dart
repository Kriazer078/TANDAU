import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

/// Premium animated progress bar showing profile completion percentage
/// with gradient fill, stepwise indicators, and smart adaptive labels.
class ProfileCompletionBar extends StatelessWidget {
  final double progress;
  final bool isDark;

  const ProfileCompletionBar({
    super.key,
    required this.progress,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final int percent = (progress * 100).round();
    final AppLocalizations? l10n = AppLocalizations.of(context);

    final List<Color> gradientColors;
    final String label;
    final IconData icon;
    final String emoji;

    if (percent < 40) {
      gradientColors = [const Color(0xFFEF4444), const Color(0xFFF97316)];
      label =
          l10n?.profileCompletionLow ??
          'Заполните профиль для лучших рекомендаций';
      icon = Icons.warning_amber_rounded;
      emoji = '🔴';
    } else if (percent < 80) {
      gradientColors = [const Color(0xFFF59E0B), const Color(0xFFFBBF24)];
      label =
          l10n?.profileCompletionMedium ??
          'Почти готово! Добавьте оставшиеся данные';
      icon = Icons.auto_graph_rounded;
      emoji = '🟡';
    } else {
      gradientColors = [const Color(0xFF22C55E), const Color(0xFF10B981)];
      label =
          l10n?.profileCompletionHigh ?? 'Отличная работа! Профиль заполнен';
      icon = Icons.check_circle_rounded;
      emoji = '🟢';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? gradientColors.first.withValues(alpha: 0.25)
              : gradientColors.first.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: isDark ? 0.12 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Gradient icon container with subtle animation
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors.first.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.profileCompletionTitle ?? 'Заполнение профиля',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$emoji $percent% завершено',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: gradientColors.first,
                      ),
                    ),
                  ],
                ),
              ),
              // Percentage badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      gradientColors.first.withValues(alpha: 0.18),
                      gradientColors.last.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: gradientColors.first.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  '$percent%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: gradientColors.first,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Gradient progress bar with rounded ends
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Stack(
                  children: [
                    // Background track with subtle pattern
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    // Filled gradient portion with shimmer
                    FractionallySizedBox(
                      widthFactor: value.clamp(0.0, 1.0),
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: gradientColors),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: gradientColors.first.withValues(
                                alpha: 0.45,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Smart adaptive message
          Row(
            children: [
              Icon(
                percent >= 80
                    ? Icons.thumb_up_alt_rounded
                    : Icons.lightbulb_outline_rounded,
                size: 14,
                color: isDark ? Colors.white30 : Colors.grey.shade400,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white38 : Colors.grey.shade500,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
