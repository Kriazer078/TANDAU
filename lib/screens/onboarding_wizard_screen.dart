import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import '../theme/app_colors.dart';

/// 6-шаговый AI Onboarding Wizard
/// Быстро заполняет профиль за 2 минуты через красивый UI
class OnboardingWizardScreen extends StatefulWidget {
  const OnboardingWizardScreen({super.key});

  @override
  State<OnboardingWizardScreen> createState() => _OnboardingWizardScreenState();
}

class _OnboardingWizardScreenState extends State<OnboardingWizardScreen>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  final int _totalSteps = 6;

  // Step 1: ENT Score
  int _entScore = 80;

  // Step 2: Specialty
  final Set<String> _selectedMajors = {};
  final List<Map<String, dynamic>> _majorOptions = [
    {'label': 'IT / Программирование', 'icon': Icons.computer_rounded},
    {'label': 'Медицина', 'icon': Icons.local_hospital_rounded},
    {'label': 'Инженерия', 'icon': Icons.engineering_rounded},
    {'label': 'Бизнес / Экономика', 'icon': Icons.trending_up_rounded},
    {'label': 'Педагогика', 'icon': Icons.school_rounded},
    {'label': 'Юриспруденция', 'icon': Icons.gavel_rounded},
    {'label': 'Архитектура', 'icon': Icons.architecture_rounded},
    {'label': 'Нефтегаз', 'icon': Icons.oil_barrel_rounded},
    {'label': 'Искусство / Дизайн', 'icon': Icons.palette_rounded},
    {'label': 'Не определился', 'icon': Icons.help_outline_rounded},
  ];

  // Step 3: City
  final Set<String> _selectedCities = {};
  final List<String> _cityOptions = [
    'Алматы',
    'Астана',
    'Шымкент',
    'Караганда',
    'Актобе',
    'Павлодар',
    'Семей',
    'Атырау',
    'Костанай',
    'Актау',
    'Любой город',
  ];

  // Step 4: Financial
  String? _financialSituation;

  // Step 5: Quotas
  bool _isRural = false;
  bool _isOrphan = false;
  bool _hasDisability = false;

  // Step 6: Achievements
  final Set<String> _selectedAchievements = {};
  final List<String> _achievementOptions = [
    'Алтын белгі',
    'Олимпиада (республика)',
    'Олимпиада (область)',
    'Спортивные достижения',
    'Волонтёрство',
    'Научный проект',
    'Нет достижений',
  ];

  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _progressAnimation =
        Tween<double>(begin: 1 / _totalSteps, end: 1 / _totalSteps).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
        _animateProgress();
      });
    } else {
      _saveProfile();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _animateProgress();
      });
    }
  }

  void _animateProgress() {
    _progressAnimation = Tween<double>(
      begin: _progressAnimation.value,
      end: (_currentStep + 1) / _totalSteps,
    ).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeOutCubic,
      ),
    );
    _progressController.forward(from: 0);
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'entScore': _entScore,
        'preferredMajors': _selectedMajors.toList(),
        'preferredCities': _selectedCities.toList(),
        'financialSituation': _financialSituation,
        'isRural': _isRural,
        'isOrphan': _isOrphan,
        'hasDisability': _hasDisability,
        'achievements': _selectedAchievements.toList(),
        'onboardingCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 🔄 FIX: Refresh AuthService local state so AI sees updated profile
      await AuthService().refreshUserData();

      if (mounted) {
        Navigator.pop(context, true); // true = profile was updated
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сохранения: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    IconButton(
                      onPressed: _prevStep,
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: isDark ? Colors.white70 : AppColors.textPrimary,
                      ),
                    )
                  else
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close_rounded,
                        color: isDark ? Colors.white70 : AppColors.textPrimary,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      'Шаг ${_currentStep + 1} из $_totalSteps',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color:
                            isDark ? Colors.white54 : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Пропустить',
                      style: TextStyle(
                        color: isDark ? Colors.white38 : Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) => ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _progressAnimation.value,
                    minHeight: 6,
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF6366F1),
                    ),
                  ),
                ),
              ),
            ),

            // Content
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.1, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: _buildStep(_currentStep, isDark),
              ),
            ),

            // Bottom button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _canProceed() ? _nextStep : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    disabledBackgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.grey.shade200,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _currentStep == _totalSteps - 1 ? '✨ Завершить' : 'Далее →',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return true; // ENT score always valid
      case 1:
        return _selectedMajors.isNotEmpty;
      case 2:
        return _selectedCities.isNotEmpty;
      case 3:
        return _financialSituation != null;
      case 4:
        return true; // quotas are optional
      case 5:
        return _selectedAchievements.isNotEmpty;
      default:
        return true;
    }
  }

  Widget _buildStep(int step, bool isDark) {
    switch (step) {
      case 0:
        return _buildEntStep(isDark);
      case 1:
        return _buildMajorStep(isDark);
      case 2:
        return _buildCityStep(isDark);
      case 3:
        return _buildFinancialStep(isDark);
      case 4:
        return _buildQuotaStep(isDark);
      case 5:
        return _buildAchievementStep(isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  // === STEP 1: ENT Score ===
  Widget _buildEntStep(bool isDark) {
    return _buildStepContainer(
      key: const ValueKey(0),
      isDark: isDark,
      emoji: '📝',
      title: 'Какой у тебя балл ЕНТ?',
      subtitle: 'Пробный или реальный — укажи примерный',
      child: Column(
        children: [
          const SizedBox(height: 32),
          Text(
            '$_entScore',
            style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w800,
              color: _getScoreColor(_entScore),
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getScoreLabel(_entScore),
            style: TextStyle(
              fontSize: 14,
              color: _getScoreColor(_entScore).withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: _getScoreColor(_entScore),
              inactiveTrackColor:
                  isDark ? Colors.white12 : Colors.grey.shade200,
              thumbColor: _getScoreColor(_entScore),
              overlayColor: _getScoreColor(_entScore).withValues(alpha: 0.2),
              trackHeight: 6,
            ),
            child: Slider(
              value: _entScore.toDouble(),
              min: 0,
              max: 140,
              divisions: 140,
              onChanged: (v) => setState(() => _entScore = v.round()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '0',
                  style: TextStyle(
                    color: isDark ? Colors.white30 : Colors.grey,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '140',
                  style: TextStyle(
                    color: isDark ? Colors.white30 : Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 100) return const Color(0xFF10B981);
    if (score >= 80) return const Color(0xFF6366F1);
    if (score >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String _getScoreLabel(int score) {
    if (score >= 120) return 'Отлично! 🔥';
    if (score >= 100) return 'Хорошо! 💪';
    if (score >= 80) return 'Неплохо 👍';
    if (score >= 60) return 'Есть куда расти 📈';
    return 'Нужна подготовка 📚';
  }

  // === STEP 2: Major ===
  Widget _buildMajorStep(bool isDark) {
    return _buildStepContainer(
      key: const ValueKey(1),
      isDark: isDark,
      emoji: '🎯',
      title: 'Какая специальность?',
      subtitle: 'Выбери одну или несколько',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _majorOptions.map((opt) {
          final label = opt['label'] as String;
          final icon = opt['icon'] as IconData;
          final selected = _selectedMajors.contains(label);
          return _buildChip(
            label: label,
            icon: icon,
            selected: selected,
            isDark: isDark,
            onTap: () => setState(() {
              if (selected) {
                _selectedMajors.remove(label);
              } else {
                _selectedMajors.add(label);
              }
            }),
          );
        }).toList(),
      ),
    );
  }

  // === STEP 3: City ===
  Widget _buildCityStep(bool isDark) {
    return _buildStepContainer(
      key: const ValueKey(2),
      isDark: isDark,
      emoji: '🏙️',
      title: 'Какой город?',
      subtitle: 'Где хочешь учиться',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _cityOptions.map((city) {
          final selected = _selectedCities.contains(city);
          return _buildChip(
            label: city,
            icon: Icons.location_on_outlined,
            selected: selected,
            isDark: isDark,
            onTap: () => setState(() {
              if (selected) {
                _selectedCities.remove(city);
              } else {
                _selectedCities.add(city);
              }
            }),
          );
        }).toList(),
      ),
    );
  }

  // === STEP 4: Financial ===
  Widget _buildFinancialStep(bool isDark) {
    final options = [
      {
        'value': 'only_grant',
        'label': 'Только грант',
        'desc': 'Не могу оплачивать обучение',
        'icon': Icons.school_rounded,
      },
      {
        'value': 'up_to_1m',
        'label': 'До 1 000 000 ₸',
        'desc': 'Могу оплатить частично',
        'icon': Icons.account_balance_wallet_rounded,
      },
      {
        'value': 'any',
        'label': 'Любой бюджет',
        'desc': 'Финансы не ограничивают выбор',
        'icon': Icons.diamond_rounded,
      },
    ];

    return _buildStepContainer(
      key: const ValueKey(3),
      isDark: isDark,
      emoji: '💰',
      title: 'Финансовая ситуация?',
      subtitle: 'Это поможет подобрать подходящие вузы',
      child: Column(
        children: options.map((opt) {
          final selected = _financialSituation == opt['value'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => setState(() {
                  _financialSituation = opt['value'] as String;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF6366F1).withValues(alpha: 0.15)
                        : isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF6366F1)
                          : isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.grey.shade200,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        opt['icon'] as IconData,
                        color: selected
                            ? const Color(0xFF6366F1)
                            : isDark
                                ? Colors.white54
                                : Colors.grey,
                        size: 28,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              opt['label'] as String,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              opt['desc'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white38 : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (selected)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF6366F1),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // === STEP 5: Quotas ===
  Widget _buildQuotaStep(bool isDark) {
    return _buildStepContainer(
      key: const ValueKey(4),
      isDark: isDark,
      emoji: '📜',
      title: 'Есть ли квоты?',
      subtitle: 'Квоты дают преимущество при поступлении',
      child: Column(
        children: [
          _buildQuotaToggle(
            label: '🏡 Сельская квота',
            desc: 'Регистрация в селе / ауле',
            value: _isRural,
            isDark: isDark,
            onChanged: (v) => setState(() => _isRural = v),
          ),
          const SizedBox(height: 10),
          _buildQuotaToggle(
            label: '👶 СУСН (дети-сироты)',
            desc: 'Статус ребёнка-сироты',
            value: _isOrphan,
            isDark: isDark,
            onChanged: (v) => setState(() => _isOrphan = v),
          ),
          const SizedBox(height: 10),
          _buildQuotaToggle(
            label: '♿ Квота для лиц с инвалидностью',
            desc: 'Инвалидность I, II или III группы',
            value: _hasDisability,
            isDark: isDark,
            onChanged: (v) => setState(() => _hasDisability = v),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Text('💡', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Нет квоты? Не страшно! AI учтёт это и подберёт лучшие варианты.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotaToggle({
    required String label,
    required String desc,
    required bool value,
    required bool isDark,
    required ValueChanged<bool> onChanged,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: value
            ? const Color(0xFF6366F1).withValues(alpha: 0.12)
            : isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value
              ? const Color(0xFF6366F1)
              : isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.shade200,
          width: value ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFF6366F1),
          ),
        ],
      ),
    );
  }

  // === STEP 6: Achievements ===
  Widget _buildAchievementStep(bool isDark) {
    return _buildStepContainer(
      key: const ValueKey(5),
      isDark: isDark,
      emoji: '🏆',
      title: 'Достижения?',
      subtitle: 'Алтын белгі, олимпиады, спорт',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _achievementOptions.map((ach) {
          final selected = _selectedAchievements.contains(ach);
          return _buildChip(
            label: ach,
            icon: Icons.emoji_events_outlined,
            selected: selected,
            isDark: isDark,
            onTap: () => setState(() {
              if (selected) {
                _selectedAchievements.remove(ach);
              } else {
                _selectedAchievements.add(ach);
              }
            }),
          );
        }).toList(),
      ),
    );
  }

  // === Reusable builders ===
  Widget _buildStepContainer({
    required Key key,
    required bool isDark,
    required String emoji,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.textPrimary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white54 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required IconData icon,
    required bool selected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF6366F1).withValues(alpha: 0.15)
              : isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? const Color(0xFF6366F1)
                : isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check_circle_rounded : icon,
              size: 18,
              color: selected
                  ? const Color(0xFF6366F1)
                  : isDark
                      ? Colors.white54
                      : Colors.grey,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected
                      ? const Color(0xFF6366F1)
                      : isDark
                          ? Colors.white70
                          : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
