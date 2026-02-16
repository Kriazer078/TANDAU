import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/university.dart';
import '../services/university_service.dart';
import '../services/comparison_service.dart';
import '../widgets/university_card.dart';
import '../widgets/filter_bottom_sheet.dart';
import 'university_detail_screen.dart';
import '../l10n/app_localizations.dart';

class UniversityListScreen extends StatefulWidget {
  final List<String>? cityFilter;
  final List<String>? majorFilter;
  final List<String>? budgetFilter;
  final String? searchQuery;

  const UniversityListScreen({
    super.key,
    this.cityFilter,
    this.majorFilter,
    this.budgetFilter,
    this.searchQuery,
  });

  @override
  State<UniversityListScreen> createState() => _UniversityListScreenState();
}

class _UniversityListScreenState extends State<UniversityListScreen> {
  final UniversityService _service = UniversityService();
  final ComparisonService _comparisonService = ComparisonService();
  final TextEditingController _searchController = TextEditingController();

  List<University> _universities = [];
  List<String> _favoriteIds = [];
  List<String> _comparisonIds = [];
  String _searchQuery = '';

  List<String> _cities = [];
  List<Map<String, dynamic>> _majors = [];

  List<String> _selectedCities = [];
  List<String> _selectedMajors = [];
  List<String> _selectedBudgets = [];

  @override
  void initState() {
    super.initState();
    _searchQuery = widget.searchQuery ?? '';
    _searchController.text = _searchQuery;
    _selectedCities = List.from(widget.cityFilter ?? []);
    _selectedMajors = List.from(widget.majorFilter ?? []);
    _selectedBudgets = List.from(widget.budgetFilter ?? []);
    _loadData();
  }

  Future<void> _loadData() async {
    final favorites = _service.getFavoriteIds();
    final cities = await _service.getUniqueCities();
    final majors = await _service.getUniqueMajors();
    final comparison = await _comparisonService.getUserComparison();
    setState(() {
      _favoriteIds = favorites;
      _comparisonIds = comparison?.universityIds ?? [];
      _cities = cities;
      _majors = majors.map((m) => {'name': m}).toList();
    });
    await _updateUniversityList();
  }

  Future<void> _updateUniversityList() async {
    final universities = await _service.filterUniversities(
      city: _selectedCities,
      major: _selectedMajors,
      budget: _selectedBudgets,
      searchQuery: _searchQuery,
    );
    setState(() {
      _universities = universities;
    });
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        cities: _cities,
        majors: _majors,
        budgets: [
          '500,000 ₸ және одан төмен',
          '500,000 - 1,000,000 ₸',
          '1,000,000 - 2,000,000 ₸',
          '2,000,000 ₸ және одан жоғары',
        ],
        selectedCity: _selectedCities,
        selectedMajor: _selectedMajors,
        selectedBudget: _selectedBudgets,
        onApply: (cities, majors, budgets) {
          setState(() {
            _selectedCities = cities;
            _selectedMajors = majors;
            _selectedBudgets = budgets;
            _updateUniversityList();
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.navSearch ?? 'Search'),
      ),
      body: Column(
        children: [
          // Premium Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText:
                          AppLocalizations.of(context)?.searchHint ??
                          'Search...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (v) {
                      setState(() {
                        _searchQuery = v;
                        _updateUniversityList();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _showFilterModal,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Icon(Icons.tune, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          // Active Chips (optional if space allows)
          Expanded(
            child: _universities.isEmpty
                ? const Center(child: Text('No results found'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _universities.length,
                    itemBuilder: (context, index) {
                      final uni = _universities[index];
                      return UniversityCard(
                        universityId: uni.id,
                        name: uni.name,
                        city: uni.city,
                        logoUrl: uni.logoUrl,
                        features: [uni.tuitionRange],
                        isFavorite: _favoriteIds.contains(uni.id),
                        isInComparison: _comparisonIds.contains(uni.id),
                        likesCount: uni.likesCount,
                        reviewsCount: uni.reviewsCount,
                        averageRating: uni.averageRating,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  UniversityDetailScreen(university: uni),
                            ),
                          ).then((_) => _loadData());
                        },
                        onFavoriteToggle: () async {
                          if (_favoriteIds.contains(uni.id)) {
                            await _service.removeFromFavorites(uni.id);
                          } else {
                            await _service.addToFavorites(uni.id);
                          }
                          _loadData();
                        },
                        onCompareToggle: () async {
                          if (_comparisonIds.contains(uni.id)) {
                            await _comparisonService.removeFromComparison(
                              uni.id,
                            );
                          } else {
                            await _comparisonService.addToComparison(uni.id);
                          }
                          _loadData();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
