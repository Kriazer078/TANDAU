import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// dart:ui removed — BackdropFilter replaced with lightweight frosted glass
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../utils/guest_guard.dart';
import '../utils/constants.dart';
import '../widgets/compare_picker_sheet.dart';
import '../widgets/premium_button.dart';
import 'filter_screen.dart';
import '../providers/grant_predictor_provider.dart';
import '../data/ent_specialties_2026.dart';
import 'grant_prediction_results_screen.dart';
import 'university_list_screen.dart';
import '../widgets/deadline_banner.dart';
import '../services/auth_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  bool get wantKeepAlive => true; // ⚡ Preserve state across tab switches

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    // ⚡ Stop controller after animation completes to free the Ticker
    _controller.forward().then((_) => _controller.stop());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    // Add haptic feedback for premium feel
    HapticFeedback.lightImpact();
    // Simulate network delay or refresh actual providers
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      ref.invalidate(untScoreProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // ⚡ Required by AutomaticKeepAliveClientMixin
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final untScore = ref.watch(untScoreProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _handleRefresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              _buildAppBar(theme, isDark),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          _buildGreetingSubtitle(l10n, theme, isDark),
                          const SizedBox(height: 16),
                          const DeadlineBanner(),
                          const SizedBox(height: 16),
                          _buildScoreInput(untScore, isDark, l10n),
                          const SizedBox(height: 24),
                          Text(
                            l10n?.homeTools ?? 'Инструменты',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildToolsRow(context, l10n, isDark),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(ThemeData theme, bool isDark) {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      expandedHeight: 120,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.school_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              AppLocalizations.of(context)?.appTitle ?? 'TANDAU',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolsRow(
    BuildContext context,
    AppLocalizations? l10n,
    bool isDark,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(
        right: 24,
      ), // Extra padding for the last item
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: _buildActionCard(
              context,
              title: l10n?.comparisonTitle ?? 'Сравнение',
              subtitle: l10n?.navComparison ?? 'Университеты',
              icon: Icons.compare_arrows_rounded,
              color: const Color(0xFF10B981),
              isDark: isDark,
              onTap: () {
                if (GuestGuard.check(context)) {
                  showComparePickerSheet(context);
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 160,
            child: _buildActionCard(
              context,
              title: l10n?.homeAdvancedFilter ?? 'Умный фильтр',
              subtitle: l10n?.filterTitle ?? 'Фильтры',
              icon: Icons.tune_rounded,
              color: const Color(0xFFF59E0B),
              isDark: isDark,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FilterScreen()),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 160,
            child: _buildActionCard(
              context,
              title: l10n?.homeUniversitySearch ?? 'Поиск ВУЗов',
              subtitle: l10n?.homeUniversities ?? 'Каталог',
              icon: Icons.search_rounded,
              color: const Color(0xFF6366F1),
              isDark: isDark,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const UniversityListScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingSubtitle(
    AppLocalizations? l10n,
    ThemeData theme,
    bool isDark,
  ) {
    // ⚡ Removed StreamBuilder — greeting is computed once per build,
    // not via a periodic timer that caused unnecessary 60s rebuilds.
    final hour = DateTime.now().hour;
    String greeting;
    if (hour >= 5 && hour < 12) {
      greeting = l10n?.homeGreetingMorning ?? 'Доброе утро';
    } else if (hour >= 12 && hour < 17) {
      greeting = l10n?.homeGreetingAfternoon ?? 'Добрый день';
    } else if (hour >= 17 && hour < 23) {
      greeting = l10n?.homeGreetingEvening ?? 'Добрый вечер';
    } else {
      greeting = l10n?.homeGreetingNight ?? 'Доброй ночи';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark ? Colors.white60 : Colors.black54,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n?.homeSubtitle ?? 'Найди свой путь в будущее',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
            height: 1.1,
            letterSpacing: -0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreInput(int untScore, bool isDark, AppLocalizations? l10n) {
    final selectedType = ref.watch(subjectTypeProvider);
    final selectedSubject = ref.watch(selectedSubjectProvider);
    final selectedSpecialty = ref.watch(selectedSpecialtyProvider);

    // Auto-load from profile if providers are empty
    final user = AuthService().currentUser.value;
    if (selectedType == null && user?.subjectType != null) {
      Future.microtask(() {
        ref.read(subjectTypeProvider.notifier).state = user!.subjectType;
      });
    }
    if (selectedSubject == null && user?.entSubject1 != null) {
      Future.microtask(() {
        ref.read(selectedSubjectProvider.notifier).state = user!.entSubject1;
      });
    }

    return Column(
      children: [
        // ── ENT Score Card ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : AppColors.border,
              width: 1,
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n?.homeEntScore ?? 'Ваш балл ЕНТ:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      letterSpacing: 0.3,
                    ),
                  ),
                  // Tappable score badge for precise input
                  GestureDetector(
                    onTap: () => _showScoreInputDialog(untScore),
                    child: Container(
                      width: 70,
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
              const SizedBox(height: 8),
              // Hint to tap
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  l10n?.scoreInputTapHint ??
                      'Нажмите на число для точного ввода',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white30 : Colors.black26,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: const Color(0xFF38BDF8),
                  inactiveTrackColor: isDark ? Colors.white12 : Colors.black12,
                  thumbColor: const Color(0xFF38BDF8),
                  overlayColor: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                  trackHeight: 4.0,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 10,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 20,
                  ),
                ),
                child: Slider(
                  value: untScore.toDouble(),
                  min: 0,
                  max: 140,
                  divisions: 140,
                  onChanged: (value) {
                    ref.read(untScoreProvider.notifier).state = value.round();
                  },
                ),
              ),

              // ── Step 1: Direction (физмат / гуманитарий) ──
              const SizedBox(height: 24),
              Text(
                l10n?.subjectTypeTitle ?? 'Направление ЕНТ',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildTypeButton(
                      label: l10n?.subjectTypePhysMath ?? 'Физ-мат 🔬',
                      value: 'physMath',
                      selected: selectedType == 'physMath',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTypeButton(
                      label: l10n?.subjectTypeHumanities ??
                          'Гуманитарий 📚',
                      value: 'humanities',
                      selected: selectedType == 'humanities',
                      isDark: isDark,
                    ),
                  ),
                ],
              ),

              // ── Step 2: Subject (profile subject) ──
              if (selectedType != null) ...[
                const SizedBox(height: 20),
                Text(
                  l10n?.entSubjectsTitle ?? 'Профильный предмет',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (AppConstants.entSubjectsByType[selectedType] ??
                          [])
                      .map(
                        (subject) => _buildSubjectChip(
                          label: subject,
                          selected: selectedSubject == subject,
                          isDark: isDark,
                        ),
                      )
                      .toList(),
                ),
              ],

              // ── Step 3: Specialty (ГОП) ──
              if (selectedSubject != null) ...[
                const SizedBox(height: 20),
                Text(
                  l10n?.selectSpecialty ?? 'Специальность (ГОП)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                _buildSpecialtyDropdown(
                  selectedType!,
                  selectedSubject,
                  selectedSpecialty,
                  isDark,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Evaluate button ──
        if (selectedSpecialty != null)
          PremiumButton(
            text: l10n?.detailChances ?? 'Оценить шансы',
            icon: Icons.insights_rounded,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GrantPredictionResultsScreen(
                    entScore: untScore,
                    specialty: selectedSpecialty,
                  ),
                ),
              );
            },
          )
        else
          PremiumButton(
            text: l10n?.detailChances ?? 'Оценить шансы',
            icon: Icons.insights_rounded,
            onPressed: () {
              // Fallback: show results without specialty filter
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GrantPredictionResultsScreen(
                    entScore: untScore,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  /// Direction toggle button
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
        // Reset downstream selections
        ref.read(selectedSubjectProvider.notifier).state = null;
        ref.read(selectedSpecialtyProvider.notifier).state = null;
        // Sync to profile in background
        AuthService().updateProfile(subjectType: value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
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
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
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

  /// Subject chip
  Widget _buildSubjectChip({
    required String label,
    required bool selected,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        ref.read(selectedSubjectProvider.notifier).state = label;
        ref.read(selectedSpecialtyProvider.notifier).state = null;
        // Sync to profile
        AuthService().updateProfile(entSubject1: label);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.15)
              : isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : isDark
                    ? Colors.white10
                    : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            color: selected
                ? AppColors.primary
                : isDark
                    ? Colors.white60
                    : Colors.black54,
          ),
        ),
      ),
    );
  }

  /// Specialty dropdown filtered by type + subject
  Widget _buildSpecialtyDropdown(
    String subjectType,
    String subject,
    EntSpecialty? currentSpecialty,
    bool isDark,
  ) {
    final type =
        subjectType == 'physMath' ? SubjectType.physMath : SubjectType.humanities;
    final specialties = getSpecialtiesByTypeAndSubject(type, subject);

    if (specialties.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Нет специальностей для данного предмета',
          style: TextStyle(
            color: isDark ? Colors.white38 : Colors.black38,
            fontSize: 13,
          ),
        ),
      );
    }

    // Determine language for titles
    final locale = Localizations.localeOf(context).languageCode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade300,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentSpecialty?.code,
          hint: Text(
            AppLocalizations.of(context)?.selectSpecialty ??
                'Выберите специальность',
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
              fontSize: 14,
            ),
          ),
          isExpanded: true,
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
          items: specialties.map((s) {
            return DropdownMenuItem<String>(
              value: s.code,
              child: Text(
                '${s.getTitle(locale)} (${s.predictedMin2026}+)',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (code) {
            if (code == null) return;
            final specialty =
                specialties.firstWhere((s) => s.code == code);
            ref.read(selectedSpecialtyProvider.notifier).state = specialty;
            HapticFeedback.selectionClick();
          },
        ),
      ),
    );
  }


  /// Dialog for precise ENT score entry
  void _showScoreInputDialog(int currentScore) {
    final controller = TextEditingController(text: '$currentScore');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          AppLocalizations.of(context)?.scoreInputTitle ?? 'Введите балл ЕНТ',
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
            hintText: AppLocalizations.of(context)?.scoreInputHint ?? '0 – 140',
            hintStyle: TextStyle(
              color: isDark ? Colors.white38 : Colors.black26,
            ),
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.grey.shade100,
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
          onSubmitted: (value) {
            _applyScoreFromText(value, ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppLocalizations.of(context)?.commonCancel ?? 'Отмена',
              style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
            ),
          ),
          FilledButton(
            onPressed: () => _applyScoreFromText(controller.text, ctx),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(AppLocalizations.of(context)?.commonDone ?? 'Готово'),
          ),
        ],
      ),
    );
  }

  void _applyScoreFromText(String text, BuildContext dialogCtx) {
    final parsed = int.tryParse(text.trim());
    if (parsed != null && parsed >= 0 && parsed <= 140) {
      ref.read(untScoreProvider.notifier).state = parsed;
      Navigator.pop(dialogCtx);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.scoreInputError ??
                'Введите число от 0 до 140',
          ),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
          width: 1.5,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isDark ? Colors.white54 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
