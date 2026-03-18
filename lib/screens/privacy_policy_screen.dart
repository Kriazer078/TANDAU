import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'legal/legal_constants.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.privacyTitle ?? 'Privacy'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.privacyHeading ??
                  'Privacy Policy & Terms of Use',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n?.privacyUpdated ?? 'Updated: February 24, 2026',
              style: const TextStyle(color: Colors.grey),
            ),
            const Divider(height: 32),
            const Text(
              LegalConstants.termsContent,
              style: TextStyle(fontSize: 15, height: 1.6),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
