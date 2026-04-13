import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../services/roi_calculator_service.dart';
import '../theme/app_colors.dart';
import '../models/profession.dart';
import '../models/university.dart';
import '../models/roi_models.dart';

class RoiScreen extends ConsumerStatefulWidget {
  const RoiScreen({super.key});

  @override
  ConsumerState<RoiScreen> createState() => _RoiScreenState();
}

class _RoiScreenState extends ConsumerState<RoiScreen> {
  final RoiCalculatorService _service = RoiCalculatorService();

  Profession? _selectedProfession;
  University? _selectedUniversity;
  bool _isGrant = false;
  int _yearsToCalculate = 10;
  bool _includeLivingCosts = true;
  bool _isHonorStudent = false;
  bool _worksWhileStudying = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final fintech = _calculateAnalysis();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.roiCalculatorTitle,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () => _showInfoDialog(l10n),
          ),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(l10n, theme),
                  const SizedBox(height: 32),
                  _buildPickerSection(l10n),
                  const SizedBox(height: 32),
                  _buildOptionsCard(l10n),
                  const SizedBox(height: 40),
                  if (fintech != null) ...[
                    _buildFinTechDashboard(l10n, fintech),
                    const SizedBox(height: 32),
                    _buildCashFlowChart(l10n, fintech),
                    const SizedBox(height: 60),
                  ] else
                    _buildEmptyState(l10n, theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  FinTechResult? _calculateAnalysis() {
    if (_selectedProfession == null || _selectedUniversity == null) return null;
    return _service.calculateFinTech(
      profession: _selectedProfession!,
      university: _selectedUniversity!,
      isGrant: _isGrant,
      yearsToCalculate: _yearsToCalculate,
      includeLivingCosts: _includeLivingCosts,
      isHonorStudent: _isHonorStudent,
      worksWhileStudying: _worksWhileStudying,
    );
  }

  void _showInfoDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.roiInfoTitle),
        content: Text(l10n.roiInfoContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  // ─── UI Builders ─────────────────────────────────────────────────────────

  Widget _buildHeader(AppLocalizations l10n, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            l10n.roiScreenPremiumLabel.toUpperCase(),
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.roiScreenHeadline,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.roiScreenSubheadline,
          style: TextStyle(
            fontSize: 15,
            color: theme.hintColor,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildPickerSection(AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(l10n.roiInitialData, theme),
        const SizedBox(height: 16),
        _buildMainPickerCard(
          label: l10n.roiLabelProfession,
          value: _selectedProfession?.name ?? l10n.roiChooseProfession,
          icon: Icons.work_outline_rounded,
          onTap: _showProfessionPicker,
          isSelected: _selectedProfession != null,
        ),
        const SizedBox(height: 16),
        _buildMainPickerCard(
          label: l10n.roiLabelUniversity,
          value: _selectedUniversity?.name ?? l10n.roiChooseUniversity,
          icon: Icons.account_balance_rounded,
          onTap: _showUniversityPicker,
          isSelected: _selectedUniversity != null,
        ),
      ],
    );
  }

  Widget _buildMainPickerCard({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : theme.dividerColor.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : theme.dividerColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.primary : theme.hintColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: theme.hintColor, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: theme.hintColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsCard(AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(l10n.roiOptionsTitle, theme),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              _buildSegmentedControl<bool>(
                label: l10n.roiFundingType,
                options: {false: l10n.roiPaid, true: l10n.roiGrant},
                currentValue: _isGrant,
                onChanged: (v) => setState(() => _isGrant = v),
              ),
              const SizedBox(height: 20),
              _buildSegmentedControl<int>(
                label: l10n.roiYearsLabel,
                options: {5: '5', 10: '10', 15: '15', 20: '20'},
                currentValue: _yearsToCalculate,
                onChanged: (v) => setState(() => _yearsToCalculate = v),
                suffix: ' ${l10n.roiYearsSuffix}',
              ),
              const SizedBox(height: 20),
              _buildSwitchRow(
                label: l10n.roiLivingCosts,
                value: _includeLivingCosts,
                onChanged: (v) => setState(() => _includeLivingCosts = v),
              ),
              const SizedBox(height: 12),
              _buildSwitchRow(
                label: l10n.roiHonorStudent,
                value: _isHonorStudent,
                onChanged: (v) => setState(() => _isHonorStudent = v),
                icon: Icons.auto_awesome_rounded,
                iconColor: Colors.amber,
              ),
              const SizedBox(height: 12),
              _buildSwitchRow(
                label: l10n.roiWorkWhileStudying,
                value: _worksWhileStudying,
                onChanged: (v) => setState(() => _worksWhileStudying = v),
                icon: Icons.work_outline_rounded,
                iconColor: AppColors.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.analytics_outlined,
                size: 48,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.roiEmptyStateTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.roiEmptyStateSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.hintColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: theme.hintColor,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildSegmentedControl<T>({
    required String label,
    required Map<T, String> options,
    required T currentValue,
    required ValueChanged<T> onChanged,
    String suffix = '',
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: options.entries.map((e) {
              final isSelected = e.key == currentValue;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onChanged(e.key);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? theme.cardColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${e.value}$suffix',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? theme.textTheme.bodyLarge?.color : theme.hintColor,
                      ),
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

  Widget _buildSwitchRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    IconData? icon,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: iconColor ?? theme.hintColor),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildFinTechDashboard(AppLocalizations l10n, FinTechResult fintech) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle(l10n.roiFinTechDashboard, theme),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getRatingColor(fintech.score).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getRatingText(fintech.score, l10n),
                style: TextStyle(
                  color: _getRatingColor(fintech.score),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildMetricTile(
              l10n.roiPaybackPeriod,
              fintech.paybackLabel,
              Icons.timer_outlined,
              Colors.orange,
            ),
            _buildMetricTile(
              l10n.roiTotalProfit,
              RoiCalculatorService.formatMoney(fintech.netProfit.toInt()),
              Icons.trending_up_rounded,
              AppColors.success,
            ),
            _buildMetricTile(
              l10n.roiInvestmentEfficiency,
              '${fintech.roi.toStringAsFixed(0)}%',
              Icons.bolt_rounded,
              Colors.purple,
            ),
            _buildMetricTile(
              l10n.roiMonthlyBalance,
              RoiCalculatorService.formatMoney(fintech.monthlyFreeCash.toInt()),
              Icons.account_balance_wallet_outlined,
              Colors.blue,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 11, color: theme.hintColor, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCashFlowChart(AppLocalizations l10n, FinTechResult fintech) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(l10n.roiCashFlowChartTitle, theme),
        const SizedBox(height: 16),
        Container(
          height: 240,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: fintech.yearlyBalance.asMap().entries.map((entry) {
                    final index = entry.key;
                    final value = entry.value;
                    final maxVal = fintech.yearlyBalance.isEmpty ? 1 : fintech.yearlyBalance.reduce((a, b) => a > b ? a : b);
                    final heightFactor = (value / (maxVal > 0 ? maxVal : 1)).clamp(0.1, 1.0);
                    
                    return Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 140 * heightFactor,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppColors.primary,
                                  AppColors.primary.withValues(alpha: 0.3),
                                ],
                              ),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            index == 0 ? 'Now' : '${index + 1}y',
                            style: TextStyle(fontSize: 10, color: theme.hintColor),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getRatingColor(double score) {
    if (score >= 0.8) return AppColors.success;
    if (score >= 0.5) return Colors.orange;
    return AppColors.error;
  }

  String _getRatingText(double score, AppLocalizations l10n) {
    if (score >= 0.8) return l10n.roiRatingExcellent;
    if (score >= 0.5) return l10n.roiRatingGood;
    return l10n.roiRatingPoor;
  }

  void _showProfessionPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ModernProfessionPicker(
        professions: _service.getProfessions(),
        onSelect: (prof) {
          setState(() => _selectedProfession = prof);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showUniversityPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ModernUniversityPicker(
        universities: _service.getUniversities(),
        onSelect: (uni) {
          setState(() => _selectedUniversity = uni);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _ModernProfessionPicker extends StatelessWidget {
  final List<Profession> professions;
  final ValueChanged<Profession> onSelect;

  const _ModernProfessionPicker({
    required this.professions,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.roiLabelProfession,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: professions.length,
                itemBuilder: (context, index) {
                  final prof = professions[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => onSelect(prof),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.rocket_launch_rounded, color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    prof.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${l10n.roiAverageSalary}: ${RoiCalculatorService.formatMoney(prof.startSalary)}',
                                    style: TextStyle(color: theme.hintColor, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernUniversityPicker extends StatelessWidget {
  final List<University> universities;
  final ValueChanged<University> onSelect;

  const _ModernUniversityPicker({
    required this.universities,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.roiLabelUniversity,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: universities.length,
                itemBuilder: (context, index) {
                  final uni = universities[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => onSelect(uni),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.purple.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.school_rounded, color: Colors.purple, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    uni.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${l10n.roiAnnualTuition}: ${RoiCalculatorService.formatMoney(uni.maxTuitionValue.toInt())}',
                                    style: TextStyle(color: theme.hintColor, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.add_circle_outline_rounded, color: Colors.purple),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
