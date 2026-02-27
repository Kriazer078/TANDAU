import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import '../l10n/app_localizations.dart';
import 'legal/terms_screen.dart';
import 'privacy_policy_screen.dart';
import 'main_navigation_screen.dart';
import 'register_screen.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/google_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // TapGestureRecognizers must be disposed to avoid memory leaks
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TermsScreen()),
        );
      };
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
        );
      };
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final error = await AuthService().login(
        _emailController.text,
        _passwordController.text,
      );
      if (mounted) {
        setState(() => _isLoading = false);
        // If banned, global listener in main.dart will handle navigation
        if (error == AuthService.bannedErrorCode) return;

        if (error == null) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const MainNavigationScreen(),
            ),
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: Stack(
        children: [
          // Decorative background circles
          Positioned(
            top: -50,
            right: -50,
            child: CircleAvatar(
              radius: 150,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.7,
            left: -50,
            child: CircleAvatar(
              radius: 100,
              backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: TextButton(
                        onPressed: _showGuestLoginDialog,
                        child: Text(
                          AppLocalizations.of(context)?.authGuestLogin ??
                              'Войти как гость',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white70
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Logo
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.school,
                          size: 60,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      AppLocalizations.of(context)?.authWelcomeBack ??
                          'Welcome Back',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)?.authLoginContinue ??
                          'Log in to continue your journey',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    CustomTextField(
                      controller: _emailController,
                      label: AppLocalizations.of(context)?.authEmail ?? 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return AppLocalizations.of(
                                context,
                              )?.validationEmail ??
                              'Введите Email';
                        }
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(v)) {
                          return AppLocalizations.of(
                                context,
                              )?.validationEmailFormat ??
                              'Неверный формат Email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: _passwordController,
                      label:
                          AppLocalizations.of(context)?.authPassword ??
                          'Password',
                      icon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _login(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? (AppLocalizations.of(context)?.validationPassword ??
                                'Введите пароль')
                          : null,
                    ),

                    const SizedBox(height: 40),

                    // Premium Button Logic
                    _buildPremiumLoginButton(),

                    const SizedBox(height: 16),

                    // Google Login Button
                    _buildGoogleLoginButton(),

                    const SizedBox(height: 24),

                    // Register Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context)?.authDontHaveAccount ??
                              "No account?",
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context)?.authRegisterNow ??
                                'Register',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumLoginButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                AppLocalizations.of(context)?.authLoginButton ?? 'LOGIN',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
      ),
    );
  }

  Widget _buildGoogleLoginButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading
            ? null
            : () async {
                setState(() => _isLoading = true);
                final error = await AuthService().signInWithGoogle();
                if (mounted) {
                  setState(() => _isLoading = false);
                  // If banned, global listener in main.dart will handle navigation
                  if (error == AuthService.bannedErrorCode) return;

                  if (error == null) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const MainNavigationScreen(),
                      ),
                      (route) => false,
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(error),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const GoogleLogo(size: 24),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)?.authGoogleLogin ??
                  'Sign in with Google',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGuestLoginDialog() {
    bool termsAccepted = false;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (sbContext, dialogSetState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.person_outline, color: AppColors.primary, size: 28),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)?.authGuestTitle ??
                    'Войти как гость',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)?.authGuestWarning ??
                            'В режиме гостя доступ ограничен. Для полного доступа к AI-консультанту и другим функциям необходима регистрация.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: termsAccepted,
                      onChanged: (v) =>
                          dialogSetState(() => termsAccepted = v!),
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        dialogSetState(() {
                          termsAccepted = !termsAccepted;
                        });
                      },
                      child: RichText(
                        text: TextSpan(
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                height: 1.5,
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.grey[400]
                                    : Colors.grey[700],
                              ),
                          children: [
                            TextSpan(
                              text:
                                  AppLocalizations.of(
                                    context,
                                  )?.authTermsIHaveRead ??
                                  'Я согласен с ',
                            ),
                            TextSpan(
                              text:
                                  AppLocalizations.of(context)?.authTermsLink ??
                                  'Условиями использования',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: _termsRecognizer,
                            ),
                            TextSpan(
                              text:
                                  AppLocalizations.of(context)?.authTermsAnd ??
                                  ' и ',
                            ),
                            TextSpan(
                              text:
                                  AppLocalizations.of(
                                    context,
                                  )?.authPrivacyLink ??
                                  'Политикой конфиденциальности',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: _privacyRecognizer,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: TextButton.styleFrom(foregroundColor: Colors.grey),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: termsAccepted
                  ? () async {
                      Navigator.pop(dialogContext); // Close dialog
                      setState(() => _isLoading = true); // Update main screen
                      final error = await AuthService().signInAnonymously();
                      if (mounted) {
                        setState(() => _isLoading = false);
                        if (error == null) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const MainNavigationScreen(),
                            ),
                            (route) => false,
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(error),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Text(
                AppLocalizations.of(context)?.authContinue ?? 'Продолжить',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
