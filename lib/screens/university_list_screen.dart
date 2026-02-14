import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/university.dart';
import '../services/university_service.dart';
import '../services/comparison_service.dart';
import '../widgets/university_card.dart';
import '../widgets/filter_bottom_sheet.dart';
import 'university_detail_screen.dart';
import 'favorites_screen.dart';
import 'comparison_screen.dart';
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

  // Local state for filters to allow individual removal
  late List<String> _selectedCities;
  late List<String> _selectedMajors;
  late List<String> _selectedBudgets;

  @override
  void initState() {
    super.initState();
    _searchQuery = widget.searchQuery ?? '';
    _searchController.text = _searchQuery;

    // Initialize local filter lists
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

  Future<void> _toggleFavorite(String universityId) async {
    if (_favoriteIds.contains(universityId)) {
      await _service.removeFromFavorites(universityId);
    } else {
      await _service.addToFavorites(universityId);
    }
    await _loadData();
  }

  Future<void> _toggleComparison(String universityId) async {
    debugPrint(
      '🔵 [UI] Toggle comparison called for university: $universityId',
    );
    final l10n = AppLocalizations.of(context);

    if (_comparisonIds.contains(universityId)) {
      debugPrint('🔵 [UI] Removing from comparison');
      await _comparisonService.removeFromComparison(universityId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.comparisonRemoved ?? 'Removed from comparison'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } else {
      debugPrint('🔵 [UI] Checking if can add more');
      final canAdd = await _comparisonService.canAddMore();
      debugPrint('🔵 [UI] Can add more: $canAdd');

      if (!canAdd) {
        debugPrint('⚠️ [UI] Cannot add - list is full');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                (l10n?.comparisonFull ?? 'Comparison list is full') as String,
              ),
              backgroundColor: AppColors.warning,
            ),
          );
        }
        return;
      }

      debugPrint('🔵 [UI] Calling addToComparison...');
      final success = await _comparisonService.addToComparison(universityId);
      debugPrint('🔵 [UI] Add result: $success');

      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.comparisonAdded ?? 'Added to comparison'),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (!success) {
        debugPrint('❌ [UI] Failed to add to comparison');
      }
    }

    debugPrint('🔵 [UI] Reloading data...');
    await _loadData();
    debugPrint(
      '✅ [UI] Data reloaded. Comparison count: ${_comparisonIds.length}',
    );
  }

  void _removeCityFilter(String city) {
    setState(() {
      _selectedCities.remove(city);
      _updateUniversityList();
    });
  }

  void _removeMajorFilter(String major) {
    setState(() {
      _selectedMajors.remove(major);
      _updateUniversityList();
    });
  }

  void _removeBudgetFilter(String budget) {
    setState(() {
      _selectedBudgets.remove(budget);
      _updateUniversityList();
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedCities.clear();
      _selectedMajors.clear();
      _selectedBudgets.clear();
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
            _selectedCities = List.from(cities);
            _selectedMajors = List.from(majors);
            _selectedBudgets = List.from(budgets);
            _updateUniversityList();
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.navSearch ?? 'Universities'),
        actions: [
          // Comparison button with badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.compare_arrows),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ComparisonScreen(),
                    ),
                  ).then((_) => _loadData());
                },
              ),
              if (_comparisonIds.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${_comparisonIds.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FavoritesScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar & Filter Button
          // Search Bar & Filter Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          AppLocalizations.of(context)?.searchHint ??
                          'Search University...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: isDark ? theme.cardColor : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: isDark
                            ? BorderSide.none
                            : BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: isDark
                            ? BorderSide.none
                            : BorderSide(color: Colors.grey.shade200),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _updateUniversityList();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: _showFilterModal,
                  highlightColor: Colors.transparent,
                  splashColor: theme.primaryColor.withValues(alpha: 0.1),
                  child: Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
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

          // Active Filters
          if (_selectedCities.isNotEmpty ||
              _selectedMajors.isNotEmpty ||
              _selectedBudgets.isNotEmpty)
            Container(
              padding: const EdgeInsets.only(top: 8, bottom: 6),
              color: isDark
                  ? theme.scaffoldBackgroundColor
                  : AppColors.background,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        ..._selectedCities.map(
                          (city) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildFilterChip(
                              label: city,
                              icon: Icons.location_city,
                              onDeleted: () => _removeCityFilter(city),
                              theme: theme,
                            ),
                          ),
                        ),
                        ..._selectedMajors.map(
                          (major) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildFilterChip(
                              label: major,
                              icon: Icons.work,
                              onDeleted: () => _removeMajorFilter(major),
                              theme: theme,
                            ),
                          ),
                        ),
                        ..._selectedBudgets.map(
                          (budget) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildFilterChip(
                              label: budget,
                              icon: Icons.attach_money,
                              onDeleted: () => _removeBudgetFilter(budget),
                              theme: theme,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: InkWell(
                        onTap: _clearFilters,
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Text(
                            AppLocalizations.of(context)?.filterClear ??
                                'Clear',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // University List
          Expanded(
            child: _universities.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)?.searchNoResults ??
                              'Universities not found',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: _universities.length,
                    itemBuilder: (context, index) {
                      final university = _universities[index];
                      final isFavorite = _favoriteIds.contains(university.id);
                      final isInComparison = _comparisonIds.contains(
                        university.id,
                      );

                      return UniversityCard(
                        universityId: university.id, // ⭐ Добавлено
                        name: university.name,
                        city: university.city,
                        logoUrl: university.logoUrl,
                        features: [
                          if (university.hasDormitory)
                            AppLocalizations.of(context)?.universityDormitory ??
                                'Dormitory',
                          if (university.hasGrants)
                            AppLocalizations.of(context)?.universityGrant ??
                                'Grant',
                          '${university.rating} ⭐',
                        ],
                        isFavorite: isFavorite,
                        isInComparison: isInComparison,
                        // ⭐ Новые параметры
                        likesCount: university.likesCount,
                        reviewsCount: university.reviewsCount,
                        averageRating: university.averageRating,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UniversityDetailScreen(
                                university: university,
                              ),
                            ),
                          );
                        },
                        onFavoriteToggle: () => _toggleFavorite(university.id),
                        onCompareToggle: () => _toggleComparison(university.id),
                      );
                    },
                  ),
          ),
        ],
      ),
      // ⭐ БОЛЬШАЯ КНОПКА СРАВНЕНИЯ
      floatingActionButton: _comparisonIds.isNotEmpty
          ? Stack(
              children: [
                FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ComparisonScreen(),
                      ),
                    ).then((_) => _loadData());
                  },
                  backgroundColor: AppColors.primary,
                  icon: const Icon(Icons.compare_arrows, color: Colors.white),
                  label: Text(
                    AppLocalizations.of(context)?.comparisonTitle ?? 'Compare',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Бейдж с количеством
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    child: Text(
                      '${_comparisonIds.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required VoidCallback onDeleted,
    required ThemeData theme,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return Chip(
      avatar: Icon(
        icon,
        size: 14,
        color: isDark ? Colors.white70 : theme.primaryColor,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.white : AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      onDeleted: onDeleted,
      deleteIcon: Icon(
        Icons.close,
        size: 14,
        color: isDark ? Colors.white70 : AppColors.textSecondary,
      ),
      backgroundColor: theme.primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
      side: BorderSide(color: theme.primaryColor.withValues(alpha: 0.1)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.all(4),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
