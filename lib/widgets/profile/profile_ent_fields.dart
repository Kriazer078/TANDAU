import 'package:flutter/material.dart';

import '../../widgets/custom_dropdown.dart';
import '../../utils/constants.dart';

/// Виджет для выбора направления ЕНТ и профильных предметов
class ProfileEntFields extends StatelessWidget {
  final String? subjectType;
  final String? entSubject1;
  final String? entSubject2;
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
    final directionItems = AppConstants.subjectTypes.map((e) => directionLabels[e] ?? e).toList();
    final String? currentDirectionLabel = subjectType != null ? directionLabels[subjectType!] : null;

    final availableSubjects = subjectType != null 
        ? AppConstants.entSubjectsByType[subjectType!] ?? []
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
            // Find the original key, or null if not found
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

        if (subjectType != null && availableSubjects.isNotEmpty) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: CustomDropdown(
                  value: availableSubjects.contains(entSubject1) ? entSubject1 : null,
                  items: availableSubjects,
                  label: 'Проф. предмет 1',
                  icon: Icons.book_outlined,
                  onChanged: onSubject1Changed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomDropdown(
                  value: availableSubjects.contains(entSubject2) ? entSubject2 : null,
                  items: availableSubjects.where((s) => s != entSubject1).toList(),
                  label: 'Проф. предмет 2',
                  icon: Icons.menu_book_rounded,
                  onChanged: onSubject2Changed,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
