import 'package:flutter/material.dart';

import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_dropdown.dart';
import '../../utils/constants.dart';
import '../../l10n/app_localizations.dart';

/// Personal fields section: name, email (readonly), age, education.
class ProfilePersonalFields extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController ageController;
  final String? selectedEducation;
  final ValueChanged<String?> onAgeChanged;
  final ValueChanged<String?> onEducationChanged;

  const ProfilePersonalFields({
    super.key,
    required this.nameController,
    required this.emailController,
    required this.ageController,
    required this.selectedEducation,
    required this.onAgeChanged,
    required this.onEducationChanged,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);

    final String? ageValue = ageController.text.isNotEmpty &&
            AppConstants.ageOptions.contains(ageController.text)
        ? ageController.text
        : null;

    return Column(
      children: [
        CustomTextField(
          label: l10n?.authFullName ?? 'ФИО',
          controller: nameController,
          icon: Icons.person_outline,
          textCapitalization: TextCapitalization.words,
          validator: (v) =>
              v!.isEmpty ? (l10n?.validationName ?? 'Введите имя') : null,
        ),
        const SizedBox(height: 14),
        CustomTextField(
          label: l10n?.authEmail ?? 'Email',
          controller: emailController,
          icon: Icons.email_outlined,
          readOnly: true,
          suffixIcon: Icon(
            Icons.lock_outline,
            color: Colors.grey.shade400,
            size: 20,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: CustomDropdown(
                value: ageValue,
                items: AppConstants.ageOptions,
                label: l10n?.profileAge ?? 'Возраст',
                icon: Icons.calendar_today_outlined,
                onChanged: onAgeChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomDropdown(
                value: selectedEducation,
                items: AppConstants.educationOptions,
                label: l10n?.profileEducation ?? 'Учёба',
                icon: Icons.school_outlined,
                onChanged: onEducationChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
