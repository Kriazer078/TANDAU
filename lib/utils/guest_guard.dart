import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';
import '../l10n/app_localizations.dart';

class GuestGuard {
  /// Проверяет, является ли текущий пользователь гостем.
  /// Если пользователь гость, показывает диалог с предложением войти
  /// и возвращает false.
  /// Если пользователь авторизован, возвращает true.
  static bool check(BuildContext context) {
    if (AuthService().isGuest) {
      showGuestDialog(context);
      return false;
    }
    return true;
  }

  static void showGuestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n?.authRequired ?? 'Требуется авторизация'),
          content: Text(
            l10n?.authGuestMessage ??
                'Эта функция доступна только авторизованным пользователям. Пожалуйста, войдите или зарегистрируйтесь.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n?.commonCancel ?? 'Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: Text(l10n?.authLogin ?? 'Войти'),
            ),
          ],
        );
      },
    );
  }
}
