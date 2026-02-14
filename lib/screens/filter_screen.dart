import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/filter_chip_widget.dart';
import '../services/university_service.dart';
import 'university_list_screen.dart';
import '../l10n/app_localizations.dart';

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
  final List<String> _selectedBudgets = [];

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
    setState(() {
      _cities = cities;
      _majors = majors;
      _isLoading = false;
    });
  }

  final List<String> budgetOptions = [
    '500,000 ₸ және одан төмен',
    '500,000 - 1,000,000 ₸',
    '1,000,000 - 2,000,000 ₸',
    '2,000,000 ₸ және одан жоғары',
  ];

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
          budgetFilter: _selectedBudgets,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.filterTitle ?? 'Filters'),
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
              onPressed:
                  _currentStep == 0 && _selectedCities.isEmpty ||
                      _currentStep == 1 && _selectedMajors.isEmpty ||
                      _currentStep == 2 && _selectedBudgets.isEmpty
                  ? null
                  : _nextStep,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(
                _currentStep < 2
                    ? (AppLocalizations.of(context)?.filterNext ?? 'Next')
                    : (AppLocalizations.of(context)?.filterShowResults ??
                          'Show Results'),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCitySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)?.filterCity ?? 'Which City?',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)?.filterCitySubtitle ??
              'Choose the city where you want to study',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)?.filterMajor ?? 'Which Major?',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)?.filterMajorSubtitle ??
              'Choose a major you are interested in',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)?.filterBudget ?? 'What is your budget?',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)?.filterBudgetSubtitle ??
              'Select annual tuition fee range',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),

        Column(
          children: budgetOptions.map((budget) {
            final isSelected = _selectedBudgets.contains(budget);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FilterChipWidget(
                label: budget,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedBudgets.remove(budget);
                    } else {
                      _selectedBudgets.add(budget);
                    }
                  });
                },
                icon: Icons.attach_money,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
