import 'package:flutter/material.dart';

import '../services/career_test_service.dart';
import '../models/career_test_result.dart';
import '../theme/app_colors.dart';
import 'holland_test_screen.dart';
import 'klimov_test_screen.dart';
import 'career_test_result_screen.dart';
import '../widgets/icon_3d.dart';

/// 📋 Хаб профориентации — выбор теста
///
/// Точки входа: HomeScreen (tools row), ProfileScreen (меню)
class CareerTestHubScreen extends StatefulWidget {
  const CareerTestHubScreen({super.key});

  @override
  State<CareerTestHubScreen> createState() => _CareerTestHubScreenState();
}

class _CareerTestHubScreenState extends State<CareerTestHubScreen>
    with SingleTickerProviderStateMixin {
  final CareerTestService _service = CareerTestService();
  CareerTestResult? _lastHollandResult;
  CareerTestResult? _lastKlimovResult;
  bool _isLoading = true;
  late AnimationController _animController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _loadResults();
  }

  Future<void> _loadResults() async {
    try {
      final hollandResult = await _service.loadLastResult(testType: 'holland');
      final klimovResult = await _service.loadLastResult(testType: 'klimov');
      
      if (mounted) {
        setState(() {
          _lastHollandResult = hollandResult;
          _lastKlimovResult = klimovResult;
          _isLoading = false;
        });
        _animController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _animController.forward();
      }
    }
  }

  void _startHollandTest() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HollandTestScreen()),
    ).then((_) => _loadResults());
  }

  void _startKlimovTest() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const KlimovTestScreen()),
    ).then((_) => _loadResults());
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 🎨 Красивый AppBar с градиентом
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: isDark ? AppColors.cardDark : Colors.white,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFE91E63),
                      const Color(0xFF9C27B0),
                      isDark
                          ? const Color(0xFF4A148C)
                          : const Color(0xFFCE93D8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.psychology_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Профориентация',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Узнай свои склонности и найди\nподходящую специальность',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 📋 Контент
          SliverToBoxAdapter(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(64),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : FadeTransition(
                    opacity: _fadeIn,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🏆 Результаты (если есть)
                          if (_lastHollandResult != null) ...[
                            _buildResultBanner(isDark, _lastHollandResult!, 'Тест Голланда'),
                            const SizedBox(height: 16),
                          ],
                          if (_lastKlimovResult != null) ...[
                            _buildResultBanner(isDark, _lastKlimovResult!, 'ДДО Климова'),
                            const SizedBox(height: 24),
                          ],

                          // 📝 Доступные тесты
                          Text(
                            'Доступные тесты',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 🧭 Тест Голланда
                          _buildTestCard(
                            isDark: isDark,
                            icon: Icons.compass_calibration_rounded,
                            title: 'Тест Голланда (RIASEC)',
                            subtitle: '42 вопроса • ~10 минут',
                            description:
                                'Международный стандарт профориентации. '
                                'Определит твой тип личности и подберёт '
                                'подходящие специальности.',
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE91E63), Color(0xFFFF5252)],
                            ),
                            isCompleted: _lastHollandResult != null,
                            onTap: () => _startHollandTest(),
                          ),
                          const SizedBox(height: 16),

                          // 🔬 ДДО Климова
                          _buildTestCard(
                            isDark: isDark,
                            icon: Icons.science_rounded,
                            title: 'ДДО Климова',
                            subtitle: '20 вопросов • ~5 минут',
                            description:
                                'Классическая методика профориентации. '
                                'Определит твою профессиональную область: '
                                'Техника, Природа, Человек, и др.',
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2196F3), Color(0xFF00BCD4)],
                            ),
                            isCompleted: _lastKlimovResult != null,
                            onTap: () => _startKlimovTest(),
                          ),

                          const SizedBox(height: 32),

                          // 📚 Информация
                          _buildInfoSection(isDark),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// 🏆 Баннер с последним результатом
  Widget _buildResultBanner(bool isDark, CareerTestResult result, String testName) {
    String typeName = '';
    String emoji = '🧭';
    Color color = const Color(0xFFE91E63);
    
    if (result.testType == 'holland') {
      final topType = result.topCode.isNotEmpty ? result.topCode[0] : 'R';
      typeName = CareerTestResult.riasecNamesRu[topType] ?? 'Неизвестный';
      emoji = CareerTestResult.riasecEmojis[topType] ?? '🧭';
      color = Color(CareerTestResult.riasecColors[topType] ?? 0xFFE91E63);
    } else {
      final topType = result.topCode.isNotEmpty ? result.topCode : 'nature';
      typeName = CareerTestResult.klimovNamesRu[topType] ?? 'Неизвестная сфера';
      emoji = CareerTestResult.klimovEmojis[topType] ?? '🔬';
      color = Color(CareerTestResult.klimovColors[topType] ?? 0xFF2196F3);
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CareerTestResultScreen(result: result),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark
              ? color.withValues(alpha: 0.15)
              : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon3D(emoji: emoji, size: 36),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '$testName: Ваш результат',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '✅ Пройден',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$typeName (${result.topCode})',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Нажми, чтобы посмотреть подробности →',
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📝 Карточка теста
  Widget _buildTestCard({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
    required Gradient gradient,
    bool isCompleted = false,
    bool isLocked = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppColors.border.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? Colors.white54
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLocked)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '🔒 Скоро',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                if (isCompleted && !isLocked)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '✅',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: isLocked ? null : gradient,
                color: isLocked
                    ? (isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.withValues(alpha: 0.1))
                    : null,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                isLocked
                    ? 'Скоро доступно'
                    : isCompleted
                        ? 'Пройти заново'
                        : 'Начать тест',
                style: TextStyle(
                  color: isLocked
                      ? (isDark ? Colors.white38 : Colors.grey)
                      : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📚 Информационный блок
  Widget _buildInfoSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.blue.withValues(alpha: 0.08)
            : Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: Colors.blue.shade400,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Зачем проходить тест?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            isDark,
            '🎯',
            'Определишь свои склонности и сильные стороны',
          ),
          const SizedBox(height: 8),
          _buildInfoItem(
            isDark,
            '📚',
            'Узнаешь, какие специальности тебе подходят',
          ),
          const SizedBox(height: 8),
          _buildInfoItem(
            isDark,
            '🎓',
            'Получишь привязку к конкретным ГОП для ЕНТ',
          ),
          const SizedBox(height: 8),
          _buildInfoItem(
            isDark,
            '🤖',
            'AI-консультант учтёт результат в рекомендациях',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(bool isDark, String emoji, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon3D(emoji: emoji, size: 24),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
