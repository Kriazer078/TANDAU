import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';

/// Displays the user avatar with a gradient ring and a "Change photo" button.
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
    return ValueListenableBuilder<UserModel?>(
      valueListenable: AuthService().currentUser,
      builder: (context, liveUser, child) {
        final UserModel displayUser = liveUser ?? user;
        final bool hasPhoto =
            displayUser.photoUrl != null && displayUser.photoUrl!.isNotEmpty;

        return Center(
          child: Column(
            children: [
              // Avatar with gradient ring
              GestureDetector(
                onTap: onPickImage,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.primary,
                        Color(0xFF60A5FA),
                        Color(0xFF818CF8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      border: Border.all(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
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
                              strokeWidth: 3,
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
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.primary,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // "Change photo" text
              GestureDetector(
                onTap: onPickImage,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Изменить фото',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
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
