import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/holland_test_data.dart';
import '../data/test_translations.dart';
import '../services/career_test_service.dart';
import '../theme/app_colors.dart';
import 'career_test_result_screen.dart';

/// 🧭 Экран прохождения теста Голланда (RIASEC)
///
/// 42 пары вопросов. Для каждой пары выбираешь один из двух вариантов.
/// По завершении → подсчёт очков → экран результатов.
class HollandTestScreen extends StatefulWidget {
  const HollandTestScreen({super.key});

  @override
  State<HollandTestScreen> createState() => _HollandTestScreenState();
}

class _HollandTestScreenState extends State<HollandTestScreen>
    with SingleTickerProviderStateMixin {
  final CareerTestService _service = CareerTestService();
  final Map<int, String> _answers = {};
  int _currentIndex = 0;
  bool _isCalculating = false;

  late AnimationController _cardAnimController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _cardAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cardAnimController,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _cardAnimController,
        curve: Curves.easeOut,
      ),
    );
    _cardAnimController.forward();
  }

  @override
  void dispose() {
    _cardAnimController.dispose();
    super.dispose();
  }

  void _selectAnswer(String type) {
    HapticFeedback.lightImpact();

    setState(() {
      _answers[hollandQuestions[_currentIndex].id] = type;
    });

    // Анимация перехода к следующему вопросу
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      if (_currentIndex < hollandQuestions.length - 1) {
        _cardAnimController.reset();
        setState(() => _currentIndex++);
        _cardAnimController.forward();
      } else {
        _finishTest();
      }
    });
  }

  void _goBack() {
    if (_currentIndex > 0) {
      _cardAnimController.reset();
      setState(() => _currentIndex--);
      _cardAnimController.forward();
    }
  }

  Future<void> _finishTest() async {
    setState(() => _isCalculating = true);

    // Имитация расчёта (для UX)
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    final result = _service.calculateHollandResult(_answers);

    // Сохранить в Firestore
    final error = await _service.saveResult(result);
    if (error != null && mounted) {
      debugPrint('⚠️ Не удалось сохранить: $error');
    }

    if (!mounted) return;

    // Перейти к результатам (заменить текущий экран)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CareerTestResultScreen(result: result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isCalculating) {
      return _buildCalculatingScreen(isDark);
    }

    final question = hollandQuestions[_currentIndex];
    final progress = (_currentIndex + 1) / hollandQuestions.length;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          onPressed: () => _showExitDialog(),
        ),
        title: Text(
          'Тест Голланда',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          // Счётчик вопросов
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E63).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentIndex + 1}/${hollandQuestions.length}',
                  style: const TextStyle(
                    color: Color(0xFFE91E63),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 8),

              // 📊 Прогресс-бар
              _buildProgressBar(progress, isDark),
              const SizedBox(height: 32),

              // 💬 Вопрос
              Text(
                'Что тебе больше нравится?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Выбери один из двух вариантов',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),

              // 🃏 Карточки вариантов
              Expanded(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        // Вариант А
                        Expanded(
                          child: _buildOptionCard(
                            text: trTest(context, question.optionA.text),
                            type: question.optionA.type,
                            label: 'А',
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFE91E63), Color(0xFFFF5252)],
                            ),
                            isDark: isDark,
                            isSelected: _answers[question.id] ==
                                question.optionA.type,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Разделитель "ИЛИ"
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: isDark
                                    ? Colors.white12
                                    : Colors.grey.shade300,
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'ИЛИ',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.grey.shade400,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: isDark
                                    ? Colors.white12
                                    : Colors.grey.shade300,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Вариант Б
                        Expanded(
                          child: _buildOptionCard(
                            text: trTest(context, question.optionB.text),
                            type: question.optionB.type,
                            label: 'Б',
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF9C27B0), Color(0xFF7C4DFF)],
                            ),
                            isDark: isDark,
                            isSelected: _answers[question.id] ==
                                question.optionB.type,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ⬅️ Кнопка «Назад»
              if (_currentIndex > 0)
                TextButton.icon(
                  onPressed: _goBack,
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: isDark ? Colors.white54 : AppColors.textSecondary,
                    size: 18,
                  ),
                  label: Text(
                    'Предыдущий вопрос',
                    style: TextStyle(
                      color:
                          isDark ? Colors.white54 : AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// 📊 Прогресс-бар
  Widget _buildProgressBar(double progress, bool isDark) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(
              Color(0xFFE91E63),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(progress * 100).round()}% пройдено',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white38 : Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'Осталось: ${hollandQuestions.length - _currentIndex - 1}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white38 : Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 🃏 Карточка варианта ответа
  Widget _buildOptionCard({
    required String text,
    required String type,
    required String label,
    required Gradient gradient,
    required bool isDark,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => _selectAnswer(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: isSelected ? gradient : null,
          color: isSelected
              ? null
              : (isDark ? AppColors.cardDark : Colors.white),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppColors.border.withValues(alpha: 0.3)),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFE91E63).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
        ),
        child: Row(
          children: [
            // Лейбл A/Б
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.withValues(alpha: 0.08)),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white54 : Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white : AppColors.textPrimary),
                  height: 1.4,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }

  /// ⏳ Экран расчёта результатов
  Widget _buildCalculatingScreen(bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Анимированная иконка
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFFE91E63).withValues(alpha: 0.4),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.psychology_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            Text(
              'Анализируем ответы...',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Определяем твой тип личности',
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white54 : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFFE91E63),
                ),
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.grey.shade200,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🚪 Диалог выхода
  void _showExitDialog() {
    if (_answers.isEmpty) {
      Navigator.pop(context);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.cardDark : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Выйти из теста?',
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Прогресс будет потерян. Вы прошли '
            '${_answers.length} из ${hollandQuestions.length} вопросов.',
            style: TextStyle(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Продолжить',
                style: TextStyle(
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text(
                'Выйти',
                style: TextStyle(
                  color: Color(0xFFE91E63),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
