import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

class FilterBottomSheet extends StatefulWidget {
  final List<String> cities;
  final List<Map<String, dynamic>> majors;
  final List<String> budgets;
  final List<String> selectedCity;
  final List<String> selectedMajor;
  final List<String> selectedBudget;
  final Function(List<String>, List<String>, List<String>) onApply;

  const FilterBottomSheet({
    super.key,
    required this.cities,
    required this.majors,
    required this.budgets,
    required this.selectedCity,
    required this.selectedMajor,
    required this.selectedBudget,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  final List<String> _city = [];
  final List<String> _major = [];
  final List<String> _budget = [];

  @override
  void initState() {
    super.initState();
    _city.addAll(widget.selectedCity);
    _major.addAll(widget.selectedMajor);
    _budget.addAll(widget.selectedBudget);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n?.filterTitle ?? 'Filters',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildFilterSection(
            l10n?.filterCity ?? 'City',
            widget.cities,
            _city,
            (val, selected) => setState(() {
              if (selected) {
                _city.add(val);
              } else {
                _city.remove(val);
              }
            }),
            theme,
          ),
          const SizedBox(height: 20),
          _buildFilterSection(
            l10n?.filterMajor ?? 'Major',
            widget.majors.map((m) => m['name'] as String).toList(),
            _major,
            (val, selected) => setState(() {
              if (selected) {
                _major.add(val);
              } else {
                _major.remove(val);
              }
            }),
            theme,
          ),
          const SizedBox(height: 20),
          _buildFilterSection(
            l10n?.filterBudget ?? 'Budget',
            widget.budgets,
            _budget,
            (val, selected) => setState(() {
              if (selected) {
                _budget.add(val);
              } else {
                _budget.remove(val);
              }
            }),
            theme,
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _city.clear();
                    _major.clear();
                    _budget.clear();
                  });
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
                child: Text(
                  l10n?.filterClear ?? 'Reset',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onApply(_city, _major, _budget);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    l10n?.filterShowResults ?? 'Apply',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(
    String title,
    List<String> options,
    List<String> selected,
    Function(String, bool) onSelect,
    ThemeData theme,
  ) {
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white70 : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: options.map((opt) {
              final isSelected = selected.contains(opt);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(opt),
                  selected: isSelected,
                  onSelected: (s) => onSelect(opt, s),
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white : AppColors.textPrimary),
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  backgroundColor: isDark
                      ? const Color(0xFF334155)
                      : Colors.white,
                  showCheckmark: true,
                  checkmarkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? Colors.white10 : Colors.grey.shade300),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
