import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';

class GuestGuard {
  /// Проверяет, является ли текущий пользователь гостем.
  /// Если пользователь гость, показывает диалог с предложением войти
  /// и возвращает false.
  /// Если пользователь авторизован, возвращает true.
  static bool check(BuildContext context) {
    if (AuthService().currentUser.value == null) {
      showGuestDialog(context);
      return false;
    }
    return true;
  }

  static void showGuestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Требуется авторизация'),
        content: const Text(
          'Эта функция доступна только авторизованным пользователям. Пожалуйста, войдите или зарегистрируйтесь.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            child: const Text('Войти'),
          ),
        ],
      ),
    );
  }
}
