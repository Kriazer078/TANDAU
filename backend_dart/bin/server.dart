import 'dart:io';
import 'dart:convert';
import 'dart:collection';
import 'dart:async';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:dotenv/dotenv.dart';

import 'package:antigravity_backend/controllers/university_controller.dart';
import 'package:antigravity_backend/controllers/notification_controller.dart';
import 'package:antigravity_backend/services/firebase_service.dart';
import 'package:antigravity_backend/services/openai_service.dart';
import 'package:antigravity_backend/services/knowledge_service.dart';
import 'package:antigravity_backend/services/cache_service.dart';
import 'package:antigravity_backend/services/ai_logger_service.dart';
import 'package:antigravity_backend/services/prompt_config_service.dart';
import 'package:antigravity_backend/services/cost_tracker_service.dart';

void main(List<String> args) async {
  // Load environment variables
  var env = DotEnv(includePlatformEnvironment: true);
  if (File('.env').existsSync()) {
    env.load();
  }

  final projectId = env['FIREBASE_PROJECT_ID'] ?? 'tandau-app';
  final groqApiKey = env['GROQ_API_KEY'] ?? env['OPENAI_API_KEY'] ?? '';
  final port = int.parse(env['PORT'] ?? '8080');

  stderr.writeln('🆔 Using Project ID: $projectId');

  // Initialize Services
  final firebaseService = FirebaseService(projectId);
  final knowledgeService = KnowledgeService(firebaseService);
  final aiService = OpenAIService(groqApiKey);

  stderr.writeln('🚀 Starting services initialization...');

  try {
    // 1. Core Firebase Init (must be fast)
    await firebaseService.init().timeout(const Duration(seconds: 10), onTimeout: () {
      throw Exception('Firebase initialization timed out (10s)');
    });
    stderr.writeln('✅ Firebase Service initialized');

    // 2. Knowledge Base Init (run in background to avoid blocking health check)
    // We don't await this directly if it takes too long
    unawaited(knowledgeService.init().then((_) {
      stderr.writeln('✅ Knowledge Base background indexing complete');
    }).catchError((e) {
      stderr.writeln('⚠️ Knowledge Base background init failed: $e');
    }));

  } catch (e, stack) {
    stderr.writeln('❌ CRITICAL ERROR during service initialization: $e');
    stderr.writeln(stack);
    // Note: We intentionally don't exit(1) here so the health check endpoint 
    // can still return an error message rather than a generic server crash.
  }

  // 📦 Initialize Cache Service
  final cacheService = CacheService();
  firebaseService.setCacheService(cacheService);
  stderr.writeln('📦 Cache Service initialized');

  // 💰 Initialize Cost Tracker
  final costTracker = CostTrackerService();
  aiService.setCostTracker(costTracker);
  stderr.writeln('💰 Cost Tracker initialized');

  // 📊 Initialize AI Logger
  final aiLogger = AILoggerService(
    firebaseService.firestoreApi,
    projectId,
  );
  stderr.writeln('📊 AI Logger initialized');

  // 🧪 Initialize Prompt Config (A/B testing)
  final promptConfig = PromptConfigService(
    firebaseService.firestoreApi,
    projectId,
  );
  try {
    await promptConfig.init();
    stderr.writeln('🧪 Prompt Config initialized');
  } catch (e) {
    stderr.writeln('⚠️ Prompt Config init failed (non-critical): $e');
  }

  // Initialize Controller
  final universityController =
      UniversityController(firebaseService, aiService, knowledgeService);
  universityController.setAILogger(aiLogger);

  final notificationController = NotificationController(firebaseService);

  // 📊 Request stats counters
  final serverStartTime = DateTime.now().toUtc();
  int totalRequests = 0;
  final Map<String, int> requestsByPath = {};
  final Map<int, int> requestsByStatus = {};

  // Router
  final router = Router();
  router.mount('/api/v1', universityController.router.call);
  router.mount('/api/v1/notifications', notificationController.router.call);

  // Health check (both paths)
  router.get('/health', (Request req) => Response.ok('OK'));
  router.get('/api/v1/health', (Request req) => Response.ok(
    '{"status":"ok"}',
    headers: {'content-type': 'application/json'},
  ));

  // 📊 Admin: Cache stats
  router.get('/admin/cache-stats', (Request req) {
    return Response.ok(
      jsonEncode(cacheService.stats()),
      headers: {'Content-Type': 'application/json'},
    );
  });

  // 🔄 Admin: Refresh Knowledge Base
  router.post('/admin/refresh-kb', (Request req) async {
    try {
      await knowledgeService.reinit();
      return Response.ok(
        jsonEncode({'status': 'success', 'message': 'Knowledge base refreshed'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'status': 'error', 'message': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  });

  // 📊 Admin: Request stats
  router.get('/admin/stats', (Request req) {
    final uptime = DateTime.now().toUtc().difference(serverStartTime);
    return Response.ok(
      jsonEncode({
        'server_start': serverStartTime.toIso8601String(),
        'uptime_minutes': uptime.inMinutes,
        'total_requests': totalRequests,
        'requests_by_path': requestsByPath,
        'requests_by_status': requestsByStatus,
        'cache': cacheService.stats(),
      }),
      headers: {'Content-Type': 'application/json'},
    );
  });

  // 💰 Admin: Cost tracking
  router.get('/admin/costs', (Request req) {
    return Response.ok(
      jsonEncode(costTracker.getStats()),
      headers: {'Content-Type': 'application/json'},
    );
  });

  // 🧪 Admin: Prompt configs
  router.get('/admin/prompts', (Request req) {
    return Response.ok(
      jsonEncode(promptConfig.getStats()),
      headers: {'Content-Type': 'application/json'},
    );
  });
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
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
               background: #0f0f1a; color: #e0e0e0; line-height: 1.7; padding: 24px 16px; }
        .container { max-width: 780px; margin: 0 auto; }
        header { text-align: center; margin-bottom: 40px; padding: 32px;
                 background: linear-gradient(135deg, #1a237e, #4527a0); border-radius: 16px; }
        header h1 { font-size: 2rem; color: #fff; margin-bottom: 8px; }
        header p { color: #b0b8ff; font-size: 0.9rem; }
        section { margin-bottom: 32px; }
        h2 { font-size: 1.1rem; color: #90caf9; margin-bottom: 12px;
             padding-bottom: 6px; border-bottom: 1px solid #1e3a5f; }
        p, li { color: #cfd8dc; font-size: 0.95rem; margin-bottom: 8px; }
        ul { padding-left: 20px; }
        strong { color: #e0e0e0; }
        a { color: #82b1ff; }
        footer { text-align: center; color: #546e7a; font-size: 0.8rem; margin-top: 40px; }
        .badge { display: inline-block; background: #4527a0; color: #b0b8ff;
                 border-radius: 20px; padding: 4px 12px; font-size: 0.8rem; margin-top: 8px; }
    </style>
</head>
<body>
<div class="container">
  <header>
    <h1>🎓 TANDAU</h1>
    <p>Политика конфиденциальности / Privacy Policy / Құпиялылық саясаты</p>
    <p style="margin-top:8px; font-size:0.8rem;">Последнее обновление: 10 марта 2026 г.</p>
    <span class="badge">Возрастное ограничение: 16+</span>
  </header>

  <section>
    <h2>1. О приложении</h2>
    <p>TANDAU — мобильное приложение для помощи абитуриентам Казахстана (16–18 лет) в выборе вузов
       на основе их ЕНТ-баллов и шансов на грант.
       Разработчик: tandau.app.help@gmail.com</p>
  </section>

  <section>
    <h2>2. Данные, которые мы собираем</h2>
    <ul>
      <li><strong>Аккаунт:</strong> email, имя — через Firebase Authentication.</li>
      <li><strong>Профиль:</strong> ЕНТ-баллы, предметы, предпочтения вузов.</li>
      <li><strong>Использование:</strong> анонимная аналитика (Firebase Analytics).</li>
      <li><strong>Push-уведомления:</strong> FCM-токен для отправки уведомлений.</li>
      <li><strong>Фото:</strong> только если пользователь загружает аватар (Firebase Storage).</li>
    </ul>
  </section>

  <section>
    <h2>3. Как мы используем данные</h2>
    <ul>
      <li>Расчёт шансов на грант и рекомендация вузов.</li>
      <li>Персонализация контента в приложении.</li>
      <li>Отправка уведомлений о дедлайнах и новостях.</li>
      <li>Работа ИИ-консультанта (TANDAU AI).</li>
      <li>Улучшение работы сервиса через анонимную аналитику.</li>
    </ul>
  </section>

  <section>
    <h2>4. Передача данных третьим лицам</h2>
    <p>Данные не продаются третьим лицам. Данные передаются только:</p>
    <ul>
      <li><strong>Google Firebase</strong> — хранение, Auth, Analytics</li>
      <li><strong>OpenAI</strong> — для обработки запросов к AI-консультанту (только текст запросов).</li>
      <li><strong>RevenueCat</strong> — обработка покупок и подписок.</li>
    </ul>
  </section>

  <section>
    <h2>5. Права пользователя</h2>
    <ul>
      <li>Запросить удаление аккаунта и всех данных.</li>
      <li>Отозвать разрешения (камера, уведомления) в настройках устройства.</li>
      <li>Экспортировать свои данные — по письменному запросу.</li>
    </ul>
    <p>Для удаления данных напишите на: <a href="mailto:tandau.app.help@gmail.com">tandau.app.help@gmail.com</a>.</p>
  </section>

  <section>
    <h2>6. Хранение данных</h2>
    <p>Данные хранятся на серверах Google (Firebase) в соответствии с их стандартами безопасности.
       Данные хранятся до удаления аккаунта пользователем.</p>
  </section>

  <section>
    <h2>7. Возрастные ограничения</h2>
    <p>Приложение TANDAU предназначено для абитуриентов в возрасте <strong>от 16 до 18 лет</strong>,
       готовящихся к поступлению в вузы Казахстана.</p>
    <p>Мы не собираем намеренно данные лиц моложе 16 лет. Если вы являетесь родителем или законным
       представителем и считаете, что ваш ребёнок предоставил нам данные, свяжитесь с нами для их удаления.</p>
  </section>

  <section>
    <h2>8. Контакты</h2>
    <p>По вопросам конфиденциальности: <a href="mailto:tandau.app.help@gmail.com">tandau.app.help@gmail.com</a></p>
  </section>

  <footer>
    <p>© 2026 TANDAU. Все права защищены.</p>
    <p>kz.tandau.app</p>
  </footer>
</div>
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
    return (Handler innerHandler) {
      return (Request request) async {
        final origin = request.headers['origin'] ?? '*';
        final corsHeaders = <String, String>{
          'Access-Control-Allow-Methods': 'GET, POST, OPTIONS, PUT, DELETE',
          'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization, Accept, X-Requested-With',
          'Access-Control-Max-Age': '86400',
          'Access-Control-Allow-Origin': origin,
        };
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

  // 📊 Request counting middleware
  Middleware requestCounterMiddleware() {
    return (Handler innerHandler) {
      return (Request request) async {
        totalRequests++;
        final path = request.requestedUri.path;
        requestsByPath[path] = (requestsByPath[path] ?? 0) + 1;

        final response = await innerHandler(request);
        requestsByStatus[response.statusCode] =
            (requestsByStatus[response.statusCode] ?? 0) + 1;
        return response;
      };
    };
  }

  // Middleware pipeline
  final handler = Pipeline()
      .addMiddleware(corsMiddleware())
      .addMiddleware(rateLimitMiddleware())
      .addMiddleware(requestCounterMiddleware())
      .addMiddleware(logRequests())
      .addHandler(router.call);

  // Start Server
  final server = await io.serve(handler, '0.0.0.0', port);
  stderr.writeln('\n🚀 Antigravity Server listening on port ${server.port}');
  stderr.writeln('   📊 Admin endpoints:');
  stderr.writeln('   │ /admin/cache-stats');
  stderr.writeln('   │ /admin/stats');
  stderr.writeln('   │ /admin/costs');
  stderr.writeln('   └ /admin/prompts');
}
