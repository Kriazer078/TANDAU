import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/filter_chip_widget.dart';
import '../services/university_service.dart';
import 'university_list_screen.dart';
import '../l10n/app_localizations.dart';
import '../utils/l10n_extensions.dart';
import '../widgets/ai_logo_icon.dart';

class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  final UniversityService _service = UniversityService();

  int _currentStep = 0;
  final List<String> _selectedCities = [];
  final List<String> _selectedMajors = [];
  bool _onlyGrants = false;
  double _maxPrice = 1500000;
  bool _showPaid = false;
  bool _onlyMilitary = false;

  List<String> _cities = [];
  List<String> _majors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final cities = await _service.getUniqueCities();
    final majors = await _service.getUniqueMajors();
    if (mounted) {
      setState(() {
        _cities = cities;
        _majors = majors;
        _isLoading = false;
      });
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
    } else {
      _applyFilters();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _applyFilters() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => UniversityListScreen(
          cityFilter: _selectedCities,
          majorFilter: _selectedMajors,
          onlyGrants: _onlyGrants,
          maxPrice: _showPaid ? _maxPrice : null,
          onlyMilitary: _onlyMilitary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.filterTitle ?? 'Filters'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep > 0) {
              _previousStep();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Column(
        children: [
          // Progress Indicator
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: List.generate(3, (index) {
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                    height: 4,
                    decoration: BoxDecoration(
                      color: index <= _currentStep
                          ? AppColors.primary
                          : AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_currentStep == 0) _buildCitySelection(),
                  if (_currentStep == 1) _buildMajorSelection(),
                  if (_currentStep == 2) _buildBudgetSelection(),
                ],
              ),
            ),
          ),

          // Bottom Button
          Container(
            padding: const EdgeInsets.all(24),
            child: ElevatedButton(
              onPressed: (_currentStep == 0 && _selectedCities.isEmpty) ||
                      (_currentStep == 1 && _selectedMajors.isEmpty) ||
                      (_currentStep == 2 && (!_onlyGrants && !_showPaid))
                  ? null
                  : _nextStep,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(
                _currentStep < 2
                    ? (l10n?.filterNext ?? 'Next')
                    : (l10n?.filterShowResults ?? 'Show Results'),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCitySelection() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.filterCity ?? 'Which City?',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          l10n?.filterCitySubtitle ?? 'Choose the city where you want to study',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _cities.map((city) {
              final isSelected = _selectedCities.contains(city);
              return FilterChipWidget(
                label: city,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedCities.remove(city);
                    } else {
                      _selectedCities.add(city);
                    }
                  });
                },
                icon: Icons.location_city,
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildMajorSelection() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.filterMajor ?? 'Which Major?',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          l10n?.filterMajorSubtitle ?? 'Choose a major you are interested in',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _majors.map((major) {
              final isSelected = _selectedMajors.contains(major);
              return FilterChipWidget(
                label: major,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedMajors.remove(major);
                    } else {
                      _selectedMajors.add(major);
                    }
                  });
                },
                icon: Icons.work,
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildBudgetSelection() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.filterEducationType,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'Выберите подходящий тип обучения',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 24),
        FilterChipWidget(
          label: l10n.filterGrant,
          isSelected: _onlyGrants,
          onTap: () => setState(() => _onlyGrants = !_onlyGrants),
          iconWidget: AILogoIcon(
            size: 20,
            color: _onlyGrants
                ? Colors.white
                : (Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : AppColors.textPrimary),
          ),
        ),
        const SizedBox(height: 16),
        FilterChipWidget(
          label: l10n.filterPaid,
          isSelected: _showPaid,
          onTap: () => setState(() => _showPaid = !_showPaid),
          icon: Icons.payments_outlined,
        ),
        if (_showPaid) ...[
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.filterMaxPrice,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '${(_maxPrice / 1000).toStringAsFixed(0)}k ₸',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          Slider(
            value: _maxPrice,
            min: 300000,
            max: 4000000,
            divisions: 37,
            label: '${(_maxPrice / 1000).toStringAsFixed(0)}k ₸',
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => _maxPrice = val),
          ),
        ],
        const SizedBox(height: 24),
        FilterChipWidget(
          label: l10n?.filterMilitary ?? 'Военная кафедра',
          isSelected: _onlyMilitary,
          onTap: () => setState(() => _onlyMilitary = !_onlyMilitary),
          icon: Icons.shield_rounded,
        ),
      ],
    );
  }
}
