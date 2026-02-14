import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/university.dart';
import '../services/university_service.dart';
import '../services/review_service.dart'; // ⭐ Import layout
import '../models/review.dart'; // ⭐ Import model
import '../widgets/like_review_widgets.dart'; // ⭐ Import widgets
import '../widgets/university_header.dart'; // ⭐ Import header
import '../services/auth_service.dart'; // ⭐ Import AuthService
import '../l10n/app_localizations.dart'; // ⭐ Import Localizations
import '../utils/guest_guard.dart'; // ⭐ Import GuestGuard

class UniversityDetailScreen extends StatefulWidget {
  final University university;

  const UniversityDetailScreen({super.key, required this.university});

  @override
  State<UniversityDetailScreen> createState() => _UniversityDetailScreenState();
}

class _UniversityDetailScreenState extends State<UniversityDetailScreen>
    with SingleTickerProviderStateMixin {
  final UniversityService _service = UniversityService();
  final ReviewService _reviewService = ReviewService(); // ⭐ Service
  final AuthService _authService = AuthService(); // ⭐ Auth Service
  late TabController _tabController;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this); // ⭐ 5 tabs now
    _loadFavoriteStatus();
  }

  void _loadFavoriteStatus() {
    setState(() {
      _isFavorite = _service.isFavorite(widget.university.id);
    });
  }

  Future<void> _toggleFavorite() async {
    // ⭐ Проверка на гостя
    if (!GuestGuard.check(context)) return;

    if (_isFavorite) {
      await _service.removeFromFavorites(widget.university.id);
    } else {
      await _service.addToFavorites(widget.university.id);
    }
    _loadFavoriteStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(gradient: AppColors.primaryGradient),
                child: const Center(
                  child: Icon(
                    Icons.account_balance,
                    size: 100,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isFavorite ? Icons.bookmark : Icons.bookmark_border,
                  color: Colors.white,
                ),
                onPressed: _toggleFavorite,
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // University Header
                UniversityHeader(university: widget.university),

                // Tabs
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  isScrollable: true,
                  tabs: [
                    Tab(
                      text:
                          AppLocalizations.of(context)?.tabOverview ??
                          'Overview',
                    ),
                    Tab(
                      text: AppLocalizations.of(context)?.tabMajors ?? 'Majors',
                    ),
                    Tab(
                      text:
                          AppLocalizations.of(context)?.tabAdmissions ??
                          'Admissions',
                    ),
                    Tab(
                      text:
                          AppLocalizations.of(context)?.tabContact ?? 'Contact',
                    ),
                    Tab(
                      text:
                          AppLocalizations.of(context)?.tabReviews ?? 'Reviews',
                    ),
                  ],
                ),

                // Tab Content
                SizedBox(
                  height: 500,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildMajorsTab(),
                      _buildAdmissionTab(),
                      _buildContactTab(),
                      _buildReviewsTab(), // ⭐ Контент вкладки
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

  // ⭐ Вкладка отзывов
  Widget _buildReviewsTab() {
    return Column(
      children: [
        // Кнопка добавления отзыва
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                // ⭐ Проверка на гостя
                if (!GuestGuard.check(context)) return;

                await showDialog(
                  context: context,
                  builder: (context) =>
                      AddReviewDialog(universityId: widget.university.id),
                );
              },
              icon: const Icon(Icons.rate_review),
              label: Text(
                AppLocalizations.of(context)?.detailLeaveReview ??
                    'Leave a Review',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),

        // Список отзывов (Real-time)
        Expanded(
          child: StreamBuilder<List<Review>>(
            stream: _reviewService.getUniversityReviewsStream(
              widget.university.id,
            ),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Қате: ${snapshot.error}'));
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final reviews = snapshot.data!;

              if (reviews.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.rate_review_outlined,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)?.detailNoReviews ??
                            'No reviews yet',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: reviews.length,
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                review.userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              RatingDisplay(
                                rating: review.rating.toDouble(),
                                showCount: false,
                              ),
                              // Кнопка удаления (только для автора)
                              if (_authService.currentUser.value?.uid ==
                                  review.userId)
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.redAccent,
                                    size: 20,
                                  ),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Удалить отзыв?'),
                                        content: const Text(
                                          'Это действие нельзя отменить.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Отмена'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text(
                                              'Удалить',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      await _reviewService.deleteReview(
                                        review.id,
                                      );
                                    }
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(review.comment),
                          const SizedBox(height: 8),
                          Text(
                            '${review.createdAt.day}.${review.createdAt.month}.${review.createdAt.year}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)?.detailAbout ?? 'About University',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(
            widget.university.description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),

          Text(
            AppLocalizations.of(context)?.detailTuition ?? 'Tuition Fees',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(
            widget.university.tuitionRange,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMajorsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: widget.university.majors.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.school, color: AppColors.primary),
            title: Text(widget.university.majors[index]),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
        );
      },
    );
  }

  Widget _buildAdmissionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Өту балы', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(
            'ҰБТ ${widget.university.passingScore}+',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 24),

          Text(
            AppLocalizations.of(context)?.detailDocuments ??
                'Required Documents',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          ...widget.university.requirements.map((req) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 20,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      req,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 24),

          Text(
            AppLocalizations.of(context)?.detailDeadline ??
                'Application Deadline',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accent),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: AppColors.accent),
                const SizedBox(width: 12),
                Text(
                  widget.university.applicationDeadline,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildContactItem(
            Icons.location_on,
            AppLocalizations.of(context)?.detailAddress ?? 'Address',
            widget.university.address,
          ),
          const SizedBox(height: 16),
          _buildContactItem(
            Icons.language,
            AppLocalizations.of(context)?.detailWebsite ?? 'Website',
            widget.university.website,
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(value, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
