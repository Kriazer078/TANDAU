import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user_model.dart';
import '../models/notification.dart';
import 'auth_service.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  // Backend URL for Push Notifications
  static const String _baseUrl = 'https://tandau-backend.onrender.com/api/v1';

  /// Verify caller is admin. Throws if not.
  void _requireAdmin() {
    if (!_authService.isAdmin) {
      throw Exception('Доступ запрещён: требуются права администратора');
    }
  }

  /// Fetch all users for selection (ADMIN ONLY)
  Future<List<UserModel>> getAllUsers() async {
    try {
      _requireAdmin();
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs
          .map((doc) {
            try {
              return UserModel.fromMap(doc.data());
            } catch (e) {
              debugPrint('Error parsing user ${doc.id}: $e');
              return null; // Skip invalid users
            }
          })
          .whereType<UserModel>()
          .toList();
    } catch (e) {
      debugPrint('Error fetching all users for admin: $e');
      rethrow; // Rethrow to let UI know
    }
  }

  /// Search users by name or email (ADMIN ONLY)
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      _requireAdmin();
      final lowercaseQuery = query.toLowerCase();
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs
          .map((doc) {
            try {
              return UserModel.fromMap(doc.data());
            } catch (e) {
              return null;
            }
          })
          .whereType<UserModel>()
          .where((user) {
            return user.name.toLowerCase().contains(lowercaseQuery) ||
                user.email.toLowerCase().contains(lowercaseQuery);
          })
          .toList();
    } catch (e) {
      debugPrint('Error searching users: $e');
      rethrow;
    }
  }

  /// Send notification to a specific user (ADMIN ONLY)
  Future<bool> sendNotification({
    required String targetUserId,
    required String title,
    required String message,
    NotificationType type = NotificationType.news,
    Map<String, dynamic>? data,
  }) async {
    try {
      _requireAdmin();

      // Sanitize inputs
      final sanitizedTitle = title.trim();
      final sanitizedMessage = message.trim();
      if (sanitizedTitle.isEmpty || sanitizedMessage.isEmpty) {
        throw Exception('Заголовок или сообщение пусты');
      }

      final notificationData = {
        'title': sanitizedTitle,
        'message': sanitizedMessage,
        'time': FieldValue.serverTimestamp(),
        'type': type.name,
        'isRead': false,
        'data': data ?? {},
      };

      // 1. Write to Firestore (In-App Notification)
      await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('notifications')
          .add(notificationData);

      // 2. Trigger Push Notification via Backend
      try {
        await _sendPushToBackend(
          userId: targetUserId,
          title: sanitizedTitle,
          message: sanitizedMessage,
          data: data,
        );
      } catch (e) {
        debugPrint('⚠️ In-app saved, but PUSH failed: $e');
        // We don't return false here because the primary action (saving to DB) succeeded.
      }

      return true;
    } catch (e) {
      debugPrint('Error sending notification: $e');
      rethrow;
    }
  }

  /// Send notification to ALL users (ADMIN ONLY)
  /// Returns the number of users the notification was sent to.
  Future<int> broadcastNotification({
    required String title,
    required String message,
  }) async {
    try {
      _requireAdmin();

      final sanitizedTitle = title.trim();
      final sanitizedMessage = message.trim();
      if (sanitizedTitle.isEmpty || sanitizedMessage.isEmpty) {
        throw Exception('Заголовок или сообщение пусты');
      }

      final users = await getAllUsers();
      if (users.isEmpty) {
        debugPrint('⚠️ No users found to broadcast to.');
        return 0;
      }

      debugPrint('🚀 Broadcasting to ${users.length} users...');

      // 1. Write to Firestore (In-App Notification) - Batch Processing
      const int batchLimit = 500;
      int successCount = 0;

      for (int i = 0; i < users.length; i += batchLimit) {
        final batch = _firestore.batch();
        final chunk = users.skip(i).take(batchLimit);

        for (var user in chunk) {
          final ref = _firestore
              .collection('users')
              .doc(user.uid)
              .collection('notifications')
              .doc();

          batch.set(ref, {
            'title': sanitizedTitle,
            'message': sanitizedMessage,
            'time': FieldValue.serverTimestamp(),
            'type': 'news',
            'isRead': false,
          });
        }

        await batch.commit();
        successCount += chunk.length;
      }

      // 2. Trigger Push Notification via Backend (Broadcast)
      try {
        await _broadcastPushToBackend(
          title: sanitizedTitle,
          message: sanitizedMessage,
        );
      } catch (e) {
        debugPrint('⚠️ In-app saved, but BROADCAST PUSH failed: $e');
      }

      return successCount;
    } catch (e) {
      debugPrint('Error broadcasting notification: $e');
      rethrow;
    }
  }

  // --- Backend Helper Methods ---

  Future<void> _sendPushToBackend({
    required String userId,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    final uri = Uri.parse('$_baseUrl/notifications/send');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'title': title,
        'message': message,
        'data': data ?? {},
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Backend returned ${response.statusCode}: ${response.body}',
      );
    }
  }

  Future<void> _broadcastPushToBackend({
    required String title,
    required String message,
  }) async {
    final uri = Uri.parse('$_baseUrl/notifications/broadcast');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'title': title, 'message': message}),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Backend broadcast returned ${response.statusCode}: ${response.body}',
      );
    }
  }

  /// Fetch statistics for a given date range (ADMIN ONLY)
  Future<List<Map<String, dynamic>>> getStatistics({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      _requireAdmin();

      // Convert to YYYY-MM-DD for string comparison
      final startStr = start.toIso8601String().split('T')[0];
      final endStr = end.toIso8601String().split('T')[0];

      final snapshot = await _firestore
          .collection('statistics')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: startStr)
          .where(FieldPath.documentId, isLessThanOrEqualTo: endStr)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['date'] = doc.id; // Include document ID as date
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error fetching statistics: $e');
      return [];
    }
  }
}
