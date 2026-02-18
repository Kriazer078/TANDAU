import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../utils/l10n_extensions.dart';
import 'package:intl/intl.dart';

class FilterBottomSheet extends StatefulWidget {
  final List<String> cities;
  final List<Map<String, dynamic>> majors;
  final List<String> selectedCity;
  final List<String> selectedMajor;
  final bool initialOnlyGrants;
  final double? initialMaxPrice;
  final Function(
    List<String> cities,
    List<String> majors,
    bool onlyGrants,
    double? maxPrice,
  )
  onApply;

  const FilterBottomSheet({
    super.key,
    required this.cities,
    required this.majors,
    required this.selectedCity,
    required this.selectedMajor,
    required this.initialOnlyGrants,
    this.initialMaxPrice,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet>
    with SingleTickerProviderStateMixin {
  final List<String> _city = [];
  final List<String> _major = [];
  bool _onlyGrants = false;
  bool _showPaid = false;
  double _maxPrice = 1500000;

  String _citySearch = '';
  String _majorSearch = '';

  bool _cityExpanded = true;
  bool _majorExpanded = false;
  bool _typeExpanded = false;

  late final DraggableScrollableController _sheetController;

  @override
  void initState() {
    super.initState();
    _sheetController = DraggableScrollableController();
    _city.addAll(widget.selectedCity);
    _major.addAll(widget.selectedMajor);
    _onlyGrants = widget.initialOnlyGrants;
    if (widget.initialMaxPrice != null) {
      _showPaid = true;
      _maxPrice = widget.initialMaxPrice!;
    }
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  String _formatCurrency(double value) {
    final formatter = NumberFormat.compact(locale: 'ru_RU');
    return '${formatter.format(value)} ₸';
  }

  int get _activeFilterCount {
    int count = 0;
    count += _city.length;
    count += _major.length;
    if (_onlyGrants) count++;
    if (_showPaid) count++;
    return count;
  }

  void _resetAll() {
    setState(() {
      _city.clear();
      _major.clear();
      _onlyGrants = false;
      _showPaid = false;
      _maxPrice = 1500000;
      _citySearch = '';
      _majorSearch = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        // Auto-close when sheet is dragged to the very bottom
        if (notification.extent <= 0.05) {
          Navigator.of(context).pop();
        }
        return false;
      },
      child: Stack(
        children: [
          // Tap barrier (area above the sheet) → close
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              behavior: HitTestBehavior.translucent,
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
          // The actual sheet
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.75,
            minChildSize: 0.0,
            maxChildSize: 0.95,
            snap: true,
            snapSizes: const [0.0, 0.5, 0.75, 0.95],
            snapAnimationDuration: const Duration(milliseconds: 300),
            builder: (context, scrollController) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // ─── Handle + Header ───
                    _buildHeader(theme, l10n, isDark),

                    // ─── Scrollable content ───
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        physics: const ClampingScrollPhysics(),
                        children: [
                          // ═══ Section: Cities ═══
                          _buildExpandableSection(
                            title: l10n?.filterCity ?? 'Город',
                            icon: Icons.location_on_outlined,
                            isExpanded: _cityExpanded,
                            selectedCount: _city.length,
                            onToggle: () =>
                                setState(() => _cityExpanded = !_cityExpanded),
                            isDark: isDark,
                            theme: theme,
                            child: _buildCitySection(isDark, theme),
                          ),

                          const SizedBox(height: 8),

                          // ═══ Section: Majors ═══
                          _buildExpandableSection(
                            title: l10n?.filterMajor ?? 'Специальность',
                            icon: Icons.school_outlined,
                            isExpanded: _majorExpanded,
                            selectedCount: _major.length,
                            onToggle: () => setState(
                              () => _majorExpanded = !_majorExpanded,
                            ),
                            isDark: isDark,
                            theme: theme,
                            child: _buildMajorSection(isDark, theme),
                          ),

                          const SizedBox(height: 8),

                          // ═══ Section: Education Type ═══
                          _buildExpandableSection(
                            title: l10n.filterEducationType,
                            icon: Icons.payments_outlined,
                            isExpanded: _typeExpanded,
                            selectedCount:
                                (_onlyGrants ? 1 : 0) + (_showPaid ? 1 : 0),
                            onToggle: () =>
                                setState(() => _typeExpanded = !_typeExpanded),
                            isDark: isDark,
                            theme: theme,
                            child: _buildEducationTypeSection(
                              l10n,
                              isDark,
                              theme,
                            ),
                          ),

                          SizedBox(height: 24 + bottomPadding),
                        ],
                      ),
                    ),

                    // ─── Bottom Apply Button ───
                    _buildBottomBar(l10n, isDark, theme, bottomPadding),
                  ],
                ),
              );
            },
          ),
        ], // Stack children
      ), // Stack
    ); // NotificationListener
  }

  // ═════════════════════════════════════════
  // HEADER
  // ═════════════════════════════════════════
  Widget _buildHeader(ThemeData theme, AppLocalizations? l10n, bool isDark) {
    return Column(
      children: [
        // Drag handle
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Title + Reset
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.tune_rounded, size: 22, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text(
                    l10n?.filterTitle ?? 'Фильтры',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary,
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
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$_activeFilterCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (_activeFilterCount > 0)
                TextButton.icon(
                  onPressed: _resetAll,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(l10n?.filterClear ?? 'Сбросить'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Divider(
          height: 1,
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ═════════════════════════════════════════
  // EXPANDABLE SECTION WRAPPER
  // ═════════════════════════════════════════
  Widget _buildExpandableSection({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required int selectedCount,
    required VoidCallback onToggle,
    required bool isDark,
    required ThemeData theme,
    required Widget child,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selectedCount > 0
              ? AppColors.primary.withValues(alpha: 0.4)
              : (isDark ? Colors.white10 : Colors.grey.shade200),
          width: selectedCount > 0 ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          // Section Header (tap to expand/collapse)
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (selectedCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$selectedCount',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: isDark ? Colors.white54 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Animated content — use AnimatedSize instead of AnimatedCrossFade
          // to avoid gap/jump artifacts
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: isExpanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: child,
                    )
                  : const SizedBox(width: double.infinity, height: 0),
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════
  // CITY SECTION
  // ═════════════════════════════════════════
  Widget _buildCitySection(bool isDark, ThemeData theme) {
    final filteredCities = _citySearch.isEmpty
        ? widget.cities
        : widget.cities
              .where((c) => c.toLowerCase().contains(_citySearch.toLowerCase()))
              .toList();

    return Column(
      children: [
        // Search field inside the section
        if (widget.cities.length > 5)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildMiniSearch(
              hint: 'Поиск города...',
              value: _citySearch,
              onChanged: (v) => setState(() => _citySearch = v),
              isDark: isDark,
            ),
          ),

        // Chips in Wrap
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: filteredCities.map((city) {
            final isSelected = _city.contains(city);
            return _buildFilterChip(
              label: city,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _city.remove(city);
                  } else {
                    _city.add(city);
                  }
                });
              },
              isDark: isDark,
            );
          }).toList(),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════
  // MAJOR SECTION
  // ═════════════════════════════════════════
  Widget _buildMajorSection(bool isDark, ThemeData theme) {
    final allMajors = widget.majors.map((m) => m['name'] as String).toList();
    final filteredMajors = _majorSearch.isEmpty
        ? allMajors
        : allMajors
              .where(
                (m) => m.toLowerCase().contains(_majorSearch.toLowerCase()),
              )
              .toList();

    return Column(
      children: [
        // Search field inside the section
        if (allMajors.length > 5)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildMiniSearch(
              hint: 'Поиск специальности...',
              value: _majorSearch,
              onChanged: (v) => setState(() => _majorSearch = v),
              isDark: isDark,
            ),
          ),

        // Chips in Wrap
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: filteredMajors.map((major) {
            final isSelected = _major.contains(major);
            return _buildFilterChip(
              label: major,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _major.remove(major);
                  } else {
                    _major.add(major);
                  }
                });
              },
              isDark: isDark,
            );
          }).toList(),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════
  // EDUCATION TYPE SECTION
  // ═════════════════════════════════════════
  Widget _buildEducationTypeSection(
    AppLocalizations? l10n,
    bool isDark,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Grant + Paid chips
        Row(
          children: [
            _buildFilterChip(
              label: l10n.filterGrant,
              isSelected: _onlyGrants,
              onTap: () => setState(() => _onlyGrants = !_onlyGrants),
              isDark: isDark,
              icon: Icons.school_outlined,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: l10n.filterPaid,
              isSelected: _showPaid,
              onTap: () => setState(() => _showPaid = !_showPaid),
              isDark: isDark,
              icon: Icons.payments_outlined,
            ),
          ],
        ),

        // Price slider (smooth animated appear using AnimatedSize)
        ClipRect(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _showPaid
                ? Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n?.filterMaxPrice ?? 'Макс. цена',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? Colors.white70
                                    : AppColors.textSecondary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _formatCurrency(_maxPrice),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: AppColors.primary,
                            inactiveTrackColor: AppColors.primary.withValues(
                              alpha: 0.15,
                            ),
                            thumbColor: AppColors.primary,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 18,
                            ),
                            trackHeight: 4,
                          ),
                          child: Slider(
                            value: _maxPrice,
                            min: 300000,
                            max: 4000000,
                            divisions: 37,
                            onChanged: (val) => setState(() => _maxPrice = val),
                          ),
                        ),
                        // Min/Max labels
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatCurrency(300000),
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.white38
                                    : Colors.grey.shade400,
                              ),
                            ),
                            Text(
                              _formatCurrency(4000000),
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.white38
                                    : Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity, height: 0),
          ),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════
  // BOTTOM BAR (Apply Button)
  // ═════════════════════════════════════════
  Widget _buildBottomBar(
    AppLocalizations? l10n,
    bool isDark,
    ThemeData theme,
    double bottomPadding,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottomPadding),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onApply(
              _city,
              _major,
              _onlyGrants,
              _showPaid ? _maxPrice : null,
            );
          },
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
              const Icon(Icons.check_rounded, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n?.filterShowResults ?? 'Показать результаты',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════
  // REUSABLE: Mini Search Field
  // ═════════════════════════════════════════
  Widget _buildMiniSearch({
    required String hint,
    required String value,
    required ValueChanged<String> onChanged,
    required bool isDark,
  }) {
    return SizedBox(
      height: 40,
      child: TextField(
        onChanged: onChanged,
        style: TextStyle(
          fontSize: 13,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white38 : Colors.grey.shade400,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 18,
            color: isDark ? Colors.white38 : Colors.grey.shade400,
          ),
          filled: true,
          fillColor: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: isDark ? Colors.white12 : Colors.grey.shade300,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: isDark ? Colors.white12 : Colors.grey.shade300,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════
  // REUSABLE: Filter Chip
  // ═════════════════════════════════════════
  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? Colors.white12 : Colors.grey.shade300),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white54 : AppColors.textSecondary),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : AppColors.textPrimary),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              const Icon(Icons.check_rounded, size: 14, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }
}
