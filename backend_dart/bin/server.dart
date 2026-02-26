import 'dart:io';
import 'dart:collection';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:dotenv/dotenv.dart';

import 'package:antigravity_backend/controllers/university_controller.dart';
import 'package:antigravity_backend/controllers/notification_controller.dart';
import 'package:antigravity_backend/services/firebase_service.dart';
import 'package:antigravity_backend/services/gemini_service.dart';
import 'package:antigravity_backend/services/knowledge_service.dart';

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

  // Initialize Knowledge Service (RAG)
  final knowledgeService = KnowledgeService(firebaseService);
  await knowledgeService.init();

  // Initialize Controller
  final universityController =
      UniversityController(firebaseService, geminiService, knowledgeService);
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
    <p>Если у вас есть вопросы к этой политике конфиденциальности, пожалуйста, свяжитесь с нами:</p>
    <p>Email: <a href="mailto:tandau.app.help@gmail.com">tandau.app.help@gmail.com</a></p>
</body>
</html>
''';
    return Response.ok(html,
        headers: {'content-type': 'text/html; charset=utf-8'});
  });

  // Account Deletion Page (required by Google Play)
  router.get('/delete-account', (Request req) {
    final html = '''
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Удаление аккаунта TANDAU</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; color: #333; background: #f5f5f5; }
        .container { max-width: 700px; margin: 40px auto; background: white; border-radius: 12px; box-shadow: 0 2px 20px rgba(0,0,0,0.1); overflow: hidden; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 40px 32px; color: white; }
        .header h1 { font-size: 28px; font-weight: 700; }
        .header p { margin-top: 8px; opacity: 0.9; font-size: 16px; }
        .content { padding: 32px; }
        .warning { background: #fff3cd; border: 1px solid #ffc107; border-radius: 8px; padding: 16px; margin-bottom: 24px; }
        .warning strong { color: #856404; }
        h2 { color: #2C3E50; font-size: 18px; margin: 24px 0 12px; }
        .step { display: flex; gap: 16px; margin-bottom: 16px; align-items: flex-start; }
        .step-num { background: #667eea; color: white; width: 32px; height: 32px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-weight: 700; flex-shrink: 0; font-size: 14px; }
        .step-text { padding-top: 4px; }
        .divider { border: none; border-top: 1px solid #eee; margin: 28px 0; }
        .contact-box { background: #f0f4ff; border-radius: 8px; padding: 20px; text-align: center; }
        .contact-box p { color: #555; margin-bottom: 8px; }
        .contact-box a { color: #667eea; font-weight: 600; text-decoration: none; font-size: 16px; }
        .note { background: #fce4ec; border-radius: 8px; padding: 16px; margin-top: 20px; font-size: 14px; color: #c62828; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🗑️ Удаление аккаунта TANDAU</h1>
            <p>Вы можете удалить свой аккаунт и все связанные данные в любое время</p>
        </div>
        <div class="content">
            <div class="warning">
                <strong>⚠️ Важно:</strong> После удаления аккаунта все ваши данные будут безвозвратно удалены, включая профиль, сохранённые университеты, историю AI-консультаций и подписки.
            </div>

            <h2>Способ 1: Удаление через приложение (быстро)</h2>
            <div class="step">
                <div class="step-num">1</div>
                <div class="step-text">Откройте приложение <strong>TANDAU</strong> и войдите в аккаунт</div>
            </div>
            <div class="step">
                <div class="step-num">2</div>
                <div class="step-text">Перейдите на вкладку <strong>«Профиль»</strong> (иконка человека внизу экрана)</div>
            </div>
            <div class="step">
                <div class="step-num">3</div>
                <div class="step-text">Прокрутите вниз и нажмите <strong>«Удалить аккаунт»</strong></div>
            </div>
            <div class="step">
                <div class="step-num">4</div>
                <div class="step-text">Подтвердите удаление в появившемся диалоге. Аккаунт будет удалён немедленно.</div>
            </div>

            <hr class="divider">

            <h2>Что будет удалено:</h2>
            <ul style="padding-left: 20px; color: #555;">
                <li>Имя, email и данные профиля</li>
                <li>Сохранённые университеты и избранное</li>
                <li>История чатов с AI-консультантом</li>
                <li>Баллы ЕНТ и образовательные данные</li>
                <li>Данные подписки (TANDAU+)</li>
                <li>Firebase-аккаунт и токены авторизации</li>
            </ul>

            <div class="note">
                📌 Обратите внимание: если у вас активна платная подписка (PRO/Premium), отмените её отдельно в настройках Google Play до удаления аккаунта, чтобы избежать повторных списаний.
            </div>

            <hr class="divider">

            <div class="contact-box">
                <p>Если у вас нет доступа к приложению или возникли проблемы — напишите нам, и мы удалим ваш аккаунт вручную в течение 3 рабочих дней.</p>
                <a href="mailto:tandau.app.help@gmail.com">📧 tandau.app.help@gmail.com</a>
            </div>
        </div>
    </div>
</body>
</html>
''';
    return Response.ok(html,
        headers: {'content-type': 'text/html; charset=utf-8'});
  });

  // ── CORS middleware ──────────────────────────────────
  Middleware corsMiddleware() {
    const allowedOrigins = {
      'https://tandau.kz',
      'https://www.tandau.kz',
      'http://localhost',
    };
    return (Handler innerHandler) {
      return (Request request) async {
        final origin = request.requestedUri.origin;
        final corsHeaders = <String, String>{
          'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization',
          'Access-Control-Max-Age': '86400',
        };
        if (allowedOrigins.contains(origin)) {
          corsHeaders['Access-Control-Allow-Origin'] = origin;
        }
        // Pre-flight
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: corsHeaders);
        }
        final response = await innerHandler(request);
        return response.change(headers: corsHeaders);
      };
    };
  }

  // ── Rate-limiting middleware (60 requests per minute per IP) ──
  final Map<String, Queue<DateTime>> rateLimitMap = {};
  const int maxRequests = 60;
  const Duration rateLimitWindow = Duration(minutes: 1);

  Middleware rateLimitMiddleware() {
    return (Handler innerHandler) {
      return (Request request) async {
        final ip =
            (request.context['shelf.io.connection_info'] as HttpConnectionInfo?)
                    ?.remoteAddress
                    .address ??
                'unknown';

        final now = DateTime.now();
        final queue = rateLimitMap.putIfAbsent(ip, () => Queue<DateTime>());

        // Remove entries outside the window
        while (
            queue.isNotEmpty && now.difference(queue.first) > rateLimitWindow) {
          queue.removeFirst();
        }

        if (queue.length >= maxRequests) {
          return Response(
            429,
            body: 'Too many requests. Try again later.',
            headers: {'Retry-After': '60'},
          );
        }

        queue.addLast(now);
        return innerHandler(request);
      };
    };
  }

  // Middleware pipeline
  final handler = Pipeline()
      .addMiddleware(corsMiddleware())
      .addMiddleware(rateLimitMiddleware())
      .addMiddleware(logRequests())
      .addHandler(router.call);

  // Start Server
  final server = await io.serve(handler, '0.0.0.0', port);
  stderr.writeln('Antigravity Server listening on port ${server.port}');
}
