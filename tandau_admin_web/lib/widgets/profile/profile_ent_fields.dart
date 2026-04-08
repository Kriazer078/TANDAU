import 'package:flutter/material.dart';

import '../../widgets/custom_dropdown.dart';
import '../../utils/constants.dart';

/// Виджет для выбора направления ЕНТ и пары профильных предметов
class ProfileEntFields extends StatelessWidget {
  final String? subjectType;
  final String? entSubject1; // Теперь хранит пару (напр. 'Математика + Физика')
  final String? entSubject2; // Deprecated, сохраняем для обратной совместимости
  final ValueChanged<String?> onSubjectTypeChanged;
  final ValueChanged<String?> onSubject1Changed;
  final ValueChanged<String?> onSubject2Changed;

  const ProfileEntFields({
    super.key,
    required this.subjectType,
    required this.entSubject1,
    required this.entSubject2,
    required this.onSubjectTypeChanged,
    required this.onSubject1Changed,
    required this.onSubject2Changed,
  });

  @override
  Widget build(BuildContext context) {
    // Label mapping for subject types
    final directionLabels = {
      'physMath': 'Физико-математическое',
      'humanities': 'Гуманитарное',
    };

    // Label to value mapping for dropdown
    final directionItems = AppConstants.subjectTypes
        .map((e) => directionLabels[e] ?? e)
        .toList();
    final String? currentDirectionLabel = subjectType != null
        ? directionLabels[subjectType!]
        : null;

    final availablePairs = subjectType != null
        ? AppConstants.entSubjectPairsByType[subjectType!] ?? []
        : <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomDropdown(
          value: currentDirectionLabel,
          items: directionItems,
          label: 'Направление ЕНТ',
          icon: Icons.explore_outlined,
          onChanged: (label) {
            if (label == null) {
              onSubjectTypeChanged(null);
              return;
            }
            String? key;
            for (var entry in directionLabels.entries) {
              if (entry.value == label) {
                key = entry.key;
                break;
              }
            }
            onSubjectTypeChanged(key ?? label);
          },
        ),

        if (subjectType != null && availablePairs.isNotEmpty) ...[
          const SizedBox(height: 14),
          CustomDropdown(
            value: availablePairs.contains(entSubject1) ? entSubject1 : null,
            items: availablePairs,
            label: 'Пара профильных предметов',
            icon: Icons.library_books_outlined,
            onChanged: onSubject1Changed,
          ),
        ],
      ],
    );
  }
}
