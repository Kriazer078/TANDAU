import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../widgets/premium_button.dart';
import '../providers/grant_predictor_provider.dart';
import '../data/ent_specialties_2026.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import 'ai_consultant_screen.dart';

class GrantWizardScreen extends ConsumerStatefulWidget {
  const GrantWizardScreen({super.key});

  @override
  ConsumerState<GrantWizardScreen> createState() => _GrantWizardScreenState();
}

class _GrantWizardScreenState extends ConsumerState<GrantWizardScreen> {
  // Local quota states loaded from profile
  bool _isRural = false;
  bool _isOrphan = false;
  bool _hasDisability = false;

  @override
  void initState() {
    super.initState();
    _loadQuotas();
  }

  void _loadQuotas() {
    final user = AuthService().currentUser.value;
    if (user != null) {
      setState(() {
        _isRural = user.isRural ?? false;
        _isOrphan = user.isOrphan ?? false;
        _hasDisability = user.hasDisability ?? false;
      });
      // Also sync Riverpod state with user's last choices safely
      Future.microtask(() {
        if (user.entSubject1 != null && ref.read(selectedSubjectPairProvider) == null) {
          ref.read(selectedSubjectPairProvider.notifier).state = user.entSubject1;
        }
        if (user.subjectType != null && ref.read(subjectTypeProvider) == null) {
          ref.read(subjectTypeProvider.notifier).state = user.subjectType;
        }
        if (user.untScore != null && user.untScore! > 0 && ref.read(untScoreProvider) == 50) {
          ref.read(untScoreProvider.notifier).state = user.untScore!;
        }
      });
    }
  }

  void _updateQuotas() {
    AuthService().updateProfile(
      isRural: _isRural,
      isOrphan: _isOrphan,
      hasDisability: _hasDisability,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final untScore = ref.watch(untScoreProvider);
    final selectedType = ref.watch(subjectTypeProvider);
    final selectedSubjectPair = ref.watch(selectedSubjectPairProvider);
    final selectedSpecialty = ref.watch(selectedSpecialtyProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Мастер оценки шансов',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepHeader('1. Балл ЕНТ', isDark),
              const SizedBox(height: 16),
              _buildScoreSlider(context, untScore, isDark, l10n),
              
              const SizedBox(height: 32),
              _buildStepHeader('2. Профильные предметы', isDark),
              const SizedBox(height: 16),
              _buildDirectionAndSubjects(selectedType, selectedSubjectPair, isDark, l10n),

              if (selectedType != null && selectedSubjectPair != null) ...[
                const SizedBox(height: 32),
                _buildStepHeader('3. Специальность (ГОП)', isDark),
                const SizedBox(height: 16),
                _buildSpecialtyDropdown(selectedType, selectedSubjectPair, selectedSpecialty, isDark, l10n),
              ],

              const SizedBox(height: 32),
              _buildStepHeader('4. Квоты и социальные льготы', isDark),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Заполнение квот позволит ИИ-консультанту значительно точнее рассчитать шансы на грант.',
                  style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13),
                ),
              ),
              const SizedBox(height: 8),
              _buildQuotaSwitches(isDark),

              const SizedBox(height: 48),
              
              // Proceed button
              PremiumButton(
                text: l10n?.detailChances ?? 'Рассчитать шансы',
                icon: Icons.insights_rounded,
                onPressed: () {
                  // Ensure current score is synced
                  AuthService().updateProfile(untScore: untScore);

                  // Build AI query from wizard data
                  final parts = <String>[];
                  parts.add('Мой балл ЕНТ: $untScore из 140.');
                  if (selectedSubjectPair != null) {
                    parts.add('Профильные предметы: $selectedSubjectPair.');
                  }
                  if (selectedSpecialty != null) {
                    parts.add(
                      'Выбранная специальность (ГОП): '
                      '${selectedSpecialty.titleRu} '
                      '(код ${selectedSpecialty.code}).',
                    );
                  }
                  if (_isRural) parts.add('У меня сельская квота.');
                  if (_isOrphan) parts.add('Я сирота (квота).');
                  if (_hasDisability) parts.add('У меня инвалидность (квота).');
                  parts.add(
                    'Оцени мои шансы на государственный грант. '
                    'Дай подробный анализ.',
                  );
                  final query = parts.join(' ');

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AIConsultantScreen(
                        initialQuery: query,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepHeader(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: isDark ? Colors.white : AppColors.textPrimary,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildScoreSlider(BuildContext context, int untScore, bool isDark, AppLocalizations? l10n) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ваш балл:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
               GestureDetector(
                onTap: () => _showScoreInputDialog(untScore),
                child: Container(
                  width: 80,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E40AF).withValues(alpha: 0.4)
                        : AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '$untScore',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? const Color(0xFF60A5FA)
                          : AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF38BDF8),
              inactiveTrackColor: isDark ? Colors.white12 : Colors.black12,
              thumbColor: const Color(0xFF38BDF8),
              overlayColor: const Color(0xFF38BDF8).withValues(alpha: 0.2),
              trackHeight: 4.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
            ),
            child: Slider(
              value: untScore.toDouble(),
              min: 0,
              max: 140,
              divisions: 140,
              onChanged: (value) {
                ref.read(untScoreProvider.notifier).state = value.round();
              },
              onChangeEnd: (value) {
                AuthService().updateProfile(untScore: value.round());
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionAndSubjects(String? selectedType, String? selectedSubjectPair, bool isDark, AppLocalizations? l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTypeButton(
                label: 'Физ-мат 🔬',
                value: 'physMath',
                selected: selectedType == 'physMath',
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTypeButton(
                label: 'Гуманитарий 📚',
                value: 'humanities',
                selected: selectedType == 'humanities',
                isDark: isDark,
              ),
            ),
          ],
        ),
        if (selectedType != null) ...[
          const SizedBox(height: 16),
          Text(
            'Выберите пару профильных предметов:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: (AppConstants.entSubjectPairsByType[selectedType] ?? [])
                .map(
                  (pair) => _buildSubjectPairChip(
                    label: pair,
                    selected: selectedSubjectPair == pair,
                    isDark: isDark,
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildTypeButton({
    required String label,
    required String value,
    required bool selected,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(subjectTypeProvider.notifier).state = value;
        ref.read(selectedSubjectPairProvider.notifier).state = null;
        ref.read(selectedSpecialtyProvider.notifier).state = null;
        AuthService().updateProfile(subjectType: value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.15)
              : isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : isDark
                    ? Colors.white12
                    : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.bold : FontWeight.w600,
              color: selected
                  ? AppColors.primary
                  : isDark
                      ? Colors.white60
                      : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectPairChip({
    required String label,
    required bool selected,
    required bool isDark,
  }) {
    // Получаем количество ГОП для этой пары
    final gopCount = getSpecialtiesBySubjectPair(label).length;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        ref.read(selectedSubjectPairProvider.notifier).state = label;
        ref.read(selectedSpecialtyProvider.notifier).state = null;
        AuthService().updateProfile(entSubject1: label);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.15)
              : isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : isDark
                    ? Colors.white10
                    : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected
                    ? AppColors.primary
                    : isDark
                        ? Colors.white70
                        : Colors.black87,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '$gopCount ГОП',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialtyDropdown(
    String subjectType,
    String subjectPair,
    EntSpecialty? currentSpecialty,
    bool isDark,
    AppLocalizations? l10n,
  ) {
    final specialties = getSpecialtiesBySubjectPair(subjectPair);

    if (specialties.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Нет специальностей для данной пары предметов',
          style: TextStyle(
            color: isDark ? Colors.white38 : Colors.black38,
            fontSize: 14,
          ),
        ),
      );
    }

    final locale = Localizations.localeOf(context).languageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.grey.shade300,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentSpecialty?.code,
              hint: Text(
                l10n?.selectSpecialty ?? 'Выберите специальность',
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black45,
                  fontSize: 14,
                ),
              ),
              isExpanded: true,
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: isDark ? Colors.white38 : Colors.black45,
              ),
              items: specialties.map((s) {
                return DropdownMenuItem<String>(
                  value: s.code,
                  child: Text(
                    '${s.quotaEmoji} ${s.getTitle(locale)} (${s.predictedMin2026}+)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (code) {
                if (code == null) return;
                final specialty = specialties.firstWhere((s) => s.code == code);
                ref.read(selectedSpecialtyProvider.notifier).state = specialty;
                HapticFeedback.selectionClick();
              },
            ),
          ),
        ),
        // Показать инфо о квоте выбранной специальности
        if (currentSpecialty != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                Text(
                  currentSpecialty.quotaEmoji,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentSpecialty.quotaDescription,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      Text(
                        'Проходной балл 2025: ${currentSpecialty.minScore2025} • Прогноз 2026: ${currentSpecialty.predictedMin2026}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white38 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (currentSpecialty.grantQuotaLevel == GrantQuotaLevel.low ||
              currentSpecialty.grantQuotaLevel == GrantQuotaLevel.veryLow) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Мало грантов — высокая конкуренция. Рассмотрите смежные ГОП.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.orange.shade200 : Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildQuotaSwitches(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildSwitchItem(
            'Сельская квота',
            Icons.agriculture_rounded,
            _isRural,
            (val) {
              setState(() => _isRural = val);
              _updateQuotas();
            },
            isDark,
          ),
          Divider(color: isDark ? Colors.white12 : Colors.grey.shade200, height: 16),
          _buildSwitchItem(
            'Квота для сирот',
            Icons.family_restroom_rounded,
            _isOrphan,
            (val) {
              setState(() => _isOrphan = val);
              _updateQuotas();
            },
            isDark,
          ),
          Divider(color: isDark ? Colors.white12 : Colors.grey.shade200, height: 16),
          _buildSwitchItem(
            'Инвалидность (I, II гр)',
            Icons.accessible_rounded,
            _hasDisability,
            (val) {
              setState(() => _hasDisability = val);
              _updateQuotas();
            },
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchItem(String title, IconData icon, bool value, ValueChanged<bool> onChanged, bool isDark) {
    return Row(
      children: [
        Icon(icon, color: isDark ? Colors.white54 : Colors.black54, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.primary,
        ),
      ],
    );
  }

  void _showScoreInputDialog(int currentScore) {
    final controller = TextEditingController(text: '$currentScore');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Введите балл ЕНТ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(3),
          ],
          decoration: InputDecoration(
            hintText: '0 – 140',
            filled: true,
            fillColor: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
          onSubmitted: (value) => _applyScoreFromText(value, ctx),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Отмена',
              style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
            ),
          ),
          FilledButton(
            onPressed: () => _applyScoreFromText(controller.text, ctx),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Готово'),
          ),
        ],
      ),
    );
  }

  void _applyScoreFromText(String text, BuildContext dialogCtx) {
    final parsed = int.tryParse(text.trim());
    if (parsed != null && parsed >= 0 && parsed <= 140) {
      ref.read(untScoreProvider.notifier).state = parsed;
      AuthService().updateProfile(untScore: parsed);
      Navigator.pop(dialogCtx);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Введите число от 0 до 140'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
