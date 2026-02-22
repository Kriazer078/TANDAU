import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/university.dart';
import '../models/user_model.dart';
import '../services/university_service.dart';
import '../services/review_service.dart';
import '../models/review.dart';
import '../widgets/like_review_widgets.dart';
import '../widgets/university_header.dart';
import '../services/auth_service.dart';
import '../utils/guest_guard.dart';
import '../models/student_profile.dart';
import '../services/ai_consultant_service.dart';
import '../services/grant_chance_service.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/ai_logo_icon.dart';
// dart:ui removed — replaced BackdropFilter with lightweight containers

class UniversityDetailScreen extends StatefulWidget {
  final University university;

  const UniversityDetailScreen({super.key, required this.university});

  @override
  State<UniversityDetailScreen> createState() => _UniversityDetailScreenState();
}

class _UniversityDetailScreenState extends State<UniversityDetailScreen>
    with SingleTickerProviderStateMixin {
  final UniversityService _service = UniversityService();
  final ReviewService _reviewService = ReviewService();
  final AuthService _authService = AuthService();
  late TabController _tabController;

  AppLocalizations? get l10n => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  Future<void> _toggleFavorite() async {
    if (!GuestGuard.check(context)) return;
    try {
      final isFavorite =
          _authService.currentUser.value?.favoriteUniversities.contains(
            widget.university.id,
          ) ??
          false;
      if (isFavorite) {
        await _service.removeFromFavorites(widget.university.id);
      } else {
        await _service.addToFavorites(widget.university.id);
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.detailErrorFavorites ?? 'Ошибка обновления избранного',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Dynamic Premium AppBar
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            stretch: true,
            backgroundColor: isDark
                ? AppColors.backgroundDark
                : AppColors.background,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black26,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black26,
                    shape: BoxShape.circle,
                  ),
                  child: ValueListenableBuilder<UserModel?>(
                    valueListenable: _authService.currentUser,
                    builder: (context, user, child) {
                      final isFavorite =
                          user?.favoriteUniversities.contains(
                            widget.university.id,
                          ) ??
                          false;
                      return IconButton(
                        icon: Icon(
                          isFavorite ? Icons.bookmark : Icons.bookmark_border,
                          color: isFavorite ? AppColors.accent : Colors.white,
                        ),
                        onPressed: _toggleFavorite,
                      );
                    },
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradient/Pattern Background
                  Container(
                    decoration: BoxDecoration(
                      gradient: isDark
                          ? AppColors.darkGradient
                          : AppColors.primaryGradient,
                    ),
                    child: Opacity(
                      opacity: 0.1,
                      child: CustomPaint(
                        painter: GridPainter(color: Colors.white),
                      ),
                    ),
                  ),
                  // Centered Icon
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 2),
                      ),
                      child: const Icon(
                        Icons.account_balance_rounded,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // Bottom Fade
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            isDark
                                ? AppColors.backgroundDark
                                : AppColors.background,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RepaintBoundary(
                  child: UniversityHeader(university: widget.university),
                ),

                // Analytics Button - Integrated Design
                RepaintBoundary(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(77), // ~0.3
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _showAdmissionStrategy,
                          borderRadius: BorderRadius.circular(20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.analytics_rounded,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                l10n?.detailEstimateChances ?? 'Оценить шансы',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Modern TabBar
                RepaintBoundary(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: isDark
                          ? Colors.white38
                          : Colors.black38,
                      indicatorColor: AppColors.primary,
                      indicatorSize: TabBarIndicatorSize.label,
                      dividerColor: Colors.transparent,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      tabs: [
                        Tab(text: l10n?.tabOverview ?? 'Обзор'),
                        Tab(text: l10n?.tabMajors ?? 'Специальности'),
                        Tab(text: l10n?.tabAdmissions ?? 'Поступление'),
                        Tab(text: l10n?.tabContact ?? 'Контакты'),
                        Tab(text: l10n?.tabReviews ?? 'Отзывы'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Content
                SizedBox(
                  height: 600,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      RepaintBoundary(child: _buildOverview(isDark)),
                      RepaintBoundary(child: _buildMajors(isDark)),
                      RepaintBoundary(child: _buildAdmission(isDark)),
                      RepaintBoundary(child: _buildContact(isDark)),
                      RepaintBoundary(child: _buildReviews(isDark)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required Widget child,
    required bool isDark,
    EdgeInsets? padding,
  }) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withAlpha(13) // ~0.05
              : AppColors.border.withAlpha(128), // ~0.5
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8), // ~0.03
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildOverview(bool isDark) {
    return SingleChildScrollView(
      child: _buildCard(
        isDark: isDark,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n?.detailAboutUniversity ?? 'About University',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.university.description,
              style: TextStyle(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
                height: 1.6,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMajors(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: widget.university.majors.length,
      itemBuilder: (context, index) {
        final major = widget.university.majors[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withAlpha(13) // ~0.05
                  : AppColors.border.withAlpha(128), // ~0.5
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(26), // ~0.1
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  major,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAdmission(bool isDark) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildCard(
            isDark: isDark,
            child: Column(
              children: [
                Text(
                  l10n?.detailPassingScoreTitle ?? 'Passing Score',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${widget.university.passingScore}',
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.primary,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n?.detailPoints ?? 'points',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.white70
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  l10n?.detailBasedOnLastYear ?? 'Based on last year\'s data',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          if (widget.university.requirements.isNotEmpty)
            _buildCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.assignment_rounded,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n?.detailAdmissionRequirements ??
                              'Admission Requirements',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...widget.university.requirements.map(
                    (req) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            size: 20,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              req,
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (widget.university.applicationDeadline.isNotEmpty)
            _buildCard(
              isDark: isDark,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withAlpha(26), // ~0.1
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.timer_outlined,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.detailApplicationDeadline ??
                            'Application Deadline',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.university.applicationDeadline,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 100), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildContact(bool isDark) {
    // Вытаскиваем телефон из описания (если мы его туда вшили с эмодзи 📞)
    String phone = l10n?.detailPhoneNotProvided ?? 'Not provided';
    final RegExp phoneRegex = RegExp(r'📞 Байланыс: (.*)');
    final match = phoneRegex.firstMatch(widget.university.description);
    if (match != null && match.groupCount >= 1) {
      phone = match.group(1)!.trim();
    } else {
      // Примерные номера для известных вузов (Астана/Алматы),
      // пока они не будут добавлены в БД окончательно.
      if (widget.university.id == '1') phone = '+7 (7172) 70 66 88'; // NU
      if (widget.university.id == '2') phone = '+7 (7172) 64 57 10'; // AITU
      if (widget.university.id == '3') phone = '+7 (7172) 70 95 00'; // ENU
      if (widget.university.id == '4') phone = '+7 (727) 377 33 33'; // KazNU
      if (widget.university.id == '5') phone = '+7 (727) 292 28 01'; // Satbayev
      if (widget.university.id == '6') phone = '+7 (727) 291 57 68'; // KazNPU
      if (widget.university.id == '7') phone = '+7 (727) 357 42 42'; // KBTU
      if (widget.university.id == '8') phone = '+7 (727) 377 19 00'; // Narxoz
    }

    final website = widget.university.website.isNotEmpty
        ? widget.university.website
        : l10n?.detailWebsiteNotProvided ?? 'Website not provided';

    return _buildCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildContactRow(
            Icons.location_on_rounded,
            l10n?.detailAddressLabel ?? 'Address',
            widget.university.address,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          _buildContactRow(
            Icons.language_rounded,
            l10n?.detailWebsiteLabel ?? 'Website',
            website,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          _buildContactRow(
            Icons.phone_rounded,
            l10n?.detailPhoneLabelFull ?? 'Phone',
            phone,
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String title, String data) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviews(bool isDark) {
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
                    builder: (_) =>
                        AddReviewDialog(universityId: widget.university.id),
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
                style: TextStyle(
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
            stream: _reviewService.getUniversityReviewsStream(
              widget.university.id,
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final reviews = snapshot.data!;
              if (reviews.isEmpty) {
                return _buildEmptyReviews(isDark);
              }

              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  // Rating summary card
                  _buildRatingSummary(reviews, isDark),
                  const SizedBox(height: 16),
                  // Review cards
                  ...reviews.map((r) => _buildReviewCard(r, isDark)),
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
  Widget _buildEmptyReviews(bool isDark) {
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
  Widget _buildRatingSummary(List<Review> reviews, bool isDark) {
    final int total = reviews.length;
    final double avg = reviews.fold<int>(0, (sum, r) => sum + r.rating) / total;

    // Count per star
    final Map<int, int> counts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final r in reviews) {
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
          // Left: big average number
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

          // Right: bar distribution
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
  Widget _buildReviewCard(Review r, bool isDark) {
    // Format date
    final String dateStr = _formatReviewDate(r.createdAt);

    // Avatar color from userName
    final Color avatarColor = _avatarColor(r.userName);

    final currentUserId = _authService.currentUser.value?.uid;
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
              // Avatar
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
              // Name + date
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
              // Stars badge
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
                  await _reviewService.toggleHelpful(r.id);
                  // Стрим обновит автоматически UI
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
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'только что';
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин назад';
    if (diff.inHours < 24) return '${diff.inHours} ч назад';
    if (diff.inDays < 7) return '${diff.inDays} дн назад';

    final months = [
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
    final colors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF10B981), // Emerald
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFEF4444), // Red
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFF3B82F6), // Blue
      const Color(0xFFEC4899), // Pink
      const Color(0xFF14B8A6), // Teal
    ];
    final int hash = name.codeUnits.fold<int>(0, (prev, c) => prev + c);
    return colors[hash % colors.length];
  }

  Future<void> _showAdmissionStrategy() async {
    if (!GuestGuard.check(context)) return;
    final user = _authService.currentUser.value;
    if (user == null) return;

    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Build student profile
    final StudentProfile profile = StudentProfile(
      userId: user.uid,
      name: user.name,
      entScore: user.untScore,
      ieltsScore: user.ieltsScore,
      gpa: user.gpa,
      mathScore: user.mathScore,
      profileStrength: 0.6,
      achievements: user.achievements,
      preferredCities: [user.city ?? 'Almaty'],
      preferredMajors: user.preferredMajors,
    );

    // STEP 1: Instant SVD calculation (no network!)
    final GrantChanceResult svdResult = AIConsultantService()
        .calculateGrantChance(profile: profile, university: widget.university);

    if (!mounted) return;

    // Show SVD result bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SvdResultSheet(
        svdResult: svdResult,
        isDark: isDark,
        university: widget.university,
        profile: profile,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class GridPainter extends CustomPainter {
  final Color color;
  GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..strokeWidth = 1;

    for (var i = 0; i < size.width; i += 40) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(i.toDouble(), size.height),
        paint,
      );
    }
    for (var i = 0; i < size.height; i += 40) {
      canvas.drawLine(
        Offset(0, i.toDouble()),
        Offset(size.width, i.toDouble()),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ─── SVD Result Bottom Sheet ───
class _SvdResultSheet extends StatefulWidget {
  final GrantChanceResult svdResult;
  final bool isDark;
  final University university;
  final StudentProfile profile;

  const _SvdResultSheet({
    required this.svdResult,
    required this.isDark,
    required this.university,
    required this.profile,
  });

  @override
  State<_SvdResultSheet> createState() => _SvdResultSheetState();
}

class _SvdResultSheetState extends State<_SvdResultSheet> {
  bool _isLoadingAiStrategy = false;
  String? _aiStrategy;

  AppLocalizations? get l10n => AppLocalizations.of(context);

  Color get _riskColor {
    switch (widget.svdResult.riskLevel) {
      case RiskLevel.low:
        return Colors.green;
      case RiskLevel.medium:
        return Colors.orange;
      case RiskLevel.high:
        return Colors.deepOrange;
      case RiskLevel.critical:
        return AppColors.error;
      case RiskLevel.unknown:
        return Colors.grey;
    }
  }

  Future<void> _loadAiStrategy() async {
    setState(() => _isLoadingAiStrategy = true);
    try {
      final String strategy = await AIConsultantService().getAdmissionStrategy(
        profile: widget.profile,
        university: widget.university,
      );
      if (mounted) {
        setState(() {
          _aiStrategy = strategy;
          _isLoadingAiStrategy = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAiStrategy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.commonError(e.toString()) ?? 'Ошибка: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final GrantChanceResult r = widget.svdResult;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.backgroundDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: widget.isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.analytics_rounded,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'СВД Аналитика',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(26),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Данные ${r.dataYear}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _riskColor.withAlpha(77),
                          width: 6,
                        ),
                        color: _riskColor.withAlpha(26),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${r.chancePercent}%',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: _riskColor,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n?.aiChancesGrant ?? 'шанс на грант',
                            style: TextStyle(
                              fontSize: 13,
                              color: widget.isDark
                                  ? Colors.white70
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _riskColor.withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            r.riskLevel.emoji,
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n?.aiChancesRisk(r.riskLevel.displayName) ??
                                'Риск: ${r.riskLevel.displayName}',
                            style: TextStyle(
                              color: _riskColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      r.verdict,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.4,
                        color: widget.isDark
                            ? Colors.white70
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      l10n?.aiChancesEntThreshold(r.entThreshold) ??
                          'Порог ЕНТ для этого направления: ${r.entThreshold} баллов',
                      style: TextStyle(
                        fontSize: 13,
                        color: widget.isDark
                            ? Colors.white38
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (r.details.isNotEmpty) ...[
                    Text(
                      l10n?.aiChancesDetails ?? 'Детали расчёта',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...r.details.map(
                      (d) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          d,
                          style: const TextStyle(fontSize: 15, height: 1.4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (r.recommendations.isNotEmpty) ...[
                    Text(
                      l10n?.detailRecommendations ?? '💡 Рекомендации',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...r.recommendations.map(
                      (rec) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                rec,
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (_aiStrategy == null && !_isLoadingAiStrategy)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _loadAiStrategy,
                        icon: const AILogoIcon(color: Colors.white),
                        label: Text(
                          l10n?.aiChancesDetailedStrategy ??
                              'Подробная AI стратегия',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  if (_isLoadingAiStrategy)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Column(
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              l10n?.detailAiThinking ??
                                  'AI формирует стратегию...',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_aiStrategy != null) ...[
                    const Divider(height: 32),
                    Row(
                      children: [
                        const AILogoIcon(color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          l10n?.detailAiStrategySubtitle ??
                              'AI Стратегия TANDAU',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    MarkdownBody(
                      data: _aiStrategy!,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: widget.isDark ? Colors.white : Colors.black87,
                        ),
                        h1: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 20,
                        ),
                        h2: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        listBullet: TextStyle(
                          color: widget.isDark
                              ? Colors.white70
                              : Colors.black54,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
