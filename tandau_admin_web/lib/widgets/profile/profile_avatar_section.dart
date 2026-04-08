import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

/// Displays the user avatar with an animated rotating gradient ring,
/// pulsing glow, and a premium glassmorphism camera badge.
class ProfileAvatarSection extends StatefulWidget {
  final UserModel user;
  final bool isDark;
  final bool isLoading;
  final VoidCallback onPickImage;

  const ProfileAvatarSection({
    super.key,
    required this.user,
    required this.isDark,
    required this.isLoading,
    required this.onPickImage,
  });

  @override
  State<ProfileAvatarSection> createState() => _ProfileAvatarSectionState();
}

class _ProfileAvatarSectionState extends State<ProfileAvatarSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _ringController;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);

    return ValueListenableBuilder<UserModel?>(
      valueListenable: AuthService().currentUser,
      builder: (context, liveUser, child) {
        final UserModel displayUser = liveUser ?? widget.user;
        final bool hasPhoto =
            displayUser.photoUrl != null && displayUser.photoUrl!.isNotEmpty;

        return Center(
          child: Column(
            children: [
              // ── Avatar with animated rotating gradient ring ──
              GestureDetector(
                onTap: widget.onPickImage,
                child: SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pulsing outer glow
                      AnimatedBuilder(
                        animation: _ringController,
                        builder: (context, child) {
                          final double pulse =
                              0.15 +
                              0.15 *
                                  math.sin(_ringController.value * 2 * math.pi);
                          return Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: pulse,
                                  ),
                                  blurRadius: 30,
                                  spreadRadius: 4,
                                ),
                                BoxShadow(
                                  color: const Color(
                                    0xFF818CF8,
                                  ).withValues(alpha: pulse * 0.6),
                                  blurRadius: 40,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      // Rotating gradient ring
                      AnimatedBuilder(
                        animation: _ringController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _ringController.value * 2 * math.pi,
                            child: Container(
                              width: 132,
                              height: 132,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: SweepGradient(
                                  colors: [
                                    AppColors.primary,
                                    Color(0xFF60A5FA),
                                    Color(0xFF818CF8),
                                    Color(0xFFA78BFA),
                                    Color(0xFFF472B6),
                                    AppColors.primary,
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      // Inner white background
                      Container(
                        width: 122,
                        height: 122,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.isDark
                              ? const Color(0xFF0F172A)
                              : Colors.white,
                        ),
                      ),
                      // Actual avatar image / initials
                      Container(
                        width: 116,
                        height: 116,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.isDark
                              ? const Color(0xFF1E293B)
                              : Colors.grey.shade50,
                          image: hasPhoto && !widget.isLoading
                              ? DecorationImage(
                                  image: NetworkImage(displayUser.photoUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: widget.isLoading
                            ? Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.primary,
                                ),
                              )
                            : !hasPhoto
                            ? Center(
                                child: Text(
                                  displayUser.name.isNotEmpty
                                      ? displayUser.name[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontSize: 44,
                                    fontWeight: FontWeight.w800,
                                    foreground: Paint()
                                      ..shader =
                                          const LinearGradient(
                                            colors: [
                                              AppColors.primary,
                                              Color(0xFF818CF8),
                                            ],
                                          ).createShader(
                                            const Rect.fromLTWH(0, 0, 50, 50),
                                          ),
                                  ),
                                ),
                              )
                            : null,
                      ),
                      // Camera badge with glassmorphism
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: widget.isDark
                                  ? const Color(0xFF0F172A)
                                  : Colors.white,
                              width: 3.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF6366F1,
                                ).withValues(alpha: 0.5),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // User name
              Text(
                displayUser.name.isNotEmpty
                    ? displayUser.name
                    : (l10n?.profileChangePhoto ?? 'Ваш профиль'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: widget.isDark ? Colors.white : AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              // "Change photo" text
              GestureDetector(
                onTap: widget.onPickImage,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.edit_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n?.profileChangePhoto ?? 'Изменить фото',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
