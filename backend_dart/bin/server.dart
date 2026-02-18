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
  final geminiKey =
      env['GEMINI_API_KEY'] ?? 'AIzaSyBFZryqzAj8Uu_bnlsO16od7XKmSLLS-LM';
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

  // Middleware pipeline
  final handler =
      Pipeline().addMiddleware(logRequests()).addHandler(router.call);

  // Start Server
  final server = await io.serve(handler, '0.0.0.0', port);
  stderr.writeln('Antigravity Server listening on port ${server.port}');
}
