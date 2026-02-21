import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import '../l10n/app_localizations.dart';
import 'login_screen.dart';
import 'legal/terms_screen.dart';
import 'privacy_policy_screen.dart';
import 'main_navigation_screen.dart';
import '../widgets/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _termsAccepted = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.validationTerms ??
                'Необходимо согласиться с Условиями использования',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      debugPrint('🔵 REGSCR: Начало процесса регистрации...');
      String? registerError;
      try {
        debugPrint('🔵 REGSCR: Вызов AuthService().register...');
        final authService = AuthService();
        registerError = await authService
            .register(
              _nameController.text.trim(),
              _emailController.text.trim(),
              _passwordController.text, // 🛡️ Security: do not trim passwords
            )
            .timeout(
              const Duration(seconds: 40),
              onTimeout: () {
                debugPrint('🔴 REGSCR: Таймаут вызова register!');
                return 'Превышено время ожидания регистрации';
              },
            );

        debugPrint('🔵 REGSCR: Ответ от сервиса получен: $registerError');

        if (mounted) {
          setState(() => _isLoading = false);
          if (registerError == null) {
            debugPrint('🟢 REGSCR: Регистрация успешна! Переход...');
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const MainNavigationScreen(),
              ),
              (route) => false,
            );
          } else {
            debugPrint('🟠 REGSCR: Ошибка регистрации: $registerError');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(registerError),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      } catch (e, stack) {
        debugPrint('🔴 REGSCR: Критическая ошибка при регистрации: $e');
        debugPrint('🔴 REGSCR: Стек вызовов: $stack');
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Критическая ошибка: $e'),
              backgroundColor: AppColors.error,
            ),
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
          // Decorative background elements
          Positioned(
            top: -50,
            left: -50,
            child: CircleAvatar(
              radius: 120,
              backgroundColor: AppColors.primary.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            bottom: 100,
            right: -30,
            child: CircleAvatar(
              radius: 80,
              backgroundColor: AppColors.secondary.withValues(alpha: 0.08),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    IconButton(
                      alignment: Alignment.centerLeft,
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      AppLocalizations.of(context)?.authCreateAccount ??
                          'Create Account',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)?.authSubtitle ??
                          'Присоединяйтесь к TANDAU и начните свой путь к образованию',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const SizedBox(height: 40),

                    CustomTextField(
                      controller: _nameController,
                      label:
                          AppLocalizations.of(context)?.authFullName ??
                          'Full Name',
                      icon: Icons.person_outline,
                      validator: (v) => v!.isEmpty
                          ? (AppLocalizations.of(context)?.authRequired ??
                                'Required')
                          : null,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: _emailController,
                      label: AppLocalizations.of(context)?.authEmail ?? 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
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
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return AppLocalizations.of(
                                context,
                              )?.validationPassword ??
                              'Введите пароль';
                        }
                        if (v.length < 6) {
                          return AppLocalizations.of(
                                context,
                              )?.validationMinLength(6) ??
                              'Минимум 6 символов';
                        }
                        if (!v.contains(RegExp(r'[0-9]'))) {
                          return AppLocalizations.of(
                                context,
                              )?.validationDigitRequired ??
                              'Пароль должен содержать хотя бы одну цифру';
                        }
                        return null;
                      },
                    ),

                    // Premium Register Button
                    const SizedBox(height: 32),
                    _buildPremiumRegisterButton(),

                    const SizedBox(height: 24),

                    // Terms and Conditions Checkbox
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _termsAccepted,
                            onChanged: (v) =>
                                setState(() => _termsAccepted = v ?? false),
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
                              setState(() {
                                _termsAccepted = !_termsAccepted;
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
                                        )?.authTermsRegister ??
                                        'Регистрируясь, вы соглашаетесь с ',
                                  ),
                                  TextSpan(
                                    text:
                                        AppLocalizations.of(
                                          context,
                                        )?.authTermsLink ??
                                        'Условиями',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const TermsScreen(),
                                          ),
                                        );
                                      },
                                  ),
                                  TextSpan(
                                    text:
                                        AppLocalizations.of(
                                          context,
                                        )?.authTermsAnd ??
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
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const PrivacyPolicyScreen(),
                                          ),
                                        );
                                      },
                                  ),
                                  if (AppLocalizations.of(
                                        context,
                                      )?.localeName ==
                                      'kk')
                                    TextSpan(
                                      text:
                                          AppLocalizations.of(
                                            context,
                                          )?.authTermsSuffix ??
                                          ' келісемін',
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(
                                context,
                              )?.authAlreadyHaveAccount ??
                              "Have an account?",
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context)?.authLogin ?? 'Login',
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

  Widget _buildPremiumRegisterButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 56,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: _termsAccepted ? AppColors.primaryGradient : null,
        color: _termsAccepted
            ? null
            : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: _termsAccepted
            ? null
            : Border.all(color: isDark ? Colors.white10 : Colors.grey[300]!),
        boxShadow: _termsAccepted
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: ElevatedButton(
        onPressed: (_isLoading || !_termsAccepted) ? null : _register,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent, // Important
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                AppLocalizations.of(context)?.authRegisterNow ?? 'REGISTER',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: _termsAccepted
                      ? Colors.white
                      : (isDark ? Colors.white24 : Colors.grey[400]),
                ),
              ),
      ),
    );
  }
}
