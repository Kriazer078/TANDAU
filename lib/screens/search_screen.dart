import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/university_service.dart';
import '../utils/guest_guard.dart';
import '../widgets/compare_picker_sheet.dart';
import '../widgets/filter_bottom_sheet.dart';
import 'university_list_screen.dart';
import '../l10n/app_localizations.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final UniversityService _service = UniversityService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  final List<String> _searchHistory = [];

  final List<String> _selectedCities = [];
  final List<String> _selectedMajors = [];
  bool _onlyGrants = false;
  double? _maxPrice;

  List<String> _cities = [];
  List<Map<String, dynamic>> _majors = [];
  bool _isLoading = true;

  // Quick-access departments with icons
  List<Map<String, dynamic>> get _featuredMajors {
    final l10n = AppLocalizations.of(context);
    final String locale = l10n?.localeName ?? 'en';

    if (locale == 'ru') {
      return [
        {
          'name': 'IT',
          'icon': Icons.computer_rounded,
          'color': const Color(0xFF3B82F6),
        },
        {
          'name': 'Медицина',
          'icon': Icons.medical_services_rounded,
          'color': const Color(0xFFEF4444),
        },
        {
          'name': 'Бизнес',
          'icon': Icons.business_center_rounded,
          'color': const Color(0xFFF97316),
        },
        {
          'name': 'Инженерия',
          'icon': Icons.engineering_rounded,
          'color': const Color(0xFF22C55E),
        },
        {
          'name': 'Право',
          'icon': Icons.gavel_rounded,
          'color': const Color(0xFF8B5CF6),
        },
        {
          'name': 'Искусство',
          'icon': Icons.palette_rounded,
          'color': const Color(0xFFEC4899),
        },
      ];
    } else if (locale == 'kk') {
      return [
        {
          'name': 'IT',
          'icon': Icons.computer_rounded,
          'color': const Color(0xFF3B82F6),
        },
        {
          'name': 'Медицина',
          'icon': Icons.medical_services_rounded,
          'color': const Color(0xFFEF4444),
        },
        {
          'name': 'Бизнес',
          'icon': Icons.business_center_rounded,
          'color': const Color(0xFFF97316),
        },
        {
          'name': 'Инженерия',
          'icon': Icons.engineering_rounded,
          'color': const Color(0xFF22C55E),
        },
        {
          'name': 'Заң',
          'icon': Icons.gavel_rounded,
          'color': const Color(0xFF8B5CF6),
        },
        {
          'name': 'Өнер',
          'icon': Icons.palette_rounded,
          'color': const Color(0xFFEC4899),
        },
      ];
    }
    return [
      {
        'name': 'IT',
        'icon': Icons.computer_rounded,
        'color': const Color(0xFF3B82F6),
      },
      {
        'name': 'Medicine',
        'icon': Icons.medical_services_rounded,
        'color': const Color(0xFFEF4444),
      },
      {
        'name': 'Business',
        'icon': Icons.business_center_rounded,
        'color': const Color(0xFFF97316),
      },
      {
        'name': 'Engineering',
        'icon': Icons.engineering_rounded,
        'color': const Color(0xFF22C55E),
      },
      {
        'name': 'Law',
        'icon': Icons.gavel_rounded,
        'color': const Color(0xFF8B5CF6),
      },
      {
        'name': 'Art',
        'icon': Icons.palette_rounded,
        'color': const Color(0xFFEC4899),
      },
    ];
  }

  int get _activeFilterCount {
    int count = 0;
    count += _selectedCities.length;
    count += _selectedMajors.length;
    if (_onlyGrants) count++;
    if (_maxPrice != null) count++;
    return count;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final cities = await _service.getUniqueCities();
      final majors = await _service.getUniqueMajors();
      if (mounted) {
        setState(() {
          _cities = cities;
          _majors = majors.map((m) => {'name': m}).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading filter data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _performSearch(String query) {
    // Save to history
    if (query.isNotEmpty && !_searchHistory.contains(query)) {
      setState(() {
        _searchHistory.insert(0, query);
        if (_searchHistory.length > 5) _searchHistory.removeLast();
      });
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UniversityListScreen(
          searchQuery: query,
          cityFilter: _selectedCities,
          majorFilter: _selectedMajors,
          onlyGrants: _onlyGrants,
          maxPrice: _maxPrice,
        ),
      ),
    );
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (context) => FilterBottomSheet(
        cities: _cities,
        majors: _majors,
        selectedCity: _selectedCities,
        selectedMajor: _selectedMajors,
        initialOnlyGrants: _onlyGrants,
        initialMaxPrice: _maxPrice,
        onApply: (cities, majors, onlyGrants, maxPrice) {
          setState(() {
            _selectedCities.clear();
            _selectedCities.addAll(cities);
            _selectedMajors.clear();
            _selectedMajors.addAll(majors);
            _onlyGrants = onlyGrants;
            _maxPrice = maxPrice;
          });
          _performSearch(_searchController.text);
        },
      ),
    );
  }

  void _clearAllFilters() {
    setState(() {
      _selectedCities.clear();
      _selectedMajors.clear();
      _onlyGrants = false;
      _maxPrice = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    final String labelDepartments = (l10n?.localeName == 'ru')
        ? 'Специальности'
        : (l10n?.localeName == 'kk' ? 'Мамандықтар' : 'Departments');
    final String labelPopularCities = (l10n?.localeName == 'ru')
        ? 'Популярные города'
        : (l10n?.localeName == 'kk' ? 'Танымал қалалар' : 'Popular Cities');
    final String labelHistory = (l10n?.localeName == 'ru')
        ? 'История поиска'
        : (l10n?.localeName == 'kk' ? 'Іздеу тарихы' : 'Search History');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n?.navSearch ?? 'Search'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ═══ Search Bar + Filter Button ═══
                  _buildSearchBar(isDark, theme, l10n),

                  // ═══ Active Filters Chips ═══
                  if (_activeFilterCount > 0)
                    _buildActiveFilters(isDark, theme, l10n),

                  // ═══ Quick Departments ═══
                  _buildSectionHeader(labelDepartments, isDark, theme),
                  const SizedBox(height: 12),
                  _buildDepartmentGrid(isDark),

                  const SizedBox(height: 24),

                  // ═══ Popular Cities ═══
                  _buildSectionHeader(labelPopularCities, isDark, theme),
                  const SizedBox(height: 12),
                  _buildCityChips(isDark, theme),

                  const SizedBox(height: 24),

                  // ═══ Search History ═══
                  if (_searchHistory.isNotEmpty) ...[
                    _buildHistorySection(labelHistory, isDark, theme, l10n),
                  ],

                  const SizedBox(height: 100), // padding for bottom button
                ],
              ),
            ),
      // ═══ Bottom Search Button ═══
      bottomNavigationBar: _buildSearchButton(isDark, l10n),
    );
  }

  // ═════════════════════════════════════════
  // SEARCH BAR
  // ═════════════════════════════════════════
  Widget _buildSearchBar(bool isDark, ThemeData theme, AppLocalizations? l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          // Search field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                ),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                onSubmitted: (val) => _performSearch(val),
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: l10n?.searchHint ?? 'Поиск университета...',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white38 : AppColors.textHint,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: isDark ? Colors.white38 : AppColors.textHint,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: isDark ? Colors.white38 : Colors.grey,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onChanged: (_) => setState(() {}), // update clear button
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Filter button with badge
          GestureDetector(
            onTap: _showFilterModal,
            child: Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF60A5FA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
                  // Badge
                  if (_activeFilterCount > 0)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$_activeFilterCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════
  // ACTIVE FILTERS (horizontal chips showing selected filters)
  // ═════════════════════════════════════════
  Widget _buildActiveFilters(
    bool isDark,
    ThemeData theme,
    AppLocalizations? l10n,
  ) {
    final List<_ActiveFilter> filters = [];

    for (final city in _selectedCities) {
      filters.add(_ActiveFilter(label: city, type: 'city'));
    }
    for (final major in _selectedMajors) {
      filters.add(_ActiveFilter(label: major, type: 'major'));
    }
    if (_onlyGrants) {
      final label = (l10n?.localeName == 'ru')
          ? 'Грант'
          : (l10n?.localeName == 'kk' ? 'Грант' : 'Grant');
      filters.add(_ActiveFilter(label: label, type: 'grant'));
    }
    if (_maxPrice != null) {
      filters.add(
        _ActiveFilter(
          label: '≤ ${(_maxPrice! / 1000).toStringAsFixed(0)}K ₸',
          type: 'price',
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: filters.length + 1, // +1 for "clear all"
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                if (index == filters.length) {
                  // Clear all button
                  return GestureDetector(
                    onTap: _clearAllFilters,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n?.filterClear ?? 'Сбросить',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final filter = filters[index];
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        filter.label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            switch (filter.type) {
                              case 'city':
                                _selectedCities.remove(filter.label);
                                break;
                              case 'major':
                                _selectedMajors.remove(filter.label);
                                break;
                              case 'grant':
                                _onlyGrants = false;
                                break;
                              case 'price':
                                _maxPrice = null;
                                break;
                            }
                          });
                        },
                        child: Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════
  // SECTION HEADER
  // ═════════════════════════════════════════
  Widget _buildSectionHeader(String title, bool isDark, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
      ),
    );
  }

  // ═════════════════════════════════════════
  // DEPARTMENT GRID (2 rows, horizontal scroll)
  // ═════════════════════════════════════════
  Widget _buildDepartmentGrid(bool isDark) {
    final majors = _featuredMajors;

    return SizedBox(
      height: 100,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: majors.length,
        itemBuilder: (context, index) {
          final major = majors[index];
          final Color color = major['color'] as Color;
          final bool isSelected = _selectedMajors.contains(major['name']);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (!_selectedMajors.contains(major['name'])) {
                    _selectedMajors.add(major['name'] as String);
                  }
                });
                _performSearch(major['name'] as String);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 58,
                    width: 58,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color
                          : color.withValues(alpha: isDark ? 0.2 : 0.1),
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: color, width: 2)
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      major['icon'] as IconData,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? color : color),
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 68,
                    child: Text(
                      major['name'] as String,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? (major['color'] as Color)
                            : (isDark
                                  ? Colors.white70
                                  : AppColors.textSecondary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ═════════════════════════════════════════
  // CITY CHIPS
  // ═════════════════════════════════════════
  Widget _buildCityChips(bool isDark, ThemeData theme) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _cities.length,
        itemBuilder: (context, index) {
          final city = _cities[index];
          final isSelected = _selectedCities.contains(city);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (!_selectedCities.contains(city)) {
                    _selectedCities.add(city);
                  }
                });
                _performSearch(city);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? const Color(0xFF1E293B) : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? Colors.white12 : Colors.grey.shade300),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : (isDark
                            ? null
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 1),
                                ),
                              ]),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white54 : AppColors.textHint),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      city,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white70 : AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ═════════════════════════════════════════
  // HISTORY SECTION
  // ═════════════════════════════════════════
  Widget _buildHistorySection(
    String label,
    bool isDark,
    ThemeData theme,
    AppLocalizations? l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() => _searchHistory.clear());
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(l10n?.filterClear ?? 'Очистить'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _searchHistory.length,
          itemBuilder: (context, index) {
            final item = _searchHistory[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListTile(
                dense: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: Icon(
                  Icons.history_rounded,
                  size: 20,
                  color: isDark ? Colors.white38 : Colors.grey.shade400,
                ),
                title: Text(
                  item,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : AppColors.textPrimary,
                  ),
                ),
                trailing: Icon(
                  Icons.north_west_rounded,
                  size: 14,
                  color: isDark ? Colors.white24 : Colors.grey.shade400,
                ),
                onTap: () {
                  _searchController.text = item;
                  _performSearch(item);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  // ═════════════════════════════════════════
  // BOTTOM SEARCH BUTTON
  // ═════════════════════════════════════════
  Widget _buildSearchButton(bool isDark, AppLocalizations? l10n) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
        ),
      ),
      child: Row(
        children: [
          // ── Search button ──
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: () => _performSearch(_searchController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      l10n?.navSearch ?? 'Поиск',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_activeFilterCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '+$_activeFilterCount',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // ── Compare button ──
          SizedBox(
            height: 52,
            width: 52,
            child: Tooltip(
              message: l10n?.comparisonTitle ?? 'Compare',
              child: ElevatedButton(
                onPressed: () {
                  if (GuestGuard.check(context)) {
                    showComparePickerSheet(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Icon(Icons.compare_arrows_rounded, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper class for active filter display
class _ActiveFilter {
  final String label;
  final String type; // 'city', 'major', 'grant', 'price'

  _ActiveFilter({required this.label, required this.type});
}
