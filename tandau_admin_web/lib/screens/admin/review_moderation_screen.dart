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

  // 🔲 Batch selection
  final Set<String> _selectedIds = {};
  bool _isBatchProcessing = false;

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

  void _showReplyDialog(Review review) {
    final TextEditingController replyController = TextEditingController(
      text: review.adminReply ?? '',
    );
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                const Icon(Icons.reply_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text('Ответить'),
              ],
            ),
            content: TextField(
              controller: replyController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Введите ответ от администрации...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (replyController.text.trim().isEmpty) return;
                        setState(() => isSubmitting = true);
                        final success = await _reviewService.addReply(
                          reviewId: review.id,
                          replyText: replyController.text.trim(),
                        );
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success ? 'Ответ добавлен' : 'Ошибка',
                              ),
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Сохранить'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // SECURITY: Guard — block non-admin access
    if (!AuthService().hasAdminAccess) {
      return const Center(child: Text('❌ У вас нет прав доступа к этой странице'));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Search bar + filter
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                  decoration: InputDecoration(
                    hintText: 'Поиск по имени или тексту...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
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
              const SizedBox(width: 4),
              PopupMenuButton<int?>(
                icon: Badge(
                  isLabelVisible: _filterRating != null,
                  label: Text('${_filterRating ?? ''}'),
                  child: const Icon(Icons.filter_list_rounded),
                ),
                onSelected: (value) {
                  setState(() => _filterRating = value);
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
                  setState(() => _filterRating = null);
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

                  // 🔲 Batch action bar
                  if (_selectedIds.isNotEmpty)
                    _buildBatchBar(isDark, reviews),

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

  /// 🔲 Batch action bar — appears when reviews are selected
  Widget _buildBatchBar(bool isDark, List<Review> reviews) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            const Color(0xFF6366F1).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Select All / Deselect
          InkWell(
            onTap: () {
              setState(() {
                if (_selectedIds.length == reviews.length) {
                  _selectedIds.clear();
                } else {
                  _selectedIds.addAll(reviews.map((r) => r.id));
                }
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                _selectedIds.length == reviews.length
                    ? Icons.deselect_rounded
                    : Icons.select_all_rounded,
                size: 20,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Выбрано: ${_selectedIds.length}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const Spacer(),

          // Batch Reply (approve)
          _batchButton(
            icon: Icons.reply_all_rounded,
            label: 'Ответить всем',
            color: AppColors.primary,
            onTap: _isBatchProcessing ? null : () => _batchReply(reviews),
          ),
          const SizedBox(width: 8),

          // Batch Delete
          if (AuthService().hasAdminAccess)
            _batchButton(
              icon: Icons.delete_sweep_rounded,
              label: 'Удалить все',
              color: Colors.red,
              onTap: _isBatchProcessing ? null : () => _batchDelete(),
            ),
          const SizedBox(width: 8),

          // Clear selection
          InkWell(
            onTap: () => setState(() => _selectedIds.clear()),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close_rounded, size: 18, color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _batchButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isBatchProcessing)
              SizedBox(
                width: 14, height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            else
              Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  /// 📝 Batch reply to all selected reviews
  Future<void> _batchReply(List<Review> reviews) async {
    final TextEditingController replyCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFF1E293B),
        title: Row(
          children: [
            const Icon(Icons.reply_all_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('Ответить на ${_selectedIds.length} отзывов'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Один ответ будет добавлен ко всем выбранным отзывам.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: replyCtrl,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Введите ответ от администрации...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Отправить'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || replyCtrl.text.trim().isEmpty) return;

    setState(() => _isBatchProcessing = true);

    int success = 0;
    int failed = 0;
    final replyText = replyCtrl.text.trim();

    for (final id in _selectedIds.toList()) {
      try {
        final result = await _reviewService.addReply(reviewId: id, replyText: replyText);
        result ? success++ : failed++;
      } catch (_) {
        failed++;
      }
    }

    if (mounted) {
      setState(() {
        _isBatchProcessing = false;
        _selectedIds.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Ответ добавлен: $success | ❌ Ошибок: $failed'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: failed == 0 ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  /// 🗑️ Batch delete all selected reviews
  Future<void> _batchDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFF1E293B),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_sweep_rounded, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Text('Удалить выбранные?', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          'Будет удалено ${_selectedIds.length} отзывов. Это действие необратимо. Рейтинги университетов будут пересчитаны.',
          style: TextStyle(color: Colors.red.withValues(alpha: 0.8), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_rounded, size: 16),
            label: const Text('Удалить все'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isBatchProcessing = true);

    int success = 0;
    int failed = 0;

    for (final id in _selectedIds.toList()) {
      try {
        final result = await _reviewService.deleteReview(id);
        result ? success++ : failed++;
      } catch (_) {
        failed++;
      }
    }

    if (mounted) {
      setState(() {
        _isBatchProcessing = false;
        _selectedIds.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🗑️ Удалено: $success | ❌ Ошибок: $failed'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: failed == 0 ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  Widget _buildReviewModCard(Review review, bool isDark) {
    final bool isSelected = _selectedIds.contains(review.id);
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
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.4)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.withValues(alpha: 0.1)),
            width: isSelected ? 1.5 : 1.0,
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
            // Top row: checkbox + user + rating + delete
            Row(
              children: [
                // Checkbox
                SizedBox(
                  width: 32,
                  height: 32,
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedIds.add(review.id);
                        } else {
                          _selectedIds.remove(review.id);
                        }
                      });
                    },
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                ),
                const SizedBox(width: 4),
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

                // Reply button
                InkWell(
                  onTap: () => _showReplyDialog(review),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.reply_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
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

            // Helpful & Media Tags
            if ((review.photoUrls?.isNotEmpty ?? false) ||
                review.helpfulCount > 0 ||
                (review.adminReply?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (review.photoUrls?.isNotEmpty ?? false)
                    Text(
                      '📷 Фото: ${review.photoUrls!.length}',
                      style: const TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  if (review.helpfulCount > 0)
                    Text(
                      '🔥 Полезно: ${review.helpfulCount}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                      ),
                    ),
                  if (review.adminReply?.isNotEmpty ?? false)
                    const Text(
                      '✅ Ответ дан',
                      style: TextStyle(fontSize: 12, color: Colors.green),
                    ),
                ],
              ),
            ],

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
