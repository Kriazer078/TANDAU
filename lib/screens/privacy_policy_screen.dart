import 'package:flutter/material.dart';
import 'legal/legal_constants.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Конфиденциальность'), elevation: 0),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Политика конфиденциальности и Условия использования',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Обновлено: 16 февраля 2026',
              style: TextStyle(color: Colors.grey),
            ),
            Divider(height: 32),
            Text(
              LegalConstants.termsContent,
              style: TextStyle(fontSize: 15, height: 1.6),
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
