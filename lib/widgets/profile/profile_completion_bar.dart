import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

/// Animated progress bar showing profile completion percentage.
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
    final Color barColor;
    final String label;
    final AppLocalizations? l10n = AppLocalizations.of(context);

    if (percent < 40) {
      barColor = Colors.red.shade400;
      label =
          l10n?.profileCompletionLow ??
          'Заполните профиль для лучших рекомендаций';
    } else if (percent < 80) {
      barColor = Colors.amber.shade600;
      label =
          l10n?.profileCompletionMedium ??
          'Почти готово! Добавьте оставшиеся данные';
    } else {
      barColor = const Color(0xFF22C55E);
      label =
          l10n?.profileCompletionHigh ?? 'Отличная работа! Профиль заполнен';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.grey.shade100,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    percent == 100
                        ? Icons.check_circle_rounded
                        : Icons.auto_graph_rounded,
                    color: barColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n?.profileCompletionTitle ?? 'Заполнение профиля',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: barColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$percent%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: barColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(barColor),
                  minHeight: 6,
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white38 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
