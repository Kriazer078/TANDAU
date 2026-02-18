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
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:ui';

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
          const SnackBar(content: Text('Ошибка обновления избранного')),
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
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: Colors.black26,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      color: Colors.black26,
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
                              isFavorite
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              color: isFavorite
                                  ? AppColors.accent
                                  : Colors.white,
                            ),
                            onPressed: _toggleFavorite,
                          );
                        },
                      ),
                    ),
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
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.analytics_rounded,
                                color: Colors.white,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Оценить шансы',
                                style: TextStyle(
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
                      tabs: const [
                        Tab(text: 'Обзор'),
                        Tab(text: 'Специальности'),
                        Tab(text: 'Поступление'),
                        Tab(text: 'Контакты'),
                        Tab(text: 'Отзывы'),
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
            const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'О университете',
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
                const Text(
                  'Проходной балл',
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
                      'баллов',
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
                const Text(
                  'На основе данных прошлого года',
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
                          'Что нужно для поступления',
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
                      const Text(
                        'Крайний срок подачи',
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
    return _buildCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildContactRow(
            Icons.location_on_rounded,
            'Адрес',
            widget.university.address,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          _buildContactRow(
            Icons.language_rounded,
            'Веб-сайт',
            'www.${widget.university.id}.kz',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          _buildContactRow(
            Icons.phone_rounded,
            'Телефон',
            '+7 (777) 000-00-00',
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: OutlinedButton.icon(
            onPressed: () {
              if (GuestGuard.check(context)) {
                showDialog(
                  context: context,
                  builder: (_) =>
                      AddReviewDialog(universityId: widget.university.id),
                );
              }
            },
            icon: const Icon(Icons.add_comment_rounded),
            label: const Text('Оставить отзыв'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
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
                return const Center(child: Text('Пока нет отзывов'));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: reviews.length,
                itemBuilder: (context, index) {
                  final r = reviews[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withAlpha(13) // ~0.05
                            : AppColors.border.withAlpha(128), // ~0.5
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              r.userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.gold.withAlpha(26), // ~0.1
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: AppColors.gold,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${r.rating}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.gold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(r.comment, style: const TextStyle(height: 1.5)),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
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
                            'шанс на грант',
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
                    const Text(
                      'Детали расчёта',
                      style: TextStyle(
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
                    const Text(
                      '💡 Рекомендации',
                      style: TextStyle(
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
                        icon: const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Подробная AI стратегия',
                          style: TextStyle(
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
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text(
                              'AI формирует стратегию...',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_aiStrategy != null) ...[
                    const Divider(height: 32),
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
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
