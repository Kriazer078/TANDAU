import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// A premium styled section header with gradient icon background and title.
class ProfileSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDark;

  const ProfileSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : AppColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.2),
                  const Color(0xFF818CF8).withValues(alpha: 0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: isDark
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.grey.shade300,
          ),
        ],
      ),
    );
  }
}
