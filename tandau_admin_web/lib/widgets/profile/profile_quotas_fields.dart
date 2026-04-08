import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Виджет для финансовой ситуации и квот
class ProfileQuotasFields extends StatelessWidget {
  final String? financialSituation;
  final bool isRural;
  final bool isOrphan;
  final bool hasDisability;
  final bool specialExamPassed;
  final ValueChanged<String?> onFinancialChanged;
  final ValueChanged<bool> onRuralChanged;
  final ValueChanged<bool> onOrphanChanged;
  final ValueChanged<bool> onDisabilityChanged;
  final ValueChanged<bool> onSpecialExamChanged;

  const ProfileQuotasFields({
    super.key,
    required this.financialSituation,
    required this.isRural,
    required this.isOrphan,
    required this.hasDisability,
    this.specialExamPassed = false,
    required this.onFinancialChanged,
    required this.onRuralChanged,
    required this.onOrphanChanged,
    required this.onDisabilityChanged,
    required this.onSpecialExamChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final financialOptions = [
      {
        'value': 'only_grant',
        'label': 'Только грант',
        'icon': Icons.school_rounded,
      },
      {
        'value': 'up_to_1m',
        'label': 'До 1 000 000 ₸',
        'icon': Icons.account_balance_wallet_rounded,
      },
      {'value': 'any', 'label': 'Любой бюджет', 'icon': Icons.diamond_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 💰 Финансовая ситуация
        Text(
          'Финансовая ситуация',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        ...financialOptions.map((opt) {
          final selected = financialSituation == opt['value'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onFinancialChanged(opt['value'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF6366F1).withValues(alpha: 0.12)
                        : isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF6366F1)
                          : isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.grey.shade200,
                      width: selected ? 1.5 : 1,
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
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          opt['label'] as String,
                          style: TextStyle(
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            fontSize: 14,
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (selected)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF6366F1),
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 16),

        // 📜 Квоты
        Text(
          'Квоты',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        _buildQuotaToggle(
          label: '🏡 Сельская квота',
          value: isRural,
          isDark: isDark,
          onChanged: onRuralChanged,
        ),
        const SizedBox(height: 8),
        _buildQuotaToggle(
          label: '👶 СУСН (дети-сироты)',
          value: isOrphan,
          isDark: isDark,
          onChanged: onOrphanChanged,
        ),
        const SizedBox(height: 8),
        _buildQuotaToggle(
          label: '♿ Квота для лиц с инвалидностью',
          value: hasDisability,
          isDark: isDark,
          onChanged: onDisabilityChanged,
        ),
        const SizedBox(height: 16),

        // 🎓 Специальный экзамен
        Text(
          'Специальный экзамен',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Творческий, медицинский или психометрический',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white38 : Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 10),
        _buildQuotaToggle(
          label: '🎓 Специальный экзамен сдан',
          value: specialExamPassed,
          isDark: isDark,
          onChanged: onSpecialExamChanged,
        ),
      ],
    );
  }

  Widget _buildQuotaToggle({
    required String label,
    required bool value,
    required bool isDark,
    required ValueChanged<bool> onChanged,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: value
            ? const Color(0xFF6366F1).withValues(alpha: 0.10)
            : isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? const Color(0xFF6366F1)
              : isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.shade200,
          width: value ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
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
}
