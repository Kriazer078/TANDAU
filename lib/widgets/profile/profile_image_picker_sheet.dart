import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/app_colors.dart';
import '../../services/auth_service.dart';

/// Helper class for image-picker bottom-sheet and upload logic.
class ProfileImagePickerHelper {
  ProfileImagePickerHelper._();

  /// Show a modal bottom sheet to choose Camera or Gallery.
  static void showPicker({
    required BuildContext context,
    required ValueChanged<bool> onLoadingChanged,
    required VoidCallback onPhotoUpdated,
    required void Function(String message) onError,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Выберите источник',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildPickerOption(
                      icon: Icons.photo_library_rounded,
                      label: 'Галерея',
                      color: const Color(0xFF3B82F6),
                      isDark: isDark,
                      onTap: () {
                        Navigator.pop(ctx);
                        _handleImageSelection(
                          source: ImageSource.gallery,
                          context: context,
                          onLoadingChanged: onLoadingChanged,
                          onPhotoUpdated: onPhotoUpdated,
                          onError: onError,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPickerOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'Камера',
                      color: const Color(0xFF8B5CF6),
                      isDark: isDark,
                      onTap: () {
                        Navigator.pop(ctx);
                        _handleImageSelection(
                          source: ImageSource.camera,
                          context: context,
                          onLoadingChanged: onLoadingChanged,
                          onPhotoUpdated: onPhotoUpdated,
                          onError: onError,
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildPickerOption({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _handleImageSelection({
    required ImageSource source,
    required BuildContext context,
    required ValueChanged<bool> onLoadingChanged,
    required VoidCallback onPhotoUpdated,
    required void Function(String message) onError,
  }) async {
    final ImagePicker picker = ImagePicker();

    try {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image == null) return;

      onLoadingChanged(true);

      final File file = File(image.path);
      final String? downloadUrl = await AuthService().uploadProfilePhoto(file);

      if (downloadUrl != null) {
        final bool success = await AuthService().updateProfile(
          photoUrl: downloadUrl,
        );
        if (success) {
          onPhotoUpdated();
        } else {
          throw Exception('Ошибка обновления ссылки в профиле');
        }
      } else {
        throw Exception('Ошибка загрузки в облако');
      }
    } catch (e) {
      debugPrint('Photo error: $e');
      onError('Ошибка: ${e.toString().replaceAll('Exception:', '')}');
    } finally {
      onLoadingChanged(false);
    }
  }
}
