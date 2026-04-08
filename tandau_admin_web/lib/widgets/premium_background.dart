import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PremiumBackground extends StatelessWidget {
  final bool isDark;

  const PremiumBackground({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Using const colors where possible to avoid rebuilds
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : AppColors.background,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF1E293B)]
              : [
                  // Lighter, optimized gradient
                  const Color(0xFFE3F2FD), // Light Blue 50
                  Colors.white,
                  const Color(0xFFF3E5F5), // Light Purple 50
                ],
        ),
      ),
    );
  }
}
