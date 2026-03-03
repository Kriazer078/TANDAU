import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

/// Displays the user avatar with a premium animated gradient ring
/// and an elegant "Change photo" button with glassmorphism.
class ProfileAvatarSection extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);

    return ValueListenableBuilder<UserModel?>(
      valueListenable: AuthService().currentUser,
      builder: (context, liveUser, child) {
        final UserModel displayUser = liveUser ?? user;
        final bool hasPhoto =
            displayUser.photoUrl != null && displayUser.photoUrl!.isNotEmpty;

        return Center(
          child: Column(
            children: [
              // ── Avatar with animated gradient ring ──
              GestureDetector(
                onTap: onPickImage,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer glow
                    Container(
                      width: 136,
                      height: 136,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.3),
                            const Color(0xFF818CF8).withValues(alpha: 0.2),
                            AppColors.primary.withValues(alpha: 0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    // Gradient ring
                    Container(
                      width: 128,
                      height: 128,
                      padding: const EdgeInsets.all(3.5),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            Color(0xFF60A5FA),
                            Color(0xFF818CF8),
                            Color(0xFFA78BFA),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              isDark ? const Color(0xFF0F172A) : Colors.white,
                          border: Border.all(
                            color:
                                isDark ? const Color(0xFF0F172A) : Colors.white,
                            width: 3,
                          ),
                          image: hasPhoto && !isLoading
                              ? DecorationImage(
                                  image: NetworkImage(displayUser.photoUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: isLoading
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
                                        fontSize: 42,
                                        fontWeight: FontWeight.w800,
                                        color: isDark
                                            ? Colors.white
                                            : AppColors.primary,
                                      ),
                                    ),
                                  )
                                : null,
                      ),
                    ),
                    // Camera badge
                    Positioned(
                      bottom: 4,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, Color(0xFF818CF8)],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                isDark ? const Color(0xFF0F172A) : Colors.white,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // "Change photo" text
              GestureDetector(
                onTap: onPickImage,
                child: Text(
                  l10n?.profileChangePhoto ?? 'Изменить фото',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
