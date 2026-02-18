import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/review.dart';
import '../../services/review_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';

class ReviewModerationScreen extends StatefulWidget {
  const ReviewModerationScreen({super.key});

  @override
  State<ReviewModerationScreen> createState() => _ReviewModerationScreenState();
}

class _ReviewModerationScreenState extends State<ReviewModerationScreen> {
  final ReviewService _reviewService = ReviewService();
  final TextEditingController _searchController = TextEditingController();

  // Cache university names
  final Map<String, String> _universityNames = {};

  String _searchQuery = '';
  int? _filterRating; // null = all

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<String> _getUniversityName(String universityId) async {
    if (_universityNames.containsKey(universityId)) {
      return _universityNames[universityId]!;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('universities')
          .doc(universityId)
          .get();
      final String name = doc.data()?['name'] ?? 'Неизвестный';
      _universityNames[universityId] = name;
      return name;
    } catch (e) {
      return 'Неизвестный';
    }
  }

  List<Review> _applyFilters(List<Review> reviews) {
    List<Review> filtered = reviews;

    // Filter by rating
    if (_filterRating != null) {
      filtered = filtered.where((r) => r.rating == _filterRating).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((r) {
        return r.userName.toLowerCase().contains(query) ||
            r.comment.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  void _showDeleteConfirmation(Review review) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Удалить отзыв?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Автор: ${review.userName}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                review.comment,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Это действие необратимо. Рейтинг университета будет пересчитан.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Отмена',
              style: TextStyle(
                color: isDark ? Colors.white60 : AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await _reviewService.deleteReview(review.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? '✅ Отзыв удалён' : '❌ Ошибка удаления',
                    ),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            icon: const Icon(Icons.delete_rounded, size: 18),
            label: const Text('Удалить'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // SECURITY: Guard — block non-admin access
    if (!AuthService().isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Доступ запрещён')),
        body: const Center(child: Text('❌ У вас нет прав администратора')),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Модерация отзывов'),
        elevation: 0,
        actions: [
          // Rating filter chip
          PopupMenuButton<int?>(
            icon: Badge(
              isLabelVisible: _filterRating != null,
              label: Text('${_filterRating ?? ''}'),
              child: const Icon(Icons.filter_list_rounded),
            ),
            onSelected: (value) {
              setState(() {
                _filterRating = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('Все отзывы')),
              const PopupMenuDivider(),
              ...List.generate(5, (i) {
                final star = 5 - i;
                return PopupMenuItem(
                  value: star,
                  child: Row(
                    children: [
                      ...List.generate(
                        star,
                        (_) => const Icon(
                          Icons.star_rounded,
                          color: AppColors.gold,
                          size: 18,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$star',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Поиск по имени или тексту...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),

          // Active filter chip
          if (_filterRating != null)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: AppColors.gold,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text('$_filterRating звёзд'),
                    ],
                  ),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    setState(() {
                      _filterRating = null;
                    });
                  },
                  backgroundColor: AppColors.gold.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

          // Reviews list
          Expanded(
            child: StreamBuilder<List<Review>>(
              stream: _reviewService.getAllReviewsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 12),
                        Text('Ошибка: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                final allReviews = snapshot.data ?? [];
                final reviews = _applyFilters(allReviews);

                if (allReviews.isEmpty) {
                  return _buildEmptyState(
                    'Отзывов пока нет',
                    Icons.chat_bubble_outline,
                  );
                }

                if (reviews.isEmpty) {
                  return _buildEmptyState(
                    'Нет отзывов по фильтру',
                    Icons.filter_alt_off_rounded,
                  );
                }

                return Column(
                  children: [
                    // Stats bar
                    _buildStatsBar(allReviews, reviews, isDark),

                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: reviews.length,
                        itemBuilder: (context, index) {
                          return _buildReviewModCard(reviews[index], isDark);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(List<Review> all, List<Review> filtered, bool isDark) {
    final double avg = all.isEmpty
        ? 0
        : all.fold<int>(0, (s, r) => s + r.rating) / all.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildStat('Всего', '${all.length}', isDark),
          _buildDivider(isDark),
          _buildStat('Показано', '${filtered.length}', isDark),
          _buildDivider(isDark),
          _buildStat('Ср. рейтинг', avg.toStringAsFixed(1), isDark),
          _buildDivider(isDark),
          _buildStat(
            '1★',
            '${all.where((r) => r.rating == 1).length}',
            isDark,
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, bool isDark, {Color? color}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color ?? (isDark ? Colors.white : AppColors.textPrimary),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white38 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      width: 1,
      height: 28,
      color: isDark
          ? Colors.white.withValues(alpha: 0.1)
          : Colors.grey.withValues(alpha: 0.2),
    );
  }

  Widget _buildReviewModCard(Review review, bool isDark) {
    return Dismissible(
      key: Key(review.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        _showDeleteConfirmation(review);
        return false; // We handle deletion in the dialog
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_rounded, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text(
              'Удалить',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.withValues(alpha: 0.1),
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
            // Top row: user + rating + delete
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 18,
                  backgroundColor: _avatarColor(
                    review.userName,
                  ).withValues(alpha: 0.15),
                  child: Text(
                    review.userName.isNotEmpty
                        ? review.userName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: _avatarColor(review.userName),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Name + date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        _formatDate(review.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? Colors.white38
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Stars
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _ratingColor(review.rating).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: _ratingColor(review.rating),
                        size: 14,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${review.rating}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: _ratingColor(review.rating),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Delete button
                InkWell(
                  onTap: () => _showDeleteConfirmation(review),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Comment
            Text(
              review.comment,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: isDark ? Colors.white70 : AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 8),

            // University name
            FutureBuilder<String>(
              future: _getUniversityName(review.universityId),
              builder: (context, snapshot) {
                final uniName = snapshot.data ?? '...';
                return Row(
                  children: [
                    Icon(
                      Icons.school_rounded,
                      size: 14,
                      color: isDark ? Colors.white30 : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        uniName,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white30 : Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Swipe hint
                    Icon(
                      Icons.swipe_left_rounded,
                      size: 14,
                      color: isDark
                          ? Colors.white12
                          : Colors.grey.withValues(alpha: 0.3),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String text, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 48,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'только что';
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин назад';
    if (diff.inHours < 24) return '${diff.inHours} ч назад';
    if (diff.inDays < 7) return '${diff.inDays} дн назад';

    return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  Color _ratingColor(int rating) {
    switch (rating) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return AppColors.gold;
      case 4:
        return Colors.lightGreen;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _avatarColor(String name) {
    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF8B5CF6),
      const Color(0xFF3B82F6),
      const Color(0xFFEC4899),
      const Color(0xFF14B8A6),
    ];
    final int hash = name.codeUnits.fold<int>(0, (prev, c) => prev + c);
    return colors[hash % colors.length];
  }
}
