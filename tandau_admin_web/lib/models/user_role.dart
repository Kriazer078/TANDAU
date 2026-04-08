/// Роли пользователей в системе
enum UserRole {
  /// Обычный пользователь (студент)
  user,

  /// Администратор с расширенными правами
  admin;

  /// Получить роль из строки
  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'user':
      default:
        return UserRole.user;
    }
  }

  /// Преобразовать роль в строку
  String toStr() {
    return toString().split('.').last;
  }

  /// Проверка на админа
  bool get isAdmin => this == UserRole.admin;

  /// Проверка на обычного пользователя
  bool get isUser => this == UserRole.user;
}
