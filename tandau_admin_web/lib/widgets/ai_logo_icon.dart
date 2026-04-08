import 'package:flutter/material.dart';

class AILogoIcon extends StatelessWidget {
  final double size;
  final Color? color;
  final bool withGlow;

  const AILogoIcon({
    super.key,
    this.size = 24.0,
    this.color,
    this.withGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    final icon = color != null
        ? Icon(Icons.hub_rounded, size: size, color: color)
        : ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (Rect bounds) => const LinearGradient(
              colors: [
                Color(0xFF38BDF8), // AppColors.primary
                Color(0xFF6366F1), // AppColors.secondary
                Color(0xFFD946EF), // Pink
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: Icon(Icons.hub_rounded, size: size),
          );

    if (!withGlow || color != null) {
      return icon;
    }

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
            blurRadius: size * 0.8,
            spreadRadius: size * 0.1,
          ),
        ],
      ),
      child: icon,
    );
  }
}
