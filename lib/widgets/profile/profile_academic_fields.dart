import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/custom_text_field.dart';
import '../../l10n/app_localizations.dart';

/// Academic score fields: UNT, IELTS, GPA, Math.
class ProfileAcademicFields extends StatelessWidget {
  final TextEditingController untScoreController;
  final TextEditingController ieltsScoreController;
  final TextEditingController gpaController;
  final TextEditingController mathScoreController;

  const ProfileAcademicFields({
    super.key,
    required this.untScoreController,
    required this.ieltsScoreController,
    required this.gpaController,
    required this.mathScoreController,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                label: l10n?.profileUntScore ?? 'Баллы ЕНТ',
                hintText: '0 – 140',
                controller: untScoreController,
                icon: Icons.score_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  final int? score = int.tryParse(v);
                  if (score == null || score > 140) return 'Max 140';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                label: l10n?.profileIeltsScore ?? 'IELTS',
                hintText: '0.0 – 9.0',
                controller: ieltsScoreController,
                icon: Icons.language_outlined,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d{0,1}(\.\d{0,1})?'),
                  ),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  final double? score = double.tryParse(v);
                  if (score == null || score > 9.0) return 'Max 9.0';
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                label: 'GPA',
                hintText: '0.00 – 4.00',
                controller: gpaController,
                icon: Icons.star_outline_rounded,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d{0,1}(\.\d{0,2})?'),
                  ),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  final double? gpa = double.tryParse(v);
                  if (gpa == null || gpa > 4.0) return 'Max 4.0';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                label: 'Мат. (проф)',
                hintText: '0 – 50',
                controller: mathScoreController,
                icon: Icons.calculate_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  final int? score = int.tryParse(v);
                  if (score == null || score > 50) return 'Max 50';
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
