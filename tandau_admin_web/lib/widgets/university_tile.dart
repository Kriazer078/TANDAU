import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/university.dart';
import '../theme/app_colors.dart';

/// Reusable university list tile used in pickers and lists.
class UniversityTile extends StatelessWidget {
  final University university;
  final bool isDark;
  final bool isSelected;
  final Widget? trailing;
  final VoidCallback onTap;

  const UniversityTile({
    super.key,
    required this.university,
    required this.isDark,
    this.isSelected = false,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : (isDark ? AppColors.cardDark : Colors.white),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? Colors.white10 : Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.1),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: university.logoUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: university.logoUrl,
                            fit: BoxFit.cover,
                            memCacheWidth: 150,
                            memCacheHeight: 150,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            errorWidget: (context, url, error) => Icon(
                              Icons.school,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.primary,
                            ),
                          )
                        : Icon(
                            Icons.school,
                            color: isSelected
                                ? Colors.white
                                : AppColors.primary,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          university.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          university.city,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? Colors.white54
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
