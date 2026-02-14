import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/university_service.dart';
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

  final List<String> _searchHistory = []; // Empty by default

  final List<String> _selectedCities = [];
  final List<String> _selectedMajors = [];
  final List<String> _selectedBudgets = [];

  List<String> _cities = [];
  List<Map<String, dynamic>> _majors = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final cities = await _service.getUniqueCities();
    final majors = await _service.getUniqueMajors();
    setState(() {
      _cities = cities;
      _majors = majors.map((m) => {'name': m}).toList();
    });
  }

  // Predefined majors with icons for better UI
  final List<Map<String, dynamic>> _featuredMajors = [
    {'name': 'IT', 'icon': Icons.computer, 'color': Colors.blue},
    {'name': 'Медицина', 'icon': Icons.medical_services, 'color': Colors.red},
    {'name': 'Бизнес', 'icon': Icons.business_center, 'color': Colors.orange},
    {'name': 'Инженерия', 'icon': Icons.engineering, 'color': Colors.green},
    {'name': 'Заң', 'icon': Icons.gavel, 'color': Colors.purple},
    {'name': 'Өнер', 'icon': Icons.palette, 'color': Colors.pink},
  ];

  final List<String> _budgets = [
    '500,000 ₸ және одан төмен',
    '500,000 - 1,000,000 ₸',
    '1,000,000 - 2,000,000 ₸',
    '2,000,000 ₸ және одан жоғары',
  ];

  void _performSearch(String query) {
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
          budgetFilter: _selectedBudgets,
        ),
      ),
    );
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        cities: _cities,
        majors: _majors,
        budgets: _budgets,
        selectedCity: _selectedCities,
        selectedMajor: _selectedMajors,
        selectedBudget: _selectedBudgets,
        onApply: (cities, majors, budgets) {
          setState(() {
            _selectedCities.clear();
            _selectedCities.addAll(cities);
            _selectedMajors.clear();
            _selectedMajors.addAll(majors);
            _selectedBudgets.clear();
            _selectedBudgets.addAll(budgets);
          });
          _performSearch(_searchController.text);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    // Hardcoded fallbacks because gen-l10n might not have run yet
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: (val) => _performSearch(val),
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: l10n?.searchHint ?? 'Search university...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: isDark ? theme.cardColor : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: isDark
                              ? BorderSide.none
                              : BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: _showFilterModal,
                    child: Container(
                      height: 55,
                      width: 55,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(Icons.tune, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            // Categories
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                labelDepartments,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              height: 110,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                scrollDirection: Axis.horizontal,
                itemCount: _featuredMajors.length,
                itemBuilder: (context, index) {
                  final major = _featuredMajors[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() {
                              if (!_selectedMajors.contains(major['name'])) {
                                _selectedMajors.add(major['name']);
                              }
                            });
                            _performSearch(major['name']);
                          },
                          child: Container(
                            height: 60,
                            width: 60,
                            decoration: BoxDecoration(
                              color: major['color'].withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(major['icon'], color: major['color']),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          major['name'],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.white70
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 15),

            // Popular Cities
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                labelPopularCities,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              height: 45,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _cities.length,
                itemBuilder: (context, index) {
                  final city = _cities[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ActionChip(
                      label: Text(
                        city,
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      backgroundColor: isDark ? theme.cardColor : Colors.white,
                      side: BorderSide(
                        color: isDark
                            ? theme.dividerColor
                            : Colors.grey.shade300,
                      ),
                      onPressed: () {
                        setState(() {
                          if (!_selectedCities.contains(city)) {
                            _selectedCities.add(city);
                          }
                        });
                        _performSearch(city);
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 30),

            // History Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    labelHistory,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  if (_searchHistory.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _searchHistory.clear();
                        });
                      },
                      child: Text(
                        l10n?.filterClear ?? 'Clear',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _searchHistory.length,
              itemBuilder: (context, index) {
                final item = _searchHistory[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  leading: const Icon(
                    Icons.history,
                    size: 20,
                    color: Colors.grey,
                  ),
                  title: Text(
                    item,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.north_west,
                    size: 14,
                    color: Colors.grey,
                  ),
                  onTap: () {
                    _searchController.text = item;
                    _performSearch(item);
                  },
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        child: ElevatedButton(
          onPressed: () => _performSearch(_searchController.text),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: Text(
            l10n?.navSearch ?? 'Search',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
