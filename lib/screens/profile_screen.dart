import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/theme_manager.dart';
import '../services/locale_manager.dart';
import '../services/auth_service.dart';
import '../l10n/app_localizations.dart';
import 'login_screen.dart';
import 'admin/admin_panel_screen.dart';
import '../models/user_model.dart'; // Import UserModel
import 'edit_profile_screen.dart'; // Import EditProfileScreen
import 'notifications_settings_screen.dart';
import 'help_support_screen.dart';
import 'privacy_policy_screen.dart';
import 'favorites_screen.dart';
import 'paywall_screen.dart';

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
                return Column(
                  children: [
                    if (user != null && !AuthService().isGuest)
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
              subtitle:
                  AppLocalizations.of(context)?.settingsThemeSubtitle ??
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
                  title:
                      AppLocalizations.of(context)?.settingsLanguage ??
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
              title:
                  AppLocalizations.of(context)?.settingsNotifications ??
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

            // Promo Code
            _buildSettingCard(
              context,
              icon: Icons.card_giftcard,
              title: 'Ввести промокод',
              subtitle: 'Активировать PRO или Premium подписку',
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(
                  context,
                ).iconTheme.color?.withValues(alpha: 0.5),
              ),
              onTap: () => _showPromoCodeDialog(context),
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
              subtitle:
                  AppLocalizations.of(context)?.settingsAboutSubtitle ??
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
              subtitle:
                  AppLocalizations.of(context)?.settingsHelpSubtitle ??
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
              subtitle:
                  AppLocalizations.of(context)?.settingsPrivacySubtitle ??
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
              title: 'Поддержать команду TANDAU ❤️',
              subtitle: 'Прямой перевод на Kaspi',
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
                    // Admin Panel - Migration (Visible only to specific admin)
                    // Admin Panel - Migration (Visible ONLY temporarily for setup)
                    if (AuthService().isAdmin)
                      _buildSettingCard(
                        context,
                        icon: Icons.admin_panel_settings,
                        title: l10n?.adminPanelTitle ?? 'Админ Панель',
                        subtitle:
                            l10n?.adminPanelSubtitle ??
                            'Управление пушем и данными',
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
                              builder: (context) => const AdminPanelScreen(),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 48),

                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: () async {
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
    final currentCode =
        LocaleManager().locale.value?.languageCode ??
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
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
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

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)?.settingsAbout ?? 'About TANDAU',
        ),
        content: Text(
          AppLocalizations.of(context)?.aboutContent ?? 'TANDAU application...',
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
    const String kaspiNumber = "+7 705 136 92 31";
    const String kaspiName = "Нұрдәулет А.";

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
                'Поддержать проект',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
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
                    Image.network(
                      'https://w7.pngwing.com/pngs/154/428/png-transparent-kaspi-bank-hd-logo.png',
                      width: 40,
                      height: 40,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.credit_card,
                        size: 40,
                        color: Colors.redAccent,
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
                          const SnackBar(
                            content: Text('Номер скопирован в буфер обмена'),
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
                  child: const Text(
                    'Открыть приложение Kaspi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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

  void _showPromoCodeDialog(BuildContext context) {
    final TextEditingController promoController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Активация промокода'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Введите промокод для активации подписки:'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: promoController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'PROMO123',
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 16.0),
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setState(() => isLoading = true);
                          final code = promoController.text;
                          final error = await AuthService().redeemPromoCode(
                            code,
                          );

                          if (context.mounted) {
                            setState(() => isLoading = false);
                            if (error == null) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Промокод успешно активирован!',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(error),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  child: const Text('Активировать'),
                ),
              ],
            );
          },
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
          const SizedBox(height: 24),
          _buildSubscriptionCard(context, user),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, UserModel user) {
    final isPro =
        user.subscriptionPlan == 'pro' || user.subscriptionPlan == 'premium';
    final planName = user.subscriptionPlan.toUpperCase();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PaywallScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isPro
              ? const LinearGradient(
                  colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    Theme.of(context).cardTheme.color ?? Colors.white,
                    Theme.of(context).cardTheme.color ?? Colors.white,
                  ],
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPro
                ? Colors.transparent
                : Theme.of(context).primaryColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: isPro
              ? [
                  BoxShadow(
                    color: const Color(0xFF8E2DE2).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isPro
                    ? Colors.white.withValues(alpha: 0.2)
                    : Theme.of(context).primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPro
                    ? Icons.workspace_premium_rounded
                    : Icons.star_outline_rounded,
                color: isPro ? Colors.white : Theme.of(context).primaryColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TANDAU $planName',
                    style: TextStyle(
                      color: isPro
                          ? Colors.white
                          : Theme.of(context).textTheme.titleLarge?.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Осталось ИИ-запросов: ${user.aiTokensRemaining}',
                    style: TextStyle(
                      color: isPro
                          ? Colors.white70
                          : Theme.of(context).textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: isPro
                  ? Colors.white70
                  : Theme.of(context).iconTheme.color?.withValues(alpha: 0.5),
              size: 16,
            ),
          ],
        ),
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
}
