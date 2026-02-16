import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/university.dart';
import '../services/university_service.dart';
import '../services/review_service.dart';
import '../models/review.dart';
import '../widgets/like_review_widgets.dart';
import '../widgets/university_header.dart';
import '../services/auth_service.dart';
import '../utils/guest_guard.dart';
import '../models/student_profile.dart';
import '../services/ai_consultant_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

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
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadFavoriteStatus();
  }

  void _loadFavoriteStatus() {
    setState(() {
      _isFavorite = _service.isFavorite(widget.university.id);
    });
  }

  Future<void> _toggleFavorite() async {
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAdmissionStrategy,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.analytics_outlined, color: Colors.white),
        label: const Text(
          'Оценить шансы',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
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
          SliverToBoxAdapter(
            child: Column(
              children: [
                UniversityHeader(university: widget.university),
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: AppColors.primary,
                  indicatorColor: AppColors.primary,
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Majors'),
                    Tab(text: 'Admission'),
                    Tab(text: 'Contact'),
                    Tab(text: 'Reviews'),
                  ],
                ),
                SizedBox(
                  height: 600,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverview(),
                      _buildMajors(),
                      _buildAdmission(),
                      _buildContact(),
                      _buildReviews(),
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
    final user = _authService.currentUser.value;
    if (user == null) return;

    showDialog(
      context: context,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final strategy = await AIConsultantService().getAdmissionStrategy(
        profile: StudentProfile(
          userId: user.uid,
          name: user.name,
          entScore: user.untScore ?? 70,
          ieltsScore: user.ieltsScore ?? 5.5,
          gpa: user.gpa ?? 3.5,
          mathScore: user.mathScore ?? 20,
          profileStrength: 0.6,
          achievements: [],
          preferredCities: [user.city ?? 'Almaty'],
          preferredMajors: [],
        ),
        university: widget.university,
      );
      if (!mounted) return;
      Navigator.pop(context);

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Стратегия поступления',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Divider(),
              Expanded(child: Markdown(data: strategy)),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildOverview() => Padding(
    padding: const EdgeInsets.all(16),
    child: Text(widget.university.description),
  );
  Widget _buildMajors() => ListView(
    padding: const EdgeInsets.all(16),
    children: widget.university.majors
        .map((m) => ListTile(title: Text(m)))
        .toList(),
  );
  Widget _buildAdmission() => Padding(
    padding: const EdgeInsets.all(16),
    child: Text('Score: ${widget.university.passingScore}'),
  );
  Widget _buildContact() => Padding(
    padding: const EdgeInsets.all(16),
    child: Text('Address: ${widget.university.address}'),
  );

  Widget _buildReviews() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () => showDialog(
              context: context,
              builder: (_) =>
                  AddReviewDialog(universityId: widget.university.id),
            ),
            child: const Text('Leave Review'),
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
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final r = snapshot.data![index];
                  return ListTile(
                    title: Text(r.userName),
                    subtitle: Text(r.comment),
                    trailing: Text('${r.rating} ⭐'),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
