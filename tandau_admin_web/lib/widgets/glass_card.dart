import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GlassCard extends StatefulWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final bool animateOnHover;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 20.0,
    this.animateOnHover = true,
    this.onTap,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Base colors matching the current theme mode
    final surfaceColor = isDark ? AppColors.cardDark : Colors.white;
    final borderColor = isDark 
        ? Colors.white.withValues(alpha: _isHovered ? 0.12 : 0.06) 
        : AppColors.cardBorder.withValues(alpha: _isHovered ? 1.0 : 0.5);
    final glowColor = isDark 
        ? Colors.black.withValues(alpha: _isHovered ? 0.4 : 0.2)
        : Colors.black.withValues(alpha: _isHovered ? 0.08 : 0.04);

    return MouseRegion(
      onEnter: widget.animateOnHover ? (_) => setState(() => _isHovered = true) : null,
      onExit: widget.animateOnHover ? (_) => setState(() => _isHovered = false) : null,
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0.0, _isHovered && widget.animateOnHover ? -4.0 : 0.0, 0.0),
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            color: surfaceColor.withValues(alpha: isDark ? 0.6 : 0.8),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: glowColor,
                blurRadius: _isHovered ? 24 : 16,
                spreadRadius: _isHovered ? 2 : 0,
                offset: Offset(0, _isHovered ? 8 : 4),
              ),
              if (_isHovered && isDark)
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: widget.padding,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
