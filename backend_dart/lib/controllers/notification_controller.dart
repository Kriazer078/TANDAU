import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/firebase_service.dart';

class NotificationController {
  final FirebaseService _firebaseService;

  NotificationController(this._firebaseService);

  Router get router {
    final router = Router();
    router.post('/send', _sendNotification);
    router.post('/broadcast', _broadcastNotification);
    return router;
  }

  Future<Response> _sendNotification(Request request) async {
    try {
      final payload = jsonDecode(await request.readAsString());
      final String? userId = payload['userId'];
      final String? title = payload['title'];
      final String? message = payload['message'];
      final Map<String, dynamic>? data = payload['data'];

      if (userId == null || title == null || message == null) {
        return Response.badRequest(body: 'Missing userId, title, or message');
      }

      final token = await _firebaseService.getUserToken(userId);
      if (token == null) {
        // Return OK but with error message so client doesn't crash, or 404.
        // Let's return 404 to be semantic.
        return Response.notFound(
            jsonEncode({'error': 'User has no FCM token'}));
      }

      // Convert dynamic map to string map for FCM
      final stringData =
          data?.map((key, value) => MapEntry(key, value.toString()));

      final success = await _firebaseService
          .sendNotification(token, title, message, data: stringData);

      if (success) {
        return Response.ok(jsonEncode({'success': true}));
      } else {
        return Response.internalServerError(
            body: jsonEncode({'error': 'Failed to send to FCM'}));
      }
    } catch (e) {
      return Response.internalServerError(body: 'Error: $e');
    }
  }

  Future<Response> _broadcastNotification(Request request) async {
    try {
      final payload = jsonDecode(await request.readAsString());
      final String? title = payload['title'];
      final String? message = payload['message'];
      final Map<String, dynamic>? data = payload['data'];

      if (title == null || message == null) {
        return Response.badRequest(body: 'Missing title or message');
      }

      final tokens = await _firebaseService.getAllUserTokens();
      if (tokens.isEmpty) {
        return Response.ok(jsonEncode(
            {'success': true, 'count': 0, 'message': 'No tokens found'}));
      }

      // Convert dynamic map to string map for FCM
      final stringData =
          data?.map((key, value) => MapEntry(key, value.toString()));

      // Send notifications
      // Note: In a real production app, you'd offload this to a task queue.
      // Here we await it, which might timeout for many users.
      // But for <100 users it's instant.
      await _firebaseService.sendMulticastNotification(tokens, title, message,
          data: stringData);

      return Response.ok(jsonEncode({'success': true, 'count': tokens.length}));
    } catch (e) {
      return Response.internalServerError(body: 'Error: $e');
    }
  }
}
