import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/deadline_service.dart';
import '../theme/app_colors.dart';

/// Баннер с ближайшими дедлайнами поступления
/// Показывает обратный отсчёт до важных дат в современном premium-дизайне
class DeadlineBanner extends StatelessWidget {
  const DeadlineBanner({super.key});

  // ⚡ Cache service reference as static — avoid repeated factory calls in build
  static final DeadlineService _deadlineService = DeadlineService();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final upcoming = _deadlineService.getDeadlinesWithin(days: 90);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (upcoming.isEmpty) return const SizedBox.shrink();

    final next = upcoming.first;

    // Define premium gradients based on urgency
    final List<Color> gradientColors = next.isSoon || next.isUrgent
        ? [
            const Color(0xFFFF416C),
            const Color(0xFFFF4B2B),
          ] // Vibrant Red/Orange
        : next.daysLeft < 30
        ? [
            const Color(0xFFF7971E),
            const Color(0xFFFFD200),
          ] // Energetic Orange/Yellow
        : [
            AppColors.primary,
            AppColors.secondary,
          ]; // Brand Electric Blue/Indigo

    final shadowColor = gradientColors.first.withValues(alpha: 0.4);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 24,
            offset: const Offset(0, 10),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => _showAllDeadlines(context, _deadlineService, isDark),
          highlightColor: Colors.white.withValues(alpha: 0.1),
          splashColor: Colors.white.withValues(alpha: 0.15),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                // Decorative blurred background elements
                Positioned(
                  top: -40,
                  right: -20,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -30,
                  left: 20,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                // Main content with light glassmorphism backdrop
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Glassy icon container
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              Colors.white,
                              Colors.white.withValues(alpha: 0.85),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: Icon(next.icon, size: 32, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Text Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              next.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                                letterSpacing: -0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              next.formattedDate,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Right-aligned countdown
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${next.daysLeft}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 26,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n?.deadlineDays ?? 'дней',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
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
      backgroundColor:
          Colors.transparent, // Background transparent for floating UI
      isScrollControlled: true,
      builder: (context) => _DeadlinesBottomSheet(
        deadlines: allDeadlines,
        isDark: isDark,
        l10n: AppLocalizations.of(context),
      ),
    );
  }
}

class _DeadlinesBottomSheet extends StatelessWidget {
  final List<AdmissionDeadline> deadlines;
  final bool isDark;
  final AppLocalizations? l10n;

  const _DeadlinesBottomSheet({
    required this.deadlines,
    required this.isDark,
    this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Floating drag handle
            Center(
              child: Container(
                width: 48,
                height: 5,
                margin: const EdgeInsets.only(bottom: 24, top: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: Color(0xFF38BDF8),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    l10n?.deadlineTitle ?? 'Дедлайны поступления\n2026',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Sub-title
            Text(
              l10n?.deadlineImportantDates ?? 'Важные даты',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.6)
                    : AppColors.textSecondary,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 12),

            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: deadlines.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _buildDeadlineCard(deadlines[index]);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDeadlineCard(AdmissionDeadline deadline) {
    final Color statusColor;
    final Color badgeBgColor;
    if (deadline.isPast) {
      statusColor = isDark ? Colors.grey.shade600 : Colors.grey.shade400;
      badgeBgColor = statusColor.withValues(alpha: 0.15);
    } else if (deadline.isSoon || deadline.isUrgent) {
      statusColor = const Color(0xFFEF4444); // Red
      badgeBgColor = statusColor.withValues(alpha: 0.15);
    } else {
      statusColor = const Color(0xFF6366F1); // Indigo
      badgeBgColor = statusColor.withValues(alpha: 0.15);
    }

    final cardBgColor = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFF8FAFC);
    final iconBgColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        children: [
          // Styled leading icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: deadline.iconGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: Icon(deadline.icon, size: 26, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Texts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deadline.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    letterSpacing: -0.3,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  deadline.formattedDate,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.6)
                        : AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Smart Status Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: badgeBgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Text(
              deadline.countdownText,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
