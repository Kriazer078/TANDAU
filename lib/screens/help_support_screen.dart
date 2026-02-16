import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Помощь и поддержка'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSupportCard(
              context,
              icon: Icons.chat_bubble_outline,
              title: 'Служба поддержки',
              subtitle: 'Мы ответим в течение 24 часов',
              buttonLabel: 'Написать нам',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Открытие чата поддержки...')),
                );
              },
            ),
            const SizedBox(height: 32),
            const Text(
              'Часто задаваемые вопросы',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildFaqItem(
              'Как рассчитываются шансы на поступление?',
              'Наша нейросеть анализирует данные прошлых лет, сложность конкурса и ваши баллы ЕНТ, GPA и IELTS.',
            ),
            _buildFaqItem(
              'Данные по грантам актуальны?',
              'Да, мы обновляем базу данных государственных грантов ежегодно на основе официальных данных МНВО РК.',
            ),
            _buildFaqItem(
              'Что дает PRO подписка?',
              'PRO пользователи получают доступ к списку альтернативных вузов и расширенной аналитике от ИИ.',
            ),
            _buildFaqItem(
              'Как сменить язык приложения?',
              'Перейдите в Профиль -> Настройки -> Язык и выберите нужный.',
            ),
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  Text(
                    'Версия приложения: 1.0.0',
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
