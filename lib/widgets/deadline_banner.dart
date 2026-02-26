import 'package:flutter/material.dart';

import '../services/deadline_service.dart';
import '../theme/app_colors.dart';

/// Баннер с ближайшими дедлайнами поступления
/// Показывает обратный отсчёт до важных дат
class DeadlineBanner extends StatelessWidget {
  const DeadlineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final deadlineService = DeadlineService();
    final upcoming = deadlineService.getDeadlinesWithin(days: 90);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (upcoming.isEmpty) return const SizedBox.shrink();

    final next = upcoming.first;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: next.isSoon || next.isUrgent
              ? [
                  const Color(0xFFFF512F),
                  const Color(0xFFDD2476),
                ] // Modern red/orange gradient
              : next.daysLeft < 30
              ? [
                  const Color(0xFFF6D365),
                  const Color(0xFFFDA085),
                ] // Modern orange/yellow gradient
              : [
                  const Color(0xFF8B5DF6),
                  const Color(0xFF7239EA),
                ], // Beautiful vibrant purple
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color:
                (next.isSoon
                        ? const Color(0xFFDD2476)
                        : const Color(0xFF7239EA))
                    .withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _showAllDeadlines(context, deadlineService, isDark),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      next.icon,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        next.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        next.formattedDate,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Countdown
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${next.daysLeft}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 28,
                          height: 1.1,
                        ),
                      ),
                      const Text(
                        'дней',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAllDeadlines(
    BuildContext context,
    DeadlineService service,
    bool isDark,
  ) {
    final allDeadlines = service.getUpcomingDeadlines();

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '📅 Дедлайны поступления 2026',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...allDeadlines.map((d) => _buildDeadlineRow(d, isDark)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildDeadlineRow(AdmissionDeadline deadline, bool isDark) {
    final Color statusColor;
    if (deadline.isPast) {
      statusColor = Colors.grey;
    } else if (deadline.isSoon || deadline.isUrgent) {
      statusColor = const Color(0xFFEF4444);
    } else if (deadline.daysLeft < 30) {
      statusColor = const Color(0xFFF59E0B);
    } else {
      statusColor = const Color(0xFF6366F1);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(deadline.icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deadline.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  deadline.formattedDate,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              deadline.countdownText,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
