import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/professions_data.dart';
import '../models/profession.dart';
import '../models/university.dart';
import '../services/roi_calculator_service.dart';
import '../services/university_service.dart';

// ─── Адаптивная палитра (светлая/тёмная) ───────────────────────────────────
class _Palette {
  final Color bg;
  final Color cardBg;
  final Color cardBgAlt;
  final Color border;
  final Color textMain;
  final Color textSub;
  final Color thumbBg;
  final Color progressTrack;

  const _Palette({
    required this.bg,
    required this.cardBg,
    required this.cardBgAlt,
    required this.border,
    required this.textMain,
    required this.textSub,
    required this.thumbBg,
    required this.progressTrack,
  });

  static _Palette dark() => const _Palette(
        bg: Color(0xFF09090B),
        cardBg: Color(0xFF18181B),
        cardBgAlt: Color(0xFF27272A),
        border: Color(0xFF3F3F46),
        textMain: Color(0xFFFAFAFA),
        textSub: Color(0xFFA1A1AA),
        thumbBg: Color(0xFF3F3F46),
        progressTrack: Color(0xFF27272A),
      );

  static _Palette light() => const _Palette(
        bg: Color(0xFFF4F6FA),
        cardBg: Color(0xFFFFFFFF),
        cardBgAlt: Color(0xFFF1F5F9),
        border: Color(0xFFDDE3EF),
        textMain: Color(0xFF0F172A),
        textSub: Color(0xFF64748B),
        thumbBg: Color(0xFFE2E8F0),
        progressTrack: Color(0xFFE2E8F0),
      );
}

// ─── Семантические цвета (не меняются в зависимости от темы) ───────────────
class _SC {
  static const Color accent = Color(0xFF3B82F6);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
}

class RoiScreen extends StatefulWidget {
  const RoiScreen({super.key});

  @override
  State<RoiScreen> createState() => _RoiScreenState();
}

class _RoiScreenState extends State<RoiScreen> {
  final RoiCalculatorService _service = RoiCalculatorService();
  final UniversityService _uniService = UniversityService();

  Profession? _selectedProfession;
  University? _selectedUniversity;
  bool _isGrant = false;
  bool _willWorkOffGrant = true;
  bool _isRuralQuota = false;
  bool _isPedagogicalOrMedical = false;
  bool _includeLivingCosts = false;
  int _yearsToCalculate = 10;

  List<University> _universities = [];
  bool _isLoadingUniversities = true;

  @override
  void initState() {
    super.initState();
    _loadUniversities();
  }

  Future<void> _loadUniversities() async {
    final list = await _uniService.getAllUniversities();
    if (mounted) {
      setState(() {
        _universities = list;
        _isLoadingUniversities = false;
      });
    }
  }

  void _showProfessionPicker() {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = isDark ? _Palette.dark() : _Palette.light();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.72,
          decoration: BoxDecoration(
            color: p.cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: p.border)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.08),
                blurRadius: 32,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 14),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: p.thumbBg,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Выберите профессию',
                    style: TextStyle(
                      color: p.textMain,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  itemCount: kProfessionsData.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final prof = kProfessionsData[index];
                    final isSelected = _selectedProfession?.id == prof.id;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedProfession = prof;
                            final lower = prof.name.toLowerCase();
                            _isPedagogicalOrMedical =
                                lower.contains('учитель') ||
                                lower.contains('педагог') ||
                                lower.contains('врач') ||
                                lower.contains('медиц') ||
                                lower.contains('медсестра') ||
                                lower.contains('преподават');
                          });
                          Navigator.pop(ctx);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _SC.accent.withValues(alpha: 0.08)
                                : p.cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? _SC.accent.withValues(alpha: 0.5)
                                  : p.border,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                            boxShadow: isDark
                                ? null
                                : [
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: Row(
                            children: [
                              Text(
                                prof.emoji,
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  prof.name,
                                  style: TextStyle(
                                    color: p.textMain,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: _SC.accent,
                                ),
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
        );
      },
    );
  }

  void _showUniversityPicker() {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = isDark ? _Palette.dark() : _Palette.light();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.72,
          decoration: BoxDecoration(
            color: p.cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: p.border)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.08),
                blurRadius: 32,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 14),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: p.thumbBg,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Выберите университет',
                        style: TextStyle(
                          color: p.textMain,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_selectedUniversity != null)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedUniversity = null;
                          });
                          Navigator.pop(ctx);
                        },
                        child: Text(
                          'Сбросить',
                          style: TextStyle(color: _SC.danger),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_isLoadingUniversities)
                Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: _SC.accent),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    itemCount: _universities.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final u = _universities[index];
                      final isSelected = _selectedUniversity?.id == u.id;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedUniversity = u;
                            });
                            Navigator.pop(ctx);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _SC.accent.withValues(alpha: 0.08)
                                  : p.cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? _SC.accent.withValues(alpha: 0.5)
                                    : p.border,
                                width: isSelected ? 1.5 : 1.0,
                              ),
                              boxShadow: isDark
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.03),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: u.logoUrl.isNotEmpty
                                        ? DecorationImage(
                                            image: NetworkImage(u.logoUrl),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                    color: p.cardBgAlt,
                                    border: Border.all(color: p.border),
                                  ),
                                  child: u.logoUrl.isEmpty
                                      ? Icon(
                                          Icons.school,
                                          color: p.textSub,
                                          size: 20,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        u.name,
                                        style: TextStyle(
                                          color: p.textMain,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (u.maxTuitionValue > 0) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Платно: ${RoiCalculatorService.formatMoney(u.maxTuitionValue.toInt())}/год',
                                          style: TextStyle(
                                            color: p.textSub,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: _SC.accent,
                                  ),
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = isDark ? _Palette.dark() : _Palette.light();

    RoiResult? result;
    if (_selectedProfession != null) {
      result = _service.calculate(
        profession: _selectedProfession!,
        isGrant: _isGrant,
        university: _selectedUniversity,
        yearsToCalculate: _yearsToCalculate,
        willWorkOffGrant: _willWorkOffGrant,
        isRuralQuota: _isRuralQuota,
        isPedagogicalOrMedical: _isPedagogicalOrMedical,
        includeLivingCosts: _includeLivingCosts,
      );
    }

    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        backgroundColor: p.cardBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: p.textMain,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Финансовый анализ',
          style: TextStyle(
            color: p.textMain,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: p.border),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Заголовок ───────────────────────────────────────────────
              Text(
                'Окупаемость\nобразования',
                style: TextStyle(
                  color: p.textMain,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Выберите специальность и формат обучения, чтобы увидеть срок возврата инвестиций.',
                style: TextStyle(
                  color: p.textSub,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),

              // ─── Профессия ───────────────────────────────────────────────
              _SectionLabel(text: 'СПЕЦИАЛЬНОСТЬ', palette: p),
              const SizedBox(height: 8),
              _PickerCard(
                isDark: isDark,
                palette: p,
                onTap: _showProfessionPicker,
                icon: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: p.cardBgAlt,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: p.border),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _selectedProfession?.emoji ?? '💼',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                title: _selectedProfession?.name ?? 'Выбрать профессию',
                titleColor: _selectedProfession == null
                    ? p.textSub
                    : p.textMain,
                subtitle: _selectedProfession != null
                    ? 'Стартовая з/п: ${RoiCalculatorService.formatMoney(_selectedProfession!.startSalary)}/мес'
                    : null,
                subtitleColor: p.textSub,
              ),
              const SizedBox(height: 20),

              // ─── Университет ─────────────────────────────────────────────
              _SectionLabel(
                text: 'УНИВЕРСИТЕТ (Необязательный)',
                palette: p,
              ),
              const SizedBox(height: 8),
              _PickerCard(
                isDark: isDark,
                palette: p,
                onTap: _showUniversityPicker,
                icon: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: p.border),
                    color: _selectedUniversity != null &&
                            _selectedUniversity!.logoUrl.isNotEmpty
                        ? Colors.transparent
                        : p.cardBgAlt,
                    image: _selectedUniversity != null &&
                            _selectedUniversity!.logoUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(_selectedUniversity!.logoUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: _selectedUniversity == null ||
                          _selectedUniversity!.logoUrl.isEmpty
                      ? const Text('🎓', style: TextStyle(fontSize: 20))
                      : null,
                ),
                title: _selectedUniversity?.name ??
                    'По умолчанию (средние цены по РК)',
                titleColor: _selectedUniversity == null
                    ? p.textSub
                    : p.textMain,
                subtitle: _selectedUniversity != null &&
                        _selectedUniversity!.maxTuitionValue > 0
                    ? 'Стоимость: ${RoiCalculatorService.formatMoney(_selectedUniversity!.maxTuitionValue.toInt())}/год'
                    : null,
                subtitleColor: p.textSub,
              ),
              const SizedBox(height: 20),

              // ─── Тип финансирования ──────────────────────────────────────
              _SectionLabel(text: 'ТИП ФИНАНСИРОВАНИЯ', palette: p),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: p.cardBgAlt,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: p.border),
                ),
                child: Row(
                  children: [
                    _SegmentBtn(
                      label: 'Платное',
                      isActive: !_isGrant,
                      activeColor: p.textMain,
                      activeBg: p.cardBg,
                      inactiveColor: p.textSub,
                      borderColor: p.border,
                      isDark: isDark,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _isGrant = false);
                      },
                    ),
                    _SegmentBtn(
                      label: 'Грант',
                      isActive: _isGrant,
                      activeColor: _SC.success,
                      activeBg: _SC.success.withValues(alpha: 0.1),
                      inactiveColor: p.textSub,
                      borderColor: _isGrant
                          ? _SC.success.withValues(alpha: 0.4)
                          : Colors.transparent,
                      isDark: isDark,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _isGrant = true);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ─── Грантовые опции ─────────────────────────────────────────
              if (_isGrant) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _SC.accent.withValues(alpha: isDark ? 0.06 : 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _SC.accent.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    children: [
                      _SwitchRow(
                        label: 'Готов отработать грант 3 года',
                        value: _willWorkOffGrant,
                        activeColor: _SC.success,
                        textColor: p.textMain,
                        onChanged: (v) =>
                            setState(() => _willWorkOffGrant = v),
                      ),
                      if (!_willWorkOffGrant)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Если не отработать грант, вы обязаны вернуть государству полную стоимость обучения',
                            style: TextStyle(
                              color: _SC.danger.withValues(alpha: 0.9),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Container(
                        height: 1,
                        color: p.border.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      _SwitchRow(
                        label: 'Поступаю по Сельской квоте',
                        value: _isRuralQuota,
                        activeColor: _SC.accent,
                        textColor: p.textMain,
                        onChanged: (v) => setState(() => _isRuralQuota = v),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 1,
                        color: p.border.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      _SwitchRow(
                        label: 'Педагог / Медик (Гос. зарплата)',
                        value: _isPedagogicalOrMedical,
                        activeColor: _SC.accent,
                        textColor: p.textMain,
                        onChanged: (v) =>
                            setState(() => _isPedagogicalOrMedical = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ─── Расходы на жизнь (платное) ──────────────────────────────
              if (!_isGrant) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _SC.warning.withValues(alpha: isDark ? 0.06 : 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _SC.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: _SwitchRow(
                    label:
                        'Учитывать расходы на жизнь\n(жилье, питание и т.д. ~100к/мес)',
                    value: _includeLivingCosts,
                    activeColor: _SC.warning,
                    textColor: p.textMain,
                    onChanged: (v) => setState(() => _includeLivingCosts = v),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ─── Горизонт планирования ───────────────────────────────────
              _SectionLabel(text: 'ГОРИЗОНТ ПЛАНИРОВАНИЯ', palette: p),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: p.cardBgAlt,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: p.border),
                ),
                child: Row(
                  children: [5, 10, 15, 20].map((y) {
                    final isActive = _yearsToCalculate == y;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _yearsToCalculate = y);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.all(2),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isActive ? p.cardBg : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isActive ? p.border : Colors.transparent,
                            ),
                            boxShadow: isActive && !isDark
                                ? [
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.06),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$y лет',
                            style: TextStyle(
                              color: isActive ? p.textMain : p.textSub,
                              fontWeight: isActive
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 28),

              // ─── Результат ───────────────────────────────────────────────
              if (result != null)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildResultsSection(result, p, isDark),
                )
              else
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.calculate_outlined,
                          size: 48,
                          color: p.textSub.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Выберите профессию для расчёта',
                          style: TextStyle(
                            color: p.textSub.withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsSection(RoiResult res, _Palette p, bool isDark) {
    if (res.isGrant && res.willWorkOff) {
      return Column(
        key: const ValueKey('grant'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _SC.success.withValues(alpha: isDark ? 0.1 : 0.07),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _SC.success.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                const Icon(Icons.school_rounded, color: _SC.success, size: 40),
                const SizedBox(height: 16),
                const Text(
                  'Вы учитесь бесплатно',
                  style: TextStyle(
                    color: _SC.success,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Грант полностью покрывает ваше обучение.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _SC.success.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _MetricCard(
            isDark: isDark,
            palette: p,
            title: 'Экономия на обучении',
            value: RoiCalculatorService.formatMoney(res.grantSavings),
            icon: Icons.savings_rounded,
            color: _SC.accent,
          ),
          const SizedBox(height: 10),
          _MetricCard(
            isDark: isDark,
            palette: p,
            title: 'Прибыль за ${res.calculatedYears} лет',
            value: RoiCalculatorService.formatMoney(res.calculatedProfit),
            icon: Icons.trending_up_rounded,
            color: _SC.success,
          ),
        ],
      );
    } else {
      return Column(
        key: const ValueKey('paid'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: p.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: p.border),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (res.isDebt)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _SC.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _SC.danger.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      'Внимание: При отказе от отработки грант нужно вернуть государству. Это равносильно платному обучению.',
                      style: TextStyle(
                        color: _SC.danger,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                Text(
                  'Итоговая окупаемость',
                  style: TextStyle(
                    color: p.textSub,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatPaybackShort(res),
                      style: TextStyle(
                        color: p.textMain,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _ratingColor(res.rating)
                            .withValues(alpha: isDark ? 0.15 : 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _ratingColor(res.rating)
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        _ratingString(res.rating),
                        style: TextStyle(
                          color: _ratingColor(res.rating),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final double ratio =
                        (res.paybackMonths / 48).clamp(0.0, 1.0);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Stack(
                            children: [
                              Container(
                                height: 8,
                                color: p.progressTrack,
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeOut,
                                height: 8,
                                width: constraints.maxWidth * ratio,
                                decoration: BoxDecoration(
                                  color: _ratingColor(res.rating),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Сейчас',
                              style: TextStyle(
                                color: p.textSub,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              '4 года',
                              style: TextStyle(
                                color: p.textSub.withValues(
                                  alpha: ratio > 0.85 ? 1.0 : 0.45,
                                ),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _CompactMetric(
                  isDark: isDark,
                  palette: p,
                  title: 'Стоим. + Жизнь',
                  value: RoiCalculatorService.formatMoney(res.totalTuition),
                  valueColor: p.textSub,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CompactMetric(
                  isDark: isDark,
                  palette: p,
                  title: 'Сбереж./мес (35%)',
                  value: RoiCalculatorService.formatMoney(
                    (res.monthlySalary * 0.35).round(),
                  ),
                  valueColor: p.textMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _MetricCard(
            isDark: isDark,
            palette: p,
            title: 'Прибыль (${res.calculatedYears} лет)',
            value: RoiCalculatorService.formatMoney(res.calculatedProfit),
            icon: Icons.account_balance_wallet_rounded,
            color: res.calculatedProfit >= 0 ? _SC.success : _SC.danger,
          ),
        ],
      );
    }
  }

  String _formatPaybackShort(RoiResult r) {
    if (r.paybackMonths == 0) return '0 мес';
    if (r.paybackYears == 0) return '${r.paybackMonths} мес';
    if (r.remainingMonths == 0) return '${r.paybackYears} лет';
    return '${r.paybackYears} г ${r.remainingMonths} м';
  }

  String _ratingString(RoiRating r) {
    switch (r) {
      case RoiRating.excellent:
        return 'ОТЛИЧНО';
      case RoiRating.good:
        return 'ХОРОШО';
      case RoiRating.average:
        return 'СРЕДНЕ';
      case RoiRating.poor:
        return 'ДОЛГО';
    }
  }

  Color _ratingColor(RoiRating rating) {
    switch (rating) {
      case RoiRating.excellent:
        return _SC.success;
      case RoiRating.good:
        return _SC.accent;
      case RoiRating.average:
        return _SC.warning;
      case RoiRating.poor:
        return _SC.danger;
    }
  }
}

// ─── Вспомогательные виджеты ────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  final _Palette palette;

  const _SectionLabel({required this.text, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: palette.textSub,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _PickerCard extends StatelessWidget {
  final bool isDark;
  final _Palette palette;
  final VoidCallback onTap;
  final Widget icon;
  final String title;
  final Color titleColor;
  final String? subtitle;
  final Color? subtitleColor;

  const _PickerCard({
    required this.isDark,
    required this.palette,
    required this.onTap,
    required this.icon,
    required this.title,
    required this.titleColor,
    this.subtitle,
    this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: palette.cardBg,
            border: Border.all(color: palette.border, width: 1.5),
            borderRadius: BorderRadius.circular(14),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Row(
            children: [
              icon,
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: subtitleColor ?? palette.textSub,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.unfold_more_rounded, color: palette.textSub, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _SegmentBtn extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color activeColor;
  final Color activeBg;
  final Color inactiveColor;
  final Color borderColor;
  final bool isDark;
  final VoidCallback onTap;

  const _SegmentBtn({
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.activeBg,
    required this.inactiveColor,
    required this.borderColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? borderColor : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: isActive && !isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? activeColor : inactiveColor,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final bool value;
  final Color activeColor;
  final Color textColor;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.label,
    required this.value,
    required this.activeColor,
    required this.textColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: textColor, fontSize: 13, height: 1.5),
          ),
        ),
        const SizedBox(width: 12),
        CupertinoSwitch(
          value: value,
          activeTrackColor: activeColor,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final bool isDark;
  final _Palette palette;
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.isDark,
    required this.palette,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border, width: 1.5),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.12 : 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: palette.textSub,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: palette.textMain,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactMetric extends StatelessWidget {
  final bool isDark;
  final _Palette palette;
  final String title;
  final String value;
  final Color valueColor;

  const _CompactMetric({
    required this.isDark,
    required this.palette,
    required this.title,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border, width: 1.5),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: palette.textSub,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
