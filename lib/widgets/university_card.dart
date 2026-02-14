import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/like_review_widgets.dart';
import '../utils/guest_guard.dart'; // ⭐ Import GuestGuard

class UniversityCard extends StatelessWidget {
  final String universityId; // ⭐ Новое поле
  final String name;
  final String city;
  final String logoUrl;
  final List<String> features;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final VoidCallback? onCompareToggle;
  final bool isInComparison;

  // ⭐ Новые поля для лайков и рейтинга
  final int likesCount;
  final int reviewsCount;
  final double averageRating;

  const UniversityCard({
    super.key,
    required this.universityId, // ⭐ Обязательный параметр
    required this.name,
    required this.city,
    required this.logoUrl,
    required this.features,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteToggle,
    this.onCompareToggle,
    this.isInComparison = false,
    this.likesCount = 0, // ⭐ По умолчанию 0
    this.reviewsCount = 0, // ⭐ По умолчанию 0
    this.averageRating = 0.0, // ⭐ По умолчанию 0.0
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // University Logo
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.school,
                  size: 32,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12), // Reduced spacing to prevent overflow
              // University Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            city,
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Features
                    Wrap(
                      spacing: 8,
                      children: features
                          .where(
                            (feature) => !feature.contains('⭐'),
                          ) // Не показываем рейтинг
                          .map((feature) {
                            final isRating = feature.contains('⭐');
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  isRating ? Icons.star : Icons.check_circle,
                                  size: 14,
                                  color: isRating
                                      ? AppColors.accent
                                      : AppColors.success,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  feature.replaceAll(
                                    ' ⭐',
                                    '',
                                  ), // Remove star from text as icon is added
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                              ],
                            );
                          })
                          .toList(),
                    ),

                    // ⭐ СТАТЫ И ЛАЙК (Всегда показываем, чтобы можно было лайкнуть)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          // Рейтинг
                          if (averageRating > 0) ...[
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              averageRating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (reviewsCount > 0) ...[
                              const SizedBox(width: 2),
                              Text(
                                '($reviewsCount)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Кнопки действий В КОЛОНКУ (экономим ширину)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Favorite Button (Top)
                  IconButton(
                    onPressed: () {
                      if (GuestGuard.check(context)) {
                        onFavoriteToggle();
                      }
                    },
                    icon: Icon(
                      isFavorite ? Icons.bookmark : Icons.bookmark_border,
                      color: isFavorite
                          ? AppColors.accent
                          : AppColors.textSecondary,
                    ),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                    iconSize: 24, // Explicit size
                  ),

                  // Compare Button
                  if (onCompareToggle != null)
                    IconButton(
                      onPressed: () {
                        if (GuestGuard.check(context)) {
                          onCompareToggle!();
                        }
                      },
                      icon: Icon(
                        isInComparison
                            ? Icons.compare_arrows
                            : Icons.compare_arrows_outlined,
                        color: isInComparison
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      tooltip: 'Compare',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                      iconSize: 24,
                    ),

                  // Like Button (Bottom)
                  LikeButton(
                    universityId: universityId,
                    initialLikesCount: likesCount,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
