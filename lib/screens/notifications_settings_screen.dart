import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Default true because they are important core features
      _grantUpdates = prefs.getBool('notif_grantUpdates') ?? true;
      _universityNews = prefs.getBool('notif_universityNews') ?? true;
      _aiCareerAdvice = prefs.getBool('notif_aiCareerAdvice') ?? true;
      _marketingEmails = prefs.getBool('notif_marketingEmails') ?? false;
      _isLoading = false;
    });

    // Make sure init matches Firebase state if they were true by default but we never subscribed
    if (_grantUpdates) {
      FirebaseMessaging.instance.subscribeToTopic('grant_updates');
    }
    if (_universityNews) {
      FirebaseMessaging.instance.subscribeToTopic('university_news');
    }
    if (_aiCareerAdvice) {
      FirebaseMessaging.instance.subscribeToTopic('ai_career_advice');
    }
    if (_marketingEmails) {
      FirebaseMessaging.instance.subscribeToTopic('marketing');
    }
  }

  Future<void> _updatePreference(String key, bool value, String topic) async {
    // Optimistic UI update
    setState(() {
      if (key == 'notif_grantUpdates') _grantUpdates = value;
      if (key == 'notif_universityNews') _universityNews = value;
      if (key == 'notif_aiCareerAdvice') _aiCareerAdvice = value;
      if (key == 'notif_marketingEmails') _marketingEmails = value;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);

    try {
      if (value) {
        await FirebaseMessaging.instance.subscribeToTopic(topic);
      } else {
        await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
      }
    } catch (e) {
      debugPrint('Error updating FCM topic: $topic - $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Уведомления'), elevation: 0),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
                onChanged: (val) => _updatePreference(
                  'notif_grantUpdates',
                  val,
                  'grant_updates',
                ),
              ),
              _buildSwitchTile(
                title: 'Новости университетов',
                subtitle: 'Дни открытых дверей и важные даты',
                value: _universityNews,
                onChanged: (val) => _updatePreference(
                  'notif_universityNews',
                  val,
                  'university_news',
                ),
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
                onChanged: (val) => _updatePreference(
                  'notif_aiCareerAdvice',
                  val,
                  'ai_career_advice',
                ),
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
                onChanged: (val) => _updatePreference(
                  'notif_marketingEmails',
                  val,
                  'marketing',
                ),
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
