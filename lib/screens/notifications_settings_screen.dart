import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> {
  bool _grantUpdates = true;
  bool _universityNews = false;
  bool _aiCareerAdvice = true;
  bool _marketingEmails = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Уведомления'), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildNotificationSection(
            title: 'Учебные оповещения',
            children: [
              _buildSwitchTile(
                title: 'Обновления по грантам',
                subtitle: 'Узнавайте первыми об изменении баллов и мест',
                value: _grantUpdates,
                onChanged: (val) => setState(() => _grantUpdates = val),
              ),
              _buildSwitchTile(
                title: 'Новости университетов',
                subtitle: 'Дни открытых дверей и важные даты',
                value: _universityNews,
                onChanged: (val) => setState(() => _universityNews = val),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildNotificationSection(
            title: 'TANDAU AI',
            children: [
              _buildSwitchTile(
                title: 'Советы по карьере',
                subtitle: 'Персональные рекомендации от ИИ',
                value: _aiCareerAdvice,
                onChanged: (val) => setState(() => _aiCareerAdvice = val),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildNotificationSection(
            title: 'Другое',
            children: [
              _buildSwitchTile(
                title: 'Маркетинг и акции',
                subtitle: 'Скидки от партнеров и новости платформы',
                value: _marketingEmails,
                onChanged: (val) => setState(() => _marketingEmails = val),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
              letterSpacing: 1.2,
            ),
          ),
        ),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[600], fontSize: 13),
      ),
      activeThumbColor: AppColors.primary,
    );
  }
}
