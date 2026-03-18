import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _sendEmail(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'tandau.app.help@gmail.com',
      query: encodeQueryParameters(<String, String>{
        'subject': l10n?.helpEmailSubject ?? 'TANDAU Support: [Question]',
      }),
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n?.helpEmailFallback ??
                    'Write to us at: tandau.app.help@gmail.com',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.helpEmailFallback ??
                  'Write to us at: tandau.app.help@gmail.com',
            ),
          ),
        );
      }
    }
  }

  String encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map(
          (MapEntry<String, String> e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.helpTitle ?? 'Help & Support'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSupportCard(
              context,
              icon: Icons.chat_bubble_outline,
              title: l10n?.helpSupportTeam ?? 'Support team',
              subtitle: l10n?.helpSupportDesc ??
                  'We\'ll reply within 24 hours\ntandau.app.help@gmail.com',
              buttonLabel: l10n?.helpWriteUs ?? 'Write to us',
              onTap: () => _sendEmail(context),
            ),
            const SizedBox(height: 32),
            Text(
              l10n?.helpFaqTitle ?? 'Frequently Asked Questions',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildFaqItem(
              l10n?.helpFaq1Q ??
                  'How are admission chances calculated?',
              l10n?.helpFaq1A ??
                  'Our AI analyzes past years\' data, competition difficulty, and your UNT, GPA, and IELTS scores.',
            ),
            _buildFaqItem(
              l10n?.helpFaq2Q ?? 'Is the grant data up-to-date?',
              l10n?.helpFaq2A ??
                  'Yes, we update the state grants database annually based on official data from the MES RK.',
            ),
            _buildFaqItem(
              l10n?.helpFaq3Q ??
                  'What does the PRO subscription offer?',
              l10n?.helpFaq3A ??
                  'PRO users get access to alternative university lists and extended AI analytics.',
            ),
            _buildFaqItem(
              l10n?.helpFaq4Q ??
                  'How to change the app language?',
              l10n?.helpFaq4A ??
                  'Go to Profile -> Settings -> Language and choose the one you need.',
            ),
            const SizedBox(height: 120),
            Center(
              child: Column(
                children: [
                  Text(
                    l10n?.helpAppVersion ?? 'App version: 1.0.0',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '© 2026 TANDAU Team',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: TextStyle(color: Colors.grey[700], height: 1.5),
          ),
        ),
      ],
    );
  }
}
