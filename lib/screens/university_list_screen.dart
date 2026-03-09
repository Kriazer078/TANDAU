import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';
import '../models/university.dart';
import '../services/university_service.dart';
import '../services/comparison_service.dart';
import '../widgets/university_card.dart';
import '../widgets/filter_bottom_sheet.dart';
import 'university_detail_screen.dart';
import '../widgets/compare_picker_sheet.dart';
import '../l10n/app_localizations.dart';

import '../services/auth_service.dart';
import '../models/comparison.dart';

class UniversityListScreen extends StatefulWidget {
  final List<String>? cityFilter;
  final List<String>? majorFilter;
  final bool? onlyGrants;
  final double? maxPrice;
  final String? searchQuery;

  const UniversityListScreen({
    super.key,
    this.cityFilter,
    this.majorFilter,
    this.onlyGrants,
    this.maxPrice,
    this.searchQuery,
  });

  @override
  State<UniversityListScreen> createState() => _UniversityListScreenState();
}

class _UniversityListScreenState extends State<UniversityListScreen> {
  Timer? _debounce;
  final UniversityService _service = UniversityService();
  final ComparisonService _comparisonService = ComparisonService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  List<University> _universities = [];
  String _searchQuery = '';

  List<String> _cities = [];
  List<Map<String, dynamic>> _majors = [];

  List<String> _selectedCities = [];
  List<String> _selectedMajors = [];
  bool _onlyGrants = false;
  double? _maxPrice;

  bool _isLoading = true;

  // ⚡ Cached reactive data — avoids nested builders inside ListView
  List<String> _comparisonIds = [];
  List<String> _favoriteIds = [];
  StreamSubscription<ComparisonItem?>? _comparisonSub;

  @override
  void initState() {
    super.initState();
    _searchQuery = widget.searchQuery ?? '';
    _searchController.text = _searchQuery;
    _selectedCities = List.from(widget.cityFilter ?? []);
    _selectedMajors = List.from(widget.majorFilter ?? []);
    _onlyGrants = widget.onlyGrants ?? false;
    _maxPrice = widget.maxPrice;
    _loadInitialData();

    // ⚡ Listen to comparison stream at state level, not inside build
    _comparisonSub = _comparisonService.getComparisonStream().listen((item) {
      if (!mounted) return;
      final ids = item?.universityIds ?? [];
      if (!_listEquals(ids, _comparisonIds)) {
        setState(() => _comparisonIds = ids);
      }
    });

    // ⚡ Listen to user favorites at state level
    _authService.currentUser.addListener(_onUserChanged);
    _favoriteIds = _authService.currentUser.value?.favoriteUniversities ?? [];
  }

  void _onUserChanged() {
    if (!mounted) return;
    final ids = _authService.currentUser.value?.favoriteUniversities ?? [];
    if (!_listEquals(ids, _favoriteIds)) {
      setState(() => _favoriteIds = ids);
    }
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _comparisonSub?.cancel();
    _authService.currentUser.removeListener(_onUserChanged);
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final cities = await _service.getUniqueCities();
      final majors = await _service.getUniqueMajors();

      if (!mounted) return;

      setState(() {
        _cities = cities;
        _majors = majors.map((m) => {'name': m}).toList();
      });
      await _updateUniversityList();
    } catch (e) {
      debugPrint('Error loading initial data: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateUniversityList() async {
    try {
      final universities = await _service.filterUniversities(
        city: _selectedCities,
        major: _selectedMajors,
        onlyGrants: _onlyGrants,
        maxPrice: _maxPrice,
        searchQuery: _searchQuery,
      );
      if (mounted) {
        setState(() {
          _universities = universities;
        });
      }
    } catch (e) {
      debugPrint('Error updating list: $e');
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = query;
      });
      _updateUniversityList();
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
        selectedCity: _selectedCities,
        selectedMajor: _selectedMajors,
        initialOnlyGrants: _onlyGrants,
        initialMaxPrice: _maxPrice,
        onApply: (cities, majors, onlyGrants, maxPrice) {
          setState(() {
            _selectedCities = cities;
            _selectedMajors = majors;
            _onlyGrants = onlyGrants;
            _maxPrice = maxPrice;
          });
          _updateUniversityList();
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
                      hintText: AppLocalizations.of(context)?.searchHint ??
                          'Search...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: _onSearchChanged,
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
          Expanded(
            child: _isLoading
                ? _buildShimmerLoading()
                : _universities.isEmpty
                    ? Center(
                        child: Text(
                          AppLocalizations.of(context)?.searchNoResults ??
                              'Universities not found',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    // ⚡ No more nested StreamBuilder/ValueListenableBuilder —
                    // comparison & favorite IDs are now cached in state fields,
                    // so only individual cards rebuild when data changes.
                    : ListView.builder(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _universities.length,
                        addRepaintBoundaries: true,
                        addAutomaticKeepAlives: false,
                        cacheExtent:
                            300, // ⚡ Pre-render 300px ahead for smooth scroll
                        itemBuilder: (context, index) {
                          final uni = _universities[index];
                          return UniversityCard(
                            universityId: uni.id,
                            name: uni.name,
                            city: uni.city,
                            logoUrl: uni.logoUrl,
                            features: [
                              uni.tuitionRange,
                              if (uni.hasGrants)
                                (AppLocalizations.of(
                                      context,
                                    )?.universityGrant ??
                                    'Grant'),
                            ],
                            isFavorite: _favoriteIds.contains(uni.id),
                            isInComparison: _comparisonIds.contains(uni.id),
                            likesCount: uni.likesCount,
                            reviewsCount: uni.reviewsCount,
                            averageRating: uni.averageRating,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UniversityDetailScreen(
                                    university: uni,
                                  ),
                                ),
                              );
                            },
                            onFavoriteToggle: () async {
                              if (_favoriteIds.contains(uni.id)) {
                                await _service.removeFromFavorites(uni.id);
                              } else {
                                await _service.addToFavorites(uni.id);
                              }
                            },
                            onCompareToggle: () async {
                              // Сначала добавим текущий университет в сравнение
                              if (!_comparisonIds.contains(uni.id)) {
                                await _comparisonService.addToComparison(
                                  uni.id,
                                );
                              }
                              // Открыть модальное окно для выбора
                              if (context.mounted) {
                                showComparePickerSheet(context);
                              }
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // SHIMMER SKELETON
  // ═══════════════════════════════════════════
  Widget _buildShimmerLoading() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final highlightColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: 6,
        itemBuilder: (context, _) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 110,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // Logo placeholder
                Container(
                  width: 80,
                  height: 110,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // University name
                      Container(
                        height: 14,
                        width: double.infinity,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(height: 12, width: 140, color: Colors.white),
                      const SizedBox(height: 12),
                      // Tags
                      Row(
                        children: [
                          Container(
                            height: 20,
                            width: 70,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            height: 20,
                            width: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
