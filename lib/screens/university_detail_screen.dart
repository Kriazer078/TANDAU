import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/university.dart';
import '../models/user_model.dart';
import '../services/university_service.dart';
import '../services/auth_service.dart';
import '../utils/guest_guard.dart';
import '../models/student_profile.dart';
import '../services/ai_consultant_service.dart';
import '../services/grant_chance_service.dart';
import '../l10n/app_localizations.dart';
import '../widgets/university_header.dart';
import '../widgets/university_overview_tab.dart';
import '../widgets/university_majors_tab.dart';
import '../widgets/university_admission_tab.dart';
import '../widgets/university_contact_tab.dart';
import '../widgets/university_reviews_tab.dart';
import '../widgets/svd_result_sheet.dart';

class UniversityDetailScreen extends StatefulWidget {
  final University university;

  const UniversityDetailScreen({super.key, required this.university});

  @override
  State<UniversityDetailScreen> createState() => _UniversityDetailScreenState();
}

class _UniversityDetailScreenState extends State<UniversityDetailScreen>
    with SingleTickerProviderStateMixin {
  final UniversityService _service = UniversityService();
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
      final bool isFavorite =
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
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

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
                      final bool isFavorite =
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

                // Analytics Button
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
                            color: AppColors.primary.withAlpha(77),
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

                // Content — extracted tab widgets
                SizedBox(
                  height: 600,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      RepaintBoundary(
                        child: UniversityOverviewTab(
                          university: widget.university,
                          isDark: isDark,
                        ),
                      ),
                      RepaintBoundary(
                        child: UniversityMajorsTab(
                          university: widget.university,
                          isDark: isDark,
                        ),
                      ),
                      RepaintBoundary(
                        child: UniversityAdmissionTab(
                          university: widget.university,
                          isDark: isDark,
                        ),
                      ),
                      RepaintBoundary(
                        child: UniversityContactTab(
                          university: widget.university,
                          isDark: isDark,
                        ),
                      ),
                      RepaintBoundary(
                        child: UniversityReviewsTab(
                          universityId: widget.university.id,
                          isDark: isDark,
                        ),
                      ),
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

  Future<void> _showAdmissionStrategy() async {
    if (!GuestGuard.check(context)) return;
    final UserModel? user = _authService.currentUser.value;
    if (user == null) return;

    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Build student profile from UserModel (единый источник данных)
    final StudentProfile profile = StudentProfile.fromUserModel(user);

    // Instant SVD calculation (no network!)
    final GrantChanceResult svdResult = AIConsultantService()
        .calculateGrantChance(profile: profile, university: widget.university);

    if (!mounted) return;

    // Show SVD result bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SvdResultSheet(
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
