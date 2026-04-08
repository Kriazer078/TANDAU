import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/like_review_widgets.dart';
import '../utils/guest_guard.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'ai_logo_icon.dart';

class UniversityCard extends StatelessWidget {
  final String universityId;
  final String name;
  final String city;
  final String logoUrl;
  final List<String> features;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final VoidCallback? onCompareToggle;
  final bool isInComparison;

  final int likesCount;
  final int reviewsCount;
  final double averageRating;

  const UniversityCard({
    super.key,
    required this.universityId,
    required this.name,
    required this.city,
    required this.logoUrl,
    required this.features,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteToggle,
    this.onCompareToggle,
    this.isInComparison = false,
    this.likesCount = 0,
    this.reviewsCount = 0,
    this.averageRating = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // ⚡ RepaintBoundary isolates this card's paint from the list
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        // ⚡ Material(elevation:) uses hardware-accelerated shadows —
        // much cheaper than BoxShadow which triggers saveLayer per card.
        child: Material(
          color: isDark ? AppColors.cardDark : Colors.white,
          elevation: isDark ? 2 : 1.5,
          shadowColor: Colors.black26,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: logoUrl,
                        fit: BoxFit.cover,
                        memCacheWidth: 210, // 70 * 3 for retina displays
                        memCacheHeight: 210,
                        fadeInDuration:
                            Duration.zero, // ⚡ No fade = instant render
                        placeholder: (context, url) => Container(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.school,
                          size: 35,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(city, style: theme.textTheme.bodySmall),
                          ],
                        ),
                        if (features.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          // Styled Badges for Price and Grants
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: features.map((feature) {
                                final isGrant = feature.toLowerCase().contains(
                                  'грант',
                                );
                                return Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isGrant
                                        ? AppColors.accent.withValues(
                                            alpha: 0.1,
                                          )
                                        : AppColors.primary.withValues(
                                            alpha: 0.1,
                                          ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isGrant
                                          ? AppColors.accent.withValues(
                                              alpha: 0.2,
                                            )
                                          : AppColors.primary.withValues(
                                              alpha: 0.2,
                                            ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      isGrant
                                          ? AILogoIcon(
                                              size: 12,
                                              color: AppColors.accent,
                                            )
                                          : const Icon(
                                              Icons.payments,
                                              size: 12,
                                              color: AppColors.primary,
                                            ),
                                      const SizedBox(width: 4),
                                      Text(
                                        feature,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isGrant
                                              ? AppColors.accent
                                              : AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        // Stats & Rating
                        Row(
                          children: [
                            if (averageRating > 0) ...[
                              const Icon(
                                Icons.star,
                                color: AppColors.accent,
                                size: 14,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                averageRating.toStringAsFixed(1),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accent,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            LikeButton(
                              universityId: universityId,
                              initialLikesCount: likesCount,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Actions
                  Column(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (GuestGuard.check(context)) onFavoriteToggle();
                        },
                        icon: Icon(
                          isFavorite ? Icons.bookmark : Icons.bookmark_border,
                          color: isFavorite
                              ? AppColors.accent
                              : AppColors.textHint,
                        ),
                      ),
                      if (onCompareToggle != null)
                        IconButton(
                          onPressed: () {
                            if (GuestGuard.check(context)) onCompareToggle!();
                          },
                          icon: Icon(
                            isInComparison
                                ? Icons.compare_arrows
                                : Icons.compare_arrows_outlined,
                            color: isInComparison
                                ? AppColors.primary
                                : AppColors.textHint,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
