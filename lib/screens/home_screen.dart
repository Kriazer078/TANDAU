import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../utils/guest_guard.dart';
import 'comparison_screen.dart';
import 'filter_screen.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/ai_consultant_service.dart';
import '../services/auth_service.dart';
import '../services/university_service.dart';
import '../models/university.dart';
import '../models/student_profile.dart';
import '../services/comparison_service.dart';
import 'notifications_screen.dart';
import '../services/notification_service.dart';
import '../models/notification.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  // Cache greeting to avoid re-computing each build
  late String _greeting;
  String? _greetingLocale;
s
  // Cache notification stream to avoid re-creating on each build
  late final Stream<List<AppNotification>> _notificationStream;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();

    // Cache notification stream — created once, reused across builds
    _notificationStream = NotificationService()
        .getNotificationsStream()
        .asBroadcastStream();

    _updateGreeting(null);
  }

  void _updateGreeting(String? locale) {
    final hour = DateTime.now().hour;
    if (locale == 'ru') {
      _greeting = hour < 12
          ? 'Доброе утро'
          : (hour < 18 ? 'Добрый день' : 'Добрый вечер');
    } else if (locale == 'kk') {
      _greeting = hour < 12
          ? 'Қайырлы таң'
          : (hour < 18 ? 'Қайырлы күн' : 'Қайырлы кеш');
    } else {
      _greeting = hour < 12
          ? 'Good Morning'
          : (hour < 18 ? 'Good Afternoon' : 'Good Evening');
    }
    _greetingLocale = locale;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    // Only recompute greeting if locale changed
    if (_greetingLocale != l10n?.localeName) {
      _updateGreeting(l10n?.localeName);
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. Dynamic AppBar
            _buildAppBar(theme, isDark),

            // 2. Main Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Greeting & Subtitle
                        const SizedBox(height: 8),
                        Text(
                          _greeting,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? Colors.white60
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n?.homeSubtitle ?? 'Find your dream university',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimary,
                            height: 1.1,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // MAIN CARD: AI CHANCE ESTIMATION
                        RepaintBoundary(
                          child: _buildMainFeatureCard(context, isDark),
                        ),

                        const SizedBox(height: 32),

                        // Quick Actions Grid
                        Text(
                          'Tools',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 16),
                        RepaintBoundary(
                          child: _buildToolsRow(context, l10n, isDark),
                        ),

                        const SizedBox(height: 32),

                        // MARKET STATS
                        Text(
                          'Market Insights',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 16),
                        RepaintBoundary(child: _buildMarketStats(isDark)),

                        const SizedBox(height: 100), // Bottom padding
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // APP BAR
  // ═══════════════════════════════════════════
  SliverAppBar _buildAppBar(ThemeData theme, bool isDark) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: theme.scaffoldBackgroundColor,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.school_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'TANDAU',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        background: ColoredBox(color: theme.scaffoldBackgroundColor),
      ),
      actions: [
        RepaintBoundary(
          child: StreamBuilder<List<AppNotification>>(
            stream: _notificationStream,
            builder: (context, snapshot) {
              final int unreadCount = snapshot.hasData
                  ? snapshot.data!.where((n) => !n.isRead).length
                  : 0;

              return IconButton(
                icon: unreadCount > 0
                    ? Badge(
                        label: Text(unreadCount.toString()),
                        child: Icon(
                          Icons.notifications_outlined,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      )
                    : Icon(
                        Icons.notifications_outlined,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // MAIN FEATURE CARD
  // ═══════════════════════════════════════════
  Widget _buildMainFeatureCard(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF0EA5E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
            blurRadius: 12, // Reduced from 20 for better GPU perf
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (GuestGuard.check(context)) {
              _showUniversityPicker(context);
            }
          },
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            children: [
              // Decorative circles (simplified — single positioned circle)
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: -40,
                right: 40,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                color: Colors.white,
                                size: 14,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'AI Powered',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_outward_rounded,
                          color: Colors.white,
                        ),
                      ],
                    ),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Оценка шансов',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Анализ поступления на грант 2025',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // TOOLS ROW
  // ═══════════════════════════════════════════
  Widget _buildToolsRow(
    BuildContext context,
    AppLocalizations? l10n,
    bool isDark,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            context,
            title: l10n?.comparisonTitle ?? 'Compare',
            subtitle: 'Universities',
            icon: Icons.compare_arrows_rounded,
            color: const Color(0xFF10B981),
            isDark: isDark,
            onTap: () {
              if (GuestGuard.check(context)) {
                _showComparePicker(context);
              }
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionCard(
            context,
            title: l10n?.ctaStart ?? 'Search',
            subtitle: 'Advanced Filter',
            icon: Icons.tune_rounded,
            color: const Color(0xFFF59E0B),
            isDark: isDark,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FilterScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark
            ? null // Skip shadow in dark mode to reduce overdraw
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.white54
                            : AppColors.textSecondary,
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

  // ═══════════════════════════════════════════
  // MARKET STATS
  // ═══════════════════════════════════════════
  Widget _buildMarketStats(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem('120+', 'ВУЗов', isDark),
          _buildDivider(isDark),
          _buildStatItem('25k', 'Студентов', isDark),
          _buildDivider(isDark),
          _buildStatItem('4.8', 'Рейтинг', isDark),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white54 : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 30,
      width: 1,
      color: isDark ? Colors.white10 : AppColors.border,
    );
  }

  // ═══════════════════════════════════════════
  // MODAL SHEETS
  // ═══════════════════════════════════════════
  void _showUniversityPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _UniversityPickerSheet(
        onUniversitySelected: (university) {
          Navigator.pop(context);
          _estimateChances(university);
        },
      ),
    );
  }

  void _showComparePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ComparePickerSheet(
        onComparisonSelected: (unis) async {
          final ids = unis.map((u) => u.id).toList();
          await ComparisonService().setComparison(ids);
          if (context.mounted) {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ComparisonScreen()),
            );
          }
        },
      ),
    );
  }

  Future<void> _estimateChances(University university) async {
    final authService = AuthService();
    final user = authService.currentUser.value;
    if (user == null) return;

    // Show Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.surfaceDark
                : Colors.white,
            borderRadius: BorderRadius.circular(32),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                "AI Analysis...",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final strategy = await AIConsultantService().getAdmissionStrategy(
        profile: StudentProfile(
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
        ),
        university: university,
      );

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Close loading dialog

      if (!mounted) return;
      _showResultSheet(strategy);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Close loading dialog
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showResultSheet(String strategy) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'AI Аналитика TANDAU',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            Expanded(
              child: Markdown(
                data: strategy,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(fontSize: 16, height: 1.6),
                  h1: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// UNIVERSITY PICKER (Optimized)
// ═══════════════════════════════════════════
class _UniversityPickerSheet extends StatefulWidget {
  final Function(University) onUniversitySelected;

  const _UniversityPickerSheet({required this.onUniversitySelected});

  @override
  State<_UniversityPickerSheet> createState() => _UniversityPickerSheetState();
}

class _UniversityPickerSheetState extends State<_UniversityPickerSheet> {
  final UniversityService _service = UniversityService();
  List<University> _universities = [];
  List<University> _filteredUniversities = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadUniversities();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUniversities() async {
    final universities = await _service.getAllUniversities();
    if (mounted) {
      setState(() {
        _universities = universities;
        _filteredUniversities = universities;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final query = _searchController.text.toLowerCase();
      if (mounted) {
        setState(() {
          _filteredUniversities = query.isEmpty
              ? _universities
              : _universities.where((u) {
                  return u.name.toLowerCase().contains(query) ||
                      u.city.toLowerCase().contains(query);
                }).toList();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Выберите вуз',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Поиск университета...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: isDark ? AppColors.cardDark : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredUniversities.length,
                    // Fixed item height for smoother scrolling
                    itemExtent: 84,
                    itemBuilder: (context, index) {
                      final uni = _filteredUniversities[index];
                      return _UniversityTile(
                        university: uni,
                        isDark: isDark,
                        onTap: () => widget.onUniversitySelected(uni),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// COMPARE PICKER (Optimized)
// ═══════════════════════════════════════════
class _ComparePickerSheet extends StatefulWidget {
  final Function(List<University>) onComparisonSelected;

  const _ComparePickerSheet({required this.onComparisonSelected});

  @override
  State<_ComparePickerSheet> createState() => _ComparePickerSheetState();
}

class _ComparePickerSheetState extends State<_ComparePickerSheet> {
  final UniversityService _service = UniversityService();
  List<University> _universities = [];
  List<University> _filteredUniversities = [];
  final Set<University> _selected = {};
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadUniversities();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUniversities() async {
    final universities = await _service.getAllUniversities();
    if (mounted) {
      setState(() {
        _universities = universities;
        _filteredUniversities = universities;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final query = _searchController.text.toLowerCase();
      if (mounted) {
        setState(() {
          _filteredUniversities = query.isEmpty
              ? _universities
              : _universities.where((u) {
                  return u.name.toLowerCase().contains(query) ||
                      u.city.toLowerCase().contains(query);
                }).toList();
        });
      }
    });
  }

  void _toggleSelection(University uni) {
    setState(() {
      if (_selected.contains(uni)) {
        _selected.remove(uni);
      } else if (_selected.length < 2) {
        _selected.add(uni);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Можно выбрать только 2 вуза')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Сравнение вузов',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${_selected.length}/2',
                      style: TextStyle(
                        color: _selected.length == 2
                            ? AppColors.primary
                            : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Поиск университета...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: isDark ? AppColors.cardDark : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredUniversities.length,
                    itemExtent: 84,
                    itemBuilder: (context, index) {
                      final uni = _filteredUniversities[index];
                      final isSelected = _selected.contains(uni);

                      return _UniversityTile(
                        university: uni,
                        isDark: isDark,
                        isSelected: isSelected,
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle,
                                color: AppColors.primary,
                              )
                            : const Icon(
                                Icons.circle_outlined,
                                color: Colors.grey,
                              ),
                        onTap: () => _toggleSelection(uni),
                      );
                    },
                  ),
          ),
          if (_selected.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () =>
                        widget.onComparisonSelected(_selected.toList()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Сравнить',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// SHARED: University Tile (Reusable, RepaintBoundary)
// ═══════════════════════════════════════════
class _UniversityTile extends StatelessWidget {
  final University university;
  final bool isDark;
  final bool isSelected;
  final Widget? trailing;
  final VoidCallback onTap;

  const _UniversityTile({
    required this.university,
    required this.isDark,
    this.isSelected = false,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.1)
            : (isDark ? AppColors.cardDark : Colors.white),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? Colors.white10 : Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: isSelected
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: university.logoUrl.isNotEmpty
                      ? CachedNetworkImageProvider(university.logoUrl)
                      : null,
                  child: university.logoUrl.isEmpty
                      ? Icon(
                          Icons.school,
                          color: isSelected ? Colors.white : AppColors.primary,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        university.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        university.city,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? Colors.white54
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
