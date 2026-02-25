import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart';
import '../models/review.dart';
import '../services/review_service.dart';
import '../services/auth_service.dart';
import '../utils/guest_guard.dart';
import '../l10n/app_localizations.dart';
import 'like_review_widgets.dart';

/// Reviews tab for university detail screen.
class UniversityReviewsTab extends StatelessWidget {
  final String universityId;
  final bool isDark;

  const UniversityReviewsTab({
    super.key,
    required this.universityId,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final ReviewService reviewService = ReviewService();
    final AuthService authService = AuthService();
    final AppLocalizations? l10n = AppLocalizations.of(context);

    return Column(
      children: [
        // ── "Leave Review" button ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF6366F1)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                if (GuestGuard.check(context)) {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => AddReviewDialog(universityId: universityId),
                  );
                }
              },
              icon: const Icon(
                Icons.edit_rounded,
                size: 20,
                color: Colors.white,
              ),
              label: Text(
                l10n?.detailLeaveReviewBtn ?? 'Leave a Review',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),

        // ── Reviews list ──
        Expanded(
          child: StreamBuilder<List<Review>>(
            stream: reviewService.getUniversityReviewsStream(universityId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final List<Review> reviews = snapshot.data!;
              if (reviews.isEmpty) {
                return _buildEmptyReviews(l10n);
              }

              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _buildRatingSummary(reviews, l10n),
                  const SizedBox(height: 16),
                  ...reviews.map(
                    (r) => _buildReviewCard(
                      r,
                      authService,
                      ReviewService(),
                      l10n,
                      context,
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Empty state ──
  Widget _buildEmptyReviews(AppLocalizations? l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.rate_review_outlined,
                size: 48,
                color: AppColors.gold.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n?.detailNoReviewsYet ?? 'No reviews yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n?.detailBeFirstReviewer ?? 'Be the first to leave a review!',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white38 : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Rating summary (Google Play style) ──
  Widget _buildRatingSummary(List<Review> reviews, AppLocalizations? l10n) {
    final int total = reviews.length;
    final double avg = reviews.fold<int>(0, (sum, r) => sum + r.rating) / total;

    final Map<int, int> counts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final Review r in reviews) {
      counts[r.rating] = (counts[r.rating] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : AppColors.border.withValues(alpha: 0.5),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Column(
              children: [
                Text(
                  avg.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    return Icon(
                      i < avg.round()
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: AppColors.gold,
                      size: 16,
                    );
                  }),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n?.detailReviewsCount(total) ?? '$total reviews',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: List.generate(5, (i) {
                final int star = 5 - i;
                final int count = counts[star] ?? 0;
                final double fraction = total > 0 ? count / total : 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        '$star',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white54
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: fraction,
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.grey.withValues(alpha: 0.15),
                            color: AppColors.gold,
                            minHeight: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ── Single review card ──
  Widget _buildReviewCard(
    Review r,
    AuthService authService,
    ReviewService reviewService,
    AppLocalizations? l10n,
    BuildContext context,
  ) {
    final String dateStr = _formatReviewDate(r.createdAt);
    final Color avatarColor = _avatarColor(r.userName);
    final String? currentUserId = authService.currentUser.value?.uid;
    final bool isHelpfulByMe = r.helpfulBy.contains(currentUserId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : AppColors.border.withValues(alpha: 0.5),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User row
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: avatarColor.withValues(alpha: 0.15),
                child: Text(
                  r.userName.isNotEmpty ? r.userName[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: avatarColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.userName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.white38
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...List.generate(r.rating, (i) {
                      return const Icon(
                        Icons.star_rounded,
                        color: AppColors.gold,
                        size: 14,
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Comment text
          Text(
            r.comment,
            style: TextStyle(
              fontSize: 14,
              height: 1.55,
              color: isDark ? Colors.white70 : AppColors.textPrimary,
            ),
          ),
          // Edited badge
          if (r.updatedAt != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.edit_outlined,
                  size: 12,
                  color: isDark ? Colors.white24 : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  l10n?.reviewEditedLabel ?? 'edited',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.white24 : Colors.grey,
                  ),
                ),
              ],
            ),
          ],

          // Photos
          if (r.photoUrls != null && r.photoUrls!.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: r.photoUrls!.length,
                itemBuilder: (context, idx) {
                  return Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.black12,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: r.photoUrls![idx],
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error, color: Colors.grey),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Helpful Button & Count
          Row(
            children: [
              InkWell(
                onTap: () async {
                  if (currentUserId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n?.reviewAuthRequiredMsg ??
                              'Please authenticate to rate',
                        ),
                      ),
                    );
                    return;
                  }
                  await reviewService.toggleHelpful(r.id);
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isHelpfulByMe
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : (isDark
                              ? Colors.white10
                              : Colors.grey.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isHelpfulByMe
                            ? Icons.thumb_up
                            : Icons.thumb_up_alt_outlined,
                        size: 16,
                        color: isHelpfulByMe
                            ? AppColors.primary
                            : (isDark ? Colors.white54 : Colors.grey),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n?.reviewHelpful(
                              r.helpfulCount > 0 ? '(${r.helpfulCount})' : '',
                            ) ??
                            'Полезно ${r.helpfulCount > 0 ? '(${r.helpfulCount})' : ''}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isHelpfulByMe
                              ? AppColors.primary
                              : (isDark ? Colors.white54 : Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Admin Reply Section
          if (r.adminReply != null && r.adminReply!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.shield_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        r.replierName ??
                            l10n?.reviewOfficialReply ??
                            'Официальный ответ',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      if (r.repliedAt != null)
                        Text(
                          _formatReviewDate(r.repliedAt!),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? Colors.white38
                                : AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    r.adminReply!,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: isDark ? Colors.white70 : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatReviewDate(DateTime date) {
    final DateTime now = DateTime.now();
    final Duration diff = now.difference(date);

    if (diff.inMinutes < 1) return 'только что';
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин назад';
    if (diff.inHours < 24) return '${diff.inHours} ч назад';
    if (diff.inDays < 7) return '${diff.inDays} дн назад';

    final List<String> months = [
      'янв',
      'фев',
      'мар',
      'апр',
      'май',
      'июн',
      'июл',
      'авг',
      'сен',
      'окт',
      'ноя',
      'дек',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Color _avatarColor(String name) {
    const List<Color> colors = [
      Color(0xFF6366F1),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
      Color(0xFF8B5CF6),
      Color(0xFF3B82F6),
      Color(0xFFEC4899),
      Color(0xFF14B8A6),
    ];
    final int hash = name.codeUnits.fold<int>(0, (prev, c) => prev + c);
    return colors[hash % colors.length];
  }
}
