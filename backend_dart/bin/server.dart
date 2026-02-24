import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:dotenv/dotenv.dart';

import 'package:antigravity_backend/controllers/university_controller.dart';
import 'package:antigravity_backend/controllers/notification_controller.dart';
import 'package:antigravity_backend/services/firebase_service.dart';
import 'package:antigravity_backend/services/gemini_service.dart';

void main(List<String> args) async {
  // Load environment variables
  var env = DotEnv(includePlatformEnvironment: true);
  if (File('.env').existsSync()) {
    env.load();
  }

  final projectId = env['FIREBASE_PROJECT_ID'] ?? 'your-project-id';
  final geminiKey = env['GEMINI_API_KEY'] ?? '';
  final port = int.parse(env['PORT'] ?? '8080');

  // Initialize Services
  final firebaseService = FirebaseService(projectId);
  await firebaseService.init();

  final geminiService = GeminiService(geminiKey);

  // Initialize Controller
  final universityController =
      UniversityController(firebaseService, geminiService);
  final notificationController = NotificationController(firebaseService);

  // Router
  final router = Router();
  router.mount('/api/v1', universityController.router.call);
  router.mount('/api/v1/notifications', notificationController.router.call);

  // Health check
  router.get('/health', (Request req) => Response.ok('OK'));

  // Privacy Policy
  router.get('/privacy', (Request req) {
    final html = '''
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Политика конфиденциальности TANDAU</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; color: #333; max-width: 800px; margin: 0 auto; padding: 20px; }
        h1, h2 { color: #2C3E50; }
        a { color: #3498DB; text-decoration: none; }
    </style>
</head>
<body>
    <h1>Политика конфиденциальности приложения TANDAU</h1>
    <p><strong>Последнее обновление: 24 февраля 2026 г.</strong></p>

    <h2>1. Какую информацию мы собираем</h2>
    <p>Мы получаем вашу информацию через Google Sign-In, Apple Sign-In и регистрацию по Email, а также другие данные, необходимые для работы приложения. Конкретно:</p>
    <ul>
        <li>Имя и фамилию</li>
        <li>Адрес электронной почты</li>
        <li>Уникальный идентификатор устройства и Firebase UID</li>
        <li>Данные о вашем образовании, результатах ЕНТ и предпочтениях для рекомендаций</li>
    </ul>

    <h2>2. Как мы используем вашу информацию</h2>
    <p>Мы используем собранные данные для оценки шансов на получение образовательного гранта, генерации персонализированных стратегий поступления, работы персонального ИИ-консультанта и обеспечения безопасности вашего аккаунта.</p>

    <h2>3. Защита данных и передача третьим лицам</h2>
    <p>Ваши данные надежно защищены с помощью протоколов безопасности Google (Firebase Authentication, Firestore). Мы не продаем ваши личные данные третьим лицам. Доступ к данным имеет только автоматизированная система генерации рекомендаций.</p>

    <h2>4. Удаление аккаунта</h2>
    <p>Вы можете запросить полное удаление вашего аккаунта и всех связанных с ним данных в любой момент прямо из настроек профиля внутри приложения.</p>

    <h2>5. Контакты</h2>
    <p>Если у вас есть вопросы к этой политике конфиденциальности, пожалуйста, свяжитесь с нами.</p>
</body>
</html>
''';
    return Response.ok(html,
        headers: {'content-type': 'text/html; charset=utf-8'});
  });

  // Middleware pipeline
  final handler =
      Pipeline().addMiddleware(logRequests()).addHandler(router.call);

  // Start Server
  final server = await io.serve(handler, '0.0.0.0', port);
  stderr.writeln('Antigravity Server listening on port ${server.port}');
}
