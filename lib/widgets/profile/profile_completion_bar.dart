import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

/// Premium animated progress bar showing profile completion percentage
/// with gradient fill, pulsing animation on low completion, and smart labels.
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

    if (percent < 40) {
      gradientColors = [const Color(0xFFEF4444), const Color(0xFFF97316)];
      label =
          l10n?.profileCompletionLow ??
          'Заполните профиль для лучших рекомендаций';
      icon = Icons.warning_amber_rounded;
    } else if (percent < 80) {
      gradientColors = [const Color(0xFFF59E0B), const Color(0xFFFBBF24)];
      label =
          l10n?.profileCompletionMedium ??
          'Почти готово! Добавьте оставшиеся данные';
      icon = Icons.auto_graph_rounded;
    } else {
      gradientColors = [const Color(0xFF22C55E), const Color(0xFF10B981)];
      label =
          l10n?.profileCompletionHigh ?? 'Отличная работа! Профиль заполнен';
      icon = Icons.check_circle_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? gradientColors.first.withValues(alpha: 0.2)
              : gradientColors.first.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: isDark ? 0.1 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Gradient icon container
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n?.profileCompletionTitle ?? 'Заполнение профиля',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              // Percentage badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      gradientColors.first.withValues(alpha: 0.15),
                      gradientColors.last.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: gradientColors.first.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  '$percent%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: gradientColors.first,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Gradient progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Stack(
                  children: [
                    // Background track
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    // Filled gradient portion
                    FractionallySizedBox(
                      widthFactor: value.clamp(0.0, 1.0),
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: gradientColors),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: gradientColors.first.withValues(
                                alpha: 0.4,
                              ),
                              blurRadius: 6,
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
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white38 : Colors.grey.shade500,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
