import 'package:flutter/material.dart';

import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_dropdown.dart';
import '../../utils/constants.dart';
import '../../l10n/app_localizations.dart';

/// City selection section with dropdown and optional custom city input.
class ProfileCityFields extends StatelessWidget {
  final String? selectedCityDropdown;
  final TextEditingController cityController;
  final ValueChanged<String?> onCityDropdownChanged;

  const ProfileCityFields({
    super.key,
    required this.selectedCityDropdown,
    required this.cityController,
    required this.onCityDropdownChanged,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);

    return Column(
      children: [
        CustomDropdown(
          value: selectedCityDropdown,
          items: AppConstants.cities,
          label: l10n?.profileCity ?? 'Город',
          icon: Icons.location_city_outlined,
          onChanged: onCityDropdownChanged,
        ),
        if (selectedCityDropdown == 'Другой') ...[
          const SizedBox(height: 12),
          CustomTextField(
            label: l10n?.profileCityEnter ?? 'Введите название города',
            controller: cityController,
            icon: Icons.edit_location_alt_outlined,
            textCapitalization: TextCapitalization.words,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return l10n?.validationCity ?? 'Введите город';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }
}
