import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Виджет для выбора предпочтений: специальности и достижения
class ProfilePreferencesFields extends StatelessWidget {
  final Set<String> selectedMajors;
  final Set<String> selectedAchievements;
  final ValueChanged<String> onMajorToggle;
  final ValueChanged<String> onAchievementToggle;

  const ProfilePreferencesFields({
    super.key,
    required this.selectedMajors,
    required this.selectedAchievements,
    required this.onMajorToggle,
    required this.onAchievementToggle,
  });

  static const List<String> majorOptions = [
    'IT / Программирование',
    'Медицина',
    'Инженерия',
    'Бизнес / Экономика',
    'Педагогика',
    'Юриспруденция',
    'Архитектура',
    'Нефтегаз',
    'Искусство / Дизайн',
    'Не определился',
  ];

  static const List<String> achievementOptions = [
    'Алтын белгі',
    'Олимпиада (республика)',
    'Олимпиада (область)',
    'Спортивные достижения',
    'Волонтёрство',
    'Научный проект',
    'Нет достижений',
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🎯 Специальности
        Text(
          'Предпочитаемые специальности',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: majorOptions.map((major) {
            final selected = selectedMajors.contains(major);
            return _buildChip(
              label: major,
              selected: selected,
              isDark: isDark,
              onTap: () => onMajorToggle(major),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // 🏆 Достижения
        Text(
          'Достижения',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: achievementOptions.map((ach) {
            final selected = selectedAchievements.contains(ach);
            return _buildChip(
              label: ach,
              selected: selected,
              isDark: isDark,
              onTap: () => onAchievementToggle(ach),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildChip({
    required String label,
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
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? const Color(0xFF6366F1)
                : isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.shade200,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected
                ? const Color(0xFF6366F1)
                : isDark
                    ? Colors.white70
                    : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
