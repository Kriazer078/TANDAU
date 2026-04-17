import 'dart:async';
import 'package:flutter/material.dart';
import '../models/university.dart';
import '../services/university_service.dart';
import '../services/comparison_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import 'university_tile.dart';
import '../screens/comparison_screen.dart';

/// Reusable Compare Picker Bottom Sheet.
///
/// Opens a modal where the user selects up to 3 universities,
/// then navigates to [ComparisonScreen].
///
/// Usage:
/// ```dart
/// showComparePickerSheet(context);
/// ```
void showComparePickerSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const ComparePickerSheet(),
  );
}

/// The actual stateful bottom-sheet widget.
class ComparePickerSheet extends StatefulWidget {
  const ComparePickerSheet({super.key});

  @override
  State<ComparePickerSheet> createState() => _ComparePickerSheetState();
}

class _ComparePickerSheetState extends State<ComparePickerSheet> {
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
    try {
      final universities = await _service.getAllUniversities();
      final comparison = await ComparisonService().getUserComparison();
      final savedIds = comparison?.universityIds ?? [];

      final Set<University> initialSelected = {};
      if (savedIds.isNotEmpty) {
        for (var id in savedIds) {
          final match = universities.where((u) => u.id == id).toList();
          if (match.isNotEmpty) initialSelected.add(match.first);
        }
      }

      if (mounted) {
        setState(() {
          _universities = universities;
          _filteredUniversities = universities;
          _selected.addAll(initialSelected);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading universities for comparison: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
      } else if (_selected.length < 3) {
        _selected.add(uni);
      } else {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.comparisonFull(3) ?? 'Select max 3 universities',
            ),
          ),
        );
      }
    });
  }

  Future<void> _onCompare() async {
    if (_selected.isEmpty) return;

    final ids = _selected.map((u) => u.id).toList();
    await ComparisonService().setComparison(ids);

    if (!mounted) return;
    // Close the bottom sheet
    Navigator.pop(context);
    // Navigate to comparison screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ComparisonScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n?.comparisonTitle ?? 'University Comparison',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${_selected.length}/3',
                      style: TextStyle(
                        color: _selected.length == 3
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
                    hintText: l10n?.searchHint ?? 'Search University...',
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

                      return UniversityTile(
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
                    onPressed: _onCompare,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      l10n?.navComparison ?? 'Compare',
                      style: const TextStyle(
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
