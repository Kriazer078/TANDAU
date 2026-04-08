import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import '../services/like_service.dart';
import '../services/review_service.dart';
import '../utils/guest_guard.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';

/// Кнопка лайка с анимацией
class LikeButton extends StatefulWidget {
  final String universityId;
  final int initialLikesCount;
  final bool? initialIsLiked;

  const LikeButton({
    super.key,
    required this.universityId,
    this.initialLikesCount = 0,
    this.initialIsLiked,
  });

  // ⚡ Static cache: load once, check many times
  static Set<String>? _likedIdsCache;
  static bool _cacheLoading = false;

  /// Pre-load all liked IDs for current user (call once)
  static Future<void> preloadLikes() async {
    if (_cacheLoading) return;
    _cacheLoading = true;
    try {
      final ids = await LikeService().getUserLikedUniversities();
      _likedIdsCache = ids.toSet();
    } catch (_) {
      _likedIdsCache = {};
    } finally {
      _cacheLoading = false;
    }
  }

  /// Clear cache on logout
  static void clearCache() => _likedIdsCache = null;

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> {
  final LikeService _likeService = LikeService();

  bool _isLiked = false;
  int _likesCount = 0;
  bool _isLoading = false;
  // ⚡ Toggle to trigger scale animation without AnimationController
  bool _animTrigger = false;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.initialLikesCount;
    _checkLikeStatus();
  }

  /// ⚡ Check like status from cache first, fallback to Firestore
  Future<void> _checkLikeStatus() async {
    // Use cache if available (no Firestore read)
    if (LikeButton._likedIdsCache != null) {
      if (mounted) {
        setState(() {
          _isLiked = LikeButton._likedIdsCache!.contains(widget.universityId);
        });
      }
      return;
    }
    // Fallback to individual read only if cache not loaded yet
    final liked = await _likeService.isLiked(widget.universityId);
    if (mounted) {
      setState(() {
        _isLiked = liked;
      });
    }
  }

  Future<void> _handleLike() async {
    if (!GuestGuard.check(context)) return;
    if (_isLoading) return;

    HapticFeedback.lightImpact();

    setState(() => _isLoading = true);

    final wasLiked = _isLiked;
    setState(() {
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
      _animTrigger = !_animTrigger; // ⚡ trigger bounce animation
    });

    final success = await _likeService.toggleLike(widget.universityId);

    // Update static cache
    if (success && LikeButton._likedIdsCache != null) {
      if (_isLiked) {
        LikeButton._likedIdsCache!.add(widget.universityId);
      } else {
        LikeButton._likedIdsCache!.remove(widget.universityId);
      }
    }

    if (!success && mounted) {
      setState(() {
        _isLiked = wasLiked;
        _likesCount += _isLiked ? 1 : -1;
      });
      debugPrint('Error toggling like (possibly rapid clicks)');
    }

    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ⚡ TweenAnimationBuilder replaces explicit AnimationController —
        // no Ticker allocated per list item, animates only on trigger change
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 1.0, end: _animTrigger ? 1.3 : 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: IconButton(
            onPressed: _handleLike,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
            icon: Icon(
              _isLiked ? Icons.favorite : Icons.favorite_border,
              color: _isLiked ? Colors.red : Colors.grey,
            ),
            iconSize: 28,
          ),
        ),
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
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
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

// ═══════════════════════════════════════════════════════
// PREMIUM ADD REVIEW BOTTOM SHEET (Google Play / App Store style)
// ═══════════════════════════════════════════════════════

class AddReviewDialog extends StatefulWidget {
  final String universityId;

  const AddReviewDialog({super.key, required this.universityId});

  @override
  State<AddReviewDialog> createState() => _AddReviewDialogState();
}

class _AddReviewDialogState extends State<AddReviewDialog>
    with SingleTickerProviderStateMixin {
  final ReviewService _reviewService = ReviewService();
  final TextEditingController _commentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  late AnimationController _animController;
  late Animation<double> _slideAnimation;

  List<File> _selectedImages = [];
  int _rating = 0;
  bool _isLoading = false;

  // Emoji and text for each rating
  static const List<String> _ratingEmojis = ['😞', '😕', '😐', '😊', '🤩'];

  List<String> _ratingTexts(AppLocalizations? l10n) => [
    l10n?.reviewRatingBad ?? 'Ужасно',
    l10n?.reviewRatingPoor ?? 'Плохо',
    l10n?.reviewRatingOk ?? 'Нормально',
    l10n?.reviewRatingGood ?? 'Хорошо',
    l10n?.reviewRatingExcellent ?? 'Отлично!',
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 70, // сжимаем для экономии места
      );

      if (images.isNotEmpty) {
        // Ограничиваем количество до 3 штук
        final toAdd = images
            .take(3 - _selectedImages.length)
            .map((e) => File(e.path));
        setState(() {
          _selectedImages.addAll(toAdd);
          if (_selectedImages.length > 3) {
            _selectedImages = _selectedImages.sublist(0, 3);
          }
        });
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<List<String>> _uploadImages() async {
    final List<String> urls = [];
    // Use centralized API key to fix Google Play image upload issues
    const String apiKey = '16ea590b6156b5c9fbc737026770d231';

    for (var i = 0; i < _selectedImages.length; i++) {
      final file = _selectedImages[i];
      try {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('https://api.imgbb.com/1/upload'),
        );
        request.fields['key'] = apiKey;
        request.files.add(
          await http.MultipartFile.fromPath('image', file.path),
        );

        final response = await request.send().timeout(
          const Duration(seconds: 30),
        );
        if (response.statusCode == 200) {
          final resBody = await response.stream.bytesToString();
          final data = jsonDecode(resBody);
          final String? downloadUrl = data['data']?['url'];
          if (downloadUrl != null) {
            urls.add(downloadUrl);
          }
        } else {
          debugPrint('ImgBB Error status: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('ImgBB upload error: $e');
      }
    }
    return urls;
  }

  Future<void> _submitReview() async {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n?.reviewSelectRatingError ?? 'Выберите оценку'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.reviewWriteCommentError ?? 'Напишите комментарий',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<String>? photoUrls;
      if (_selectedImages.isNotEmpty) {
        photoUrls = await _uploadImages();
      }

      final success = await _reviewService.addReview(
        universityId: widget.universityId,
        rating: _rating,
        comment: _commentController.text.trim(),
        photoUrls: photoUrls,
      );

      if (mounted) {
        if (success) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(l10n?.reviewSuccessMsg ?? 'Отзыв успешно добавлен!'),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        } else {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n?.reviewModerationFailMsg ??
                    'Не удалось отправить. Проверьте текст на нецензурные слова.',
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.reviewErrorGeneric(e.toString()) ?? 'Произошла ошибка: $e',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final AppLocalizations? l10n = AppLocalizations.of(context);

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(_slideAnimation),
      child: Container(
        padding: EdgeInsets.only(bottom: bottomInset),
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.gold.withValues(alpha: 0.2),
                            AppColors.gold.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.rate_review_rounded,
                        color: AppColors.gold,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      l10n?.reviewLeaveTitle ?? 'Оставить отзыв',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Rating section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                          ? Colors.white10
                          : AppColors.border.withValues(alpha: 0.5),
                    ),
                    boxShadow: isDark
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        l10n?.reviewRateQuestion ?? 'Как вы оцениваете вуз?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white70
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Star selector
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final bool selected = index < _rating;
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _rating = index + 1);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutBack,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 4,
                              ),
                              child: AnimatedScale(
                                scale: selected ? 1.15 : 1.0,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutBack,
                                child: Icon(
                                  selected
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  color: selected
                                      ? AppColors.gold
                                      : (isDark
                                            ? Colors.white24
                                            : Colors.grey[300]),
                                  size: 44,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),

                      // Emoji feedback
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOutBack,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: _rating > 0
                              ? Padding(
                                  key: ValueKey(_rating),
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getRatingColor(
                                        _rating,
                                      ).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _ratingEmojis[_rating - 1],
                                          style: const TextStyle(fontSize: 22),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _ratingTexts(l10n)[_rating - 1],
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: _getRatingColor(_rating),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : const SizedBox(height: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Comment field
                Container(
                  decoration: BoxDecoration(
                    boxShadow: isDark
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                  ),
                  child: TextField(
                    controller: _commentController,
                    maxLines: 4,
                    maxLength: 1000,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      fontSize: 15,
                      height: 1.5,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          l10n?.reviewCommentHint ??
                          'Поделитесь своим мнением: преподаватели, инфраструктура, атмосфера...',
                      hintMaxLines: 2,
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white38 : AppColors.textHint,
                        height: 1.5,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.03)
                          : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white10 : AppColors.border,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white10 : AppColors.border,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(20),
                      counterStyle: TextStyle(
                        color: isDark ? Colors.white38 : AppColors.textHint,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                // Photo attachments UI
                const SizedBox(height: 16),
                if (_selectedImages.isNotEmpty)
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: FileImage(_selectedImages[index]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 16,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                if (_selectedImages.isNotEmpty) const SizedBox(height: 16),

                // Add photo button
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _selectedImages.length >= 3 ? null : _pickImages,
                    icon: Icon(
                      Icons.camera_alt_outlined,
                      color: _selectedImages.length >= 3
                          ? Colors.grey
                          : AppColors.primary,
                    ),
                    label: Text(
                      l10n?.reviewAttachPhotoLabel(_selectedImages.length) ??
                          'Прикрепить фото (${_selectedImages.length}/3)',
                      style: TextStyle(
                        color: _selectedImages.length >= 3
                            ? Colors.grey
                            : AppColors.primary,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      backgroundColor: isDark
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.primary.withValues(alpha: 0.05),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Buttons row
                Row(
                  children: [
                    // Cancel
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(
                            color: isDark ? Colors.white24 : AppColors.border,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          l10n?.reviewCancelBtn ?? 'Отмена',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white70
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Submit
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, Color(0xFF6366F1)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitReview,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.send_rounded,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      l10n?.reviewSubmitBtn ?? 'Отправить',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.deepOrange;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.lightGreen;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
