import 'package:flutter/material.dart';
import '../services/like_service.dart';
import '../services/review_service.dart';
import '../utils/guest_guard.dart'; // ⭐ Import GuestGuard

/// Пример виджета кнопки лайка с анимацией
class LikeButton extends StatefulWidget {
  final String universityId;
  final int initialLikesCount;

  const LikeButton({
    super.key,
    required this.universityId,
    this.initialLikesCount = 0,
  });

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton>
    with SingleTickerProviderStateMixin {
  final LikeService _likeService = LikeService();
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  bool _isLiked = false;
  int _likesCount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.initialLikesCount;
    _checkLikeStatus();

    // Анимация при нажатии
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkLikeStatus() async {
    final liked = await _likeService.isLiked(widget.universityId);
    if (mounted) {
      setState(() {
        _isLiked = liked;
      });
    }
  }

  Future<void> _handleLike() async {
    // ⭐ Проверка на гостя
    if (!GuestGuard.check(context)) return;

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    // Оптимистичное обновление UI
    final wasLiked = _isLiked;
    setState(() {
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
    });

    // Анимация
    _controller.forward().then((_) => _controller.reverse());

    // Реальное обновление
    final success = await _likeService.toggleLike(widget.universityId);

    if (!success && mounted) {
      // Откатываем при ошибке
      setState(() {
        _isLiked = wasLiked;
        _likesCount += _isLiked ? 1 : -1;
      });

      // Не показываем ошибку пользователю при частых нажатиях,
      // просто возвращаем состояние
      debugPrint('Error toggling like (possibly rapid clicks)');
    }

    // Небольшая задержка перед разблокировкой кнопки,
    // чтобы предотвратить спам-клики
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Кнопка лайка с анимацией
        ScaleTransition(
          scale: _scaleAnimation,
          child: IconButton(
            onPressed: _handleLike, // ⭐ Вернул обработчик
            constraints: const BoxConstraints(), // Compact
            padding: const EdgeInsets.all(4), // Reduced padding
            icon: Icon(
              _isLiked ? Icons.favorite : Icons.favorite_border,
              color: _isLiked ? Colors.red : Colors.grey,
            ),
            iconSize: 28, // Keep size visible but compact container
          ),
        ),

        // Счетчик
        Text(
          _likesCount > 0 ? _likesCount.toString() : '',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

/// Виджет отображения рейтинга со звездами
class RatingDisplay extends StatelessWidget {
  final double rating;
  final int reviewsCount;
  final bool showCount;

  const RatingDisplay({
    super.key,
    required this.rating,
    this.reviewsCount = 0,
    this.showCount = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Звезды
        ...List.generate(5, (index) {
          final filled = index < rating.floor();
          final partial = index < rating && index >= rating.floor();

          return Icon(
            filled
                ? Icons.star
                : (partial ? Icons.star_half : Icons.star_border),
            color: Colors.amber,
            size: 20,
          );
        }),

        const SizedBox(width: 8),

        // Число
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),

        // Количество отзывов
        if (showCount && reviewsCount > 0) ...[
          const SizedBox(width: 4),
          Text(
            '($reviewsCount)',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ],
    );
  }
}

/// Пример диалога добавления отзыва
class AddReviewDialog extends StatefulWidget {
  final String universityId;

  const AddReviewDialog({super.key, required this.universityId});

  @override
  State<AddReviewDialog> createState() => _AddReviewDialogState();
}

class _AddReviewDialogState extends State<AddReviewDialog> {
  final ReviewService _reviewService = ReviewService();
  final TextEditingController _commentController = TextEditingController();

  int _rating = 5;
  bool _isLoading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Напишите комментарий')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final success = await _reviewService.addReview(
      universityId: widget.universityId,
      rating: _rating,
      comment: _commentController.text.trim(),
    );

    if (mounted) {
      if (success) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Отзыв добавлен!')));
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка. Попробуйте снова')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Оставить отзыв'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Выбор рейтинга
          const Text(
            'Ваша оценка:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          // Выбор рейтинга (авто-масштабирование)
          FittedBox(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 16),

          // Поле комментария
          TextField(
            controller: _commentController,
            maxLines: 4,
            maxLength: 1000,
            decoration: const InputDecoration(
              hintText: 'Напишите ваш отзыв...',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitReview,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Отправить'),
        ),
      ],
    );
  }
}
