import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shimmer/shimmer.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../theme/theme_manager.dart';
import '../services/locale_manager.dart';
import '../services/auth_service.dart';
import '../l10n/app_localizations.dart';
import 'login_screen.dart';
import '../models/user_model.dart';
import 'edit_profile_screen.dart';
import 'notifications_settings_screen.dart';
import 'help_support_screen.dart';
import 'privacy_policy_screen.dart';
import 'favorites_screen.dart';
import 'feedback_screen.dart';
import 'my_feedbacks_screen.dart';
import '../widgets/like_review_widgets.dart';
import 'roi_screen.dart';
import 'career_test_hub_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // State for language selection
  // String _selectedLanguage = 'Русский'; // Replaced by LocaleManager

  final Map<String, String> _languages = {
    'ru': 'Русский',
    'kk': 'Қазақша',
    'en': 'English',
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(AppLocalizations.of(context)?.profileTitle ?? 'Профиль'),
        elevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            ValueListenableBuilder<UserModel?>(
              valueListenable: AuthService().currentUser,
              builder: (context, user, _) {
                final isAuthLoading =
                    FirebaseAuth.instance.currentUser != null && user == null;

                return Column(
                  children: [
                    if (isAuthLoading)
                      _buildShimmerHeader(context)
                    else if (user != null && !AuthService().isGuest)
                      _buildUserHeader(context, user)
                    else
                      _buildGuestHeader(context),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),

            // Settings Section
            Text(
              AppLocalizations.of(context)?.settingsTitle ?? 'Settings',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Dark Mode Toggle
            _buildSettingCard(
              context,
              icon: Icons.dark_mode,
              title: AppLocalizations.of(context)?.settingsTheme ?? 'Dark Mode',
              subtitle: AppLocalizations.of(context)?.settingsThemeSubtitle ??
                  'Switch to dark mode',
              trailing: Switch(
                value: isDarkMode,
                onChanged: (value) {
                  ThemeManager().toggleTheme(value);
                },
              ),
            ),
            const SizedBox(height: 12),

            // Language Selector
            ValueListenableBuilder<Locale?>(
              valueListenable: LocaleManager().locale,
              builder: (context, locale, child) {
                // Если locale == null, берем системный язык из контекста
                final currentLocale = locale ?? Localizations.localeOf(context);

                return _buildSettingCard(
                  context,
                  icon: Icons.language,
                  title: AppLocalizations.of(context)?.settingsLanguage ??
                      'Language',
                  subtitle: _languages[currentLocale.languageCode] ?? 'Русский',
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Theme.of(
                      context,
                    ).iconTheme.color?.withValues(alpha: 0.5),
                  ),
                  onTap: () => _showLanguageDialog(),
                );
              },
            ),
            const SizedBox(height: 12),

            // Notifications
            _buildSettingCard(
              context,
              icon: Icons.notifications,
              title: AppLocalizations.of(context)?.settingsNotifications ??
                  'Notifications',
              subtitle:
                  AppLocalizations.of(context)?.settingsNotificationsSubtitle ??
                      'Configure notifications',
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(
                  context,
                ).iconTheme.color?.withValues(alpha: 0.5),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsSettingsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // Saved Universities
            _buildSettingCard(
              context,
              icon: Icons.favorite_rounded,
              title: AppLocalizations.of(context)?.navFavorites ?? 'Saved',
              subtitle:
                  l10n?.profileSavedSubtitle ?? 'Ваши сохранённые университеты',
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(
                  context,
                ).iconTheme.color?.withValues(alpha: 0.5),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FavoritesScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // ROI Calculator
            _buildSettingCard(
              context,
              icon: Icons.calculate_rounded,
              title: 'Окупаемость обучения',
              subtitle: 'Расчет выгоды и стоимости',
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(
                  context,
                ).iconTheme.color?.withValues(alpha: 0.5),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RoiScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // Career Test (Профориентация)
            _buildSettingCard(
              context,
              icon: Icons.psychology_rounded,
              title: 'Профориентация',
              subtitle: 'Узнай свои склонности и подходящие ГОП',
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(
                  context,
                ).iconTheme.color?.withValues(alpha: 0.5),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CareerTestHubScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // Feedback
            _buildSettingCard(
              context,
              icon: Icons.feedback_rounded,
              title: AppLocalizations.of(context)?.feedbackTitle ?? 'Feedback',
              subtitle: AppLocalizations.of(context)?.feedbackMessageHint ??
                  'Оставьте отзыв или предложение',
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(
                  context,
                ).iconTheme.color?.withValues(alpha: 0.5),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FeedbackScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // My Feedbacks History
            _buildSettingCard(
              context,
              icon: Icons.history_rounded,
              title: AppLocalizations.of(context)?.myFeedbacksTitle ?? 'My Feedbacks',
              subtitle: AppLocalizations.of(context)?.myFeedbacksEmpty ??
                  'История ваших обращений',
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(
                  context,
                ).iconTheme.color?.withValues(alpha: 0.5),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyFeedbacksScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // About Section
            Text(
              AppLocalizations.of(context)?.settingsAbout ?? 'About App',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildSettingCard(
              context,
              icon: Icons.info,
              title: AppLocalizations.of(context)?.settingsAbout ?? 'About',
              subtitle: AppLocalizations.of(context)?.settingsAboutSubtitle ??
                  'Information about TANDAU',
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(
                  context,
                ).iconTheme.color?.withValues(alpha: 0.5),
              ),
              onTap: () {
                _showAboutDialog();
              },
            ),
            const SizedBox(height: 12),

            _buildSettingCard(
              context,
              icon: Icons.help,
              title: AppLocalizations.of(context)?.settingsHelp ?? 'Help',
              subtitle: AppLocalizations.of(context)?.settingsHelpSubtitle ??
                  'FAQ and support',
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(
                  context,
                ).iconTheme.color?.withValues(alpha: 0.5),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HelpSupportScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            _buildSettingCard(
              context,
              icon: Icons.privacy_tip,
              title: AppLocalizations.of(context)?.settingsPrivacy ?? 'Privacy',
              subtitle: AppLocalizations.of(context)?.settingsPrivacySubtitle ??
                  'Privacy policy',
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(
                  context,
                ).iconTheme.color?.withValues(alpha: 0.5),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrivacyPolicyScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            _buildSettingCard(
              context,
              icon: Icons.volunteer_activism_rounded,
              title: AppLocalizations.of(context)?.supportTitle ??
                  'Поддержать команду TANDAU ❤️',
              subtitle: AppLocalizations.of(context)?.supportSubtitle ??
                  'Прямой перевод на Kaspi',
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(
                  context,
                ).iconTheme.color?.withValues(alpha: 0.5),
              ),
              onTap: () => _showKaspiSupportDialog(context),
            ),
            const SizedBox(height: 32),

            ValueListenableBuilder<UserModel?>(
              valueListenable: AuthService().currentUser,
              builder: (context, user, _) {
                if (user == null) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [


                    const SizedBox(height: 16),

                    // Delete Account Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(
                                l10n?.profileDeleteAccountTitle ??
                                    'Удалить аккаунт?',
                              ),
                              content: Text(
                                l10n?.profileDeleteAccountContent ??
                                    'Вы уверены, что хотите удалить аккаунт? Все ваши данные будут удалены безвозвратно.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text(
                                    l10n?.profileDeleteAccountCancel ??
                                        'Отмена',
                                  ),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    final Uri url = Uri.parse(
                                      'https://tandau-backend.onrender.com/delete-account',
                                    );
                                    if (await canLaunchUrl(url)) {
                                      await launchUrl(
                                        url,
                                        mode: LaunchMode.externalApplication,
                                      );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              l10n?.profileDeleteAccountSent ??
                                                  'Запрос на удаление отправлен. Следуйте инструкциям на открывшейся странице.',
                                            ),
                                            backgroundColor:
                                                Colors.orange.shade700,
                                            duration: const Duration(
                                              seconds: 5,
                                            ),
                                          ),
                                        );
                                      }
                                    } else {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              l10n?.profileDeleteAccountErrorLink ??
                                                  'Не удалось открыть ссылку',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  child: Text(
                                    l10n?.profileDeleteAccountConfirm ??
                                        'Удалить',
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.person_remove,
                          color: Colors.grey,
                        ),
                        label: Text(
                          l10n?.profileDeleteAccount ?? 'Удалить аккаунт',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Colors.grey,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          LikeButton.clearCache(); // ⚡ Clear like cache
                          await AuthService().logout();
                          if (context.mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                              (route) => false,
                            );
                          }
                        },
                        icon: const Icon(Icons.logout, color: Colors.red),
                        label: Text(
                          AppLocalizations.of(context)?.authLogout ?? 'Logout',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                  ),
                ],
              ),
            ),
            trailing ?? const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    // Получаем текущий код языка (из настроек или системы)
    final currentCode = LocaleManager().locale.value?.languageCode ??
        Localizations.localeOf(context).languageCode;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)?.dialogLanguageTitle ?? 'Выберите язык',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _languages.entries.map((entry) {
            final isSelected = entry.key == currentCode;
            return ListTile(
              title: Text(entry.value),
              leading: Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color:
                    isSelected ? Theme.of(context).primaryColor : Colors.grey,
              ),
              onTap: () {
                LocaleManager().setLocale(entry.key);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _showAboutDialog() async {
    String version = '1.0.0';
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      version = packageInfo.version;
    } catch (_) {}

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)?.settingsAbout ?? 'About TANDAU',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)?.aboutContent ?? 'TANDAU application...',
            ),
            const SizedBox(height: 16),
            Text(
              'Версия: $version',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)?.commonOk ?? 'OK'),
          ),
        ],
      ),
    );
  }

  void _showKaspiSupportDialog(BuildContext context) {
    // Номер и имя для переводов Kaspi
    const String kaspiNumber = "4400430351854929";
    const String kaspiName = "Номер карты Kaspi";

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.redAccent,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)?.supportProject ??
                    'Поддержать проект',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)?.supportDescription ??
                    'Будем рады любой поддержке! Все средства идут на оплату серверов для ИИ и развитие TANDAU.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                    ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF14635).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Color(0xFFF14635),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            kaspiName,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            kaspiNumber,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.blue),
                      onPressed: () {
                        Clipboard.setData(
                          const ClipboardData(text: kaspiNumber),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(
                                    context,
                                  )?.supportNumberCopied ??
                                  'Номер скопирован в буфер обмена',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF14635), // Kaspi Red
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final Uri kaspiUrl = Uri.parse('kaspi://');
                    if (await canLaunchUrl(kaspiUrl)) {
                      await launchUrl(kaspiUrl);
                    } else {
                      // Fallback to web link if Kaspi app is not installed
                      final Uri kaspiWebUrl = Uri.parse('https://kaspi.kz/');
                      await launchUrl(
                        kaspiWebUrl,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  child: Text(
                    AppLocalizations.of(context)?.supportOpenKaspi ??
                        'Открыть приложение Kaspi',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserHeader(BuildContext context, UserModel user) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: user.photoUrl != null && user.photoUrl!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      user.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.person,
                          size: 60,
                          color: Theme.of(context).primaryColor,
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                    ),
                  )
                : Icon(
                    Icons.person,
                    size: 60,
                    color: Theme.of(context).primaryColor,
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            user.name,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(user: user),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              side: BorderSide(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              AppLocalizations.of(context)?.editProfileTitle ?? 'Edit Profile',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestHeader(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline,
              size: 60,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)?.authWelcome ?? 'Welcome!',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)?.authGuestMessage ??
                'Войдите в аккаунт, чтобы получить доступ ко всем функциям',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              AppLocalizations.of(context)?.authLoginNow ?? 'Login',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Center(
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 16),
            Container(width: 150, height: 24, color: Colors.white),
            const SizedBox(height: 4),
            Container(width: 200, height: 16, color: Colors.white),
            const SizedBox(height: 16),
            Container(
              width: 140,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
