import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

/// Service for recording admin actions into the `admin_logs` collection.
/// Uses fire-and-forget pattern so logging never blocks the main action.
class AuditLogService {
  static final AuditLogService _instance = AuditLogService._internal();
  factory AuditLogService() => _instance;
  AuditLogService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── Action type constants ──
  static const String actionBanUser = 'ban_user';
  static const String actionUnbanUser = 'unban_user';
  static const String actionChangeRole = 'change_role';
  static const String actionDeleteUser = 'delete_user';
  static const String actionDeleteReview = 'delete_review';
  static const String actionSendNotification = 'send_notification';
  static const String actionBroadcastNotification = 'broadcast_notification';
  static const String actionUpdateUniversity = 'update_university';

  /// All known action types for filtering UI
  static const List<String> allActions = [
    actionBanUser,
    actionUnbanUser,
    actionChangeRole,
    actionDeleteUser,
    actionDeleteReview,
    actionSendNotification,
    actionBroadcastNotification,
    actionUpdateUniversity,
  ];

  /// Human-readable labels for action types
  static String actionLabel(String action) {
    switch (action) {
      case actionBanUser:
        return 'Бан пользователя';
      case actionUnbanUser:
        return 'Разбан пользователя';
      case actionChangeRole:
        return 'Смена роли';
      case actionDeleteUser:
        return 'Удаление пользователя';
      case actionDeleteReview:
        return 'Удаление отзыва';
      case actionSendNotification:
        return 'Отправка уведомления';
      case actionBroadcastNotification:
        return 'Рассылка всем';
      case actionUpdateUniversity:
        return 'Обновление ВУЗа';
      default:
        return action;
    }
  }

  /// Log an admin action. Fire-and-forget — never throws, never blocks.
  void log({
    required String action,
    String? targetUid,
    String? targetName,
    String? details,
    Map<String, dynamic>? diffs,
  }) {
    // SECURITY: Only admins and moderators can write logs
    final currentUser = AuthService().currentUser.value;
    if (currentUser == null || !AuthService().hasAdminAccess) {
      debugPrint('⚠️ AuditLog: skipped — no access');
      return;
    }

    final Map<String, dynamic> logData = {
      'adminUid': currentUser.uid,
      'adminEmail': currentUser.email,
      'action': action,
      'targetUid': targetUid,
      'targetName': targetName,
      'details': details,
      'diffs': diffs,
      'timestamp': FieldValue.serverTimestamp(),
      'ipAddress': currentUser.lastIp,
    };

    // Fire-and-forget with timeout
    _firestore
        .collection('admin_logs')
        .add(logData)
        .timeout(const Duration(seconds: 5))
        .then((_) {
          debugPrint('📋 AuditLog: $action → $targetName');
        })
        .catchError((Object e) {
          debugPrint('⚠️ AuditLog write failed: $e');
        });
  }

  /// Fetch paginated audit logs for the viewer screen.
  /// Returns list of log documents and the last document for cursor pagination.
  Future<AuditLogPage> getLogs({
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? actionFilter,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('admin_logs')
          .orderBy('timestamp', descending: true);

      if (actionFilter != null && actionFilter.isNotEmpty) {
        query = query.where('action', isEqualTo: actionFilter);
      }

      query = query.limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get().timeout(const Duration(seconds: 10));

      final List<AuditLogEntry> entries = [];
      for (final doc in snapshot.docs) {
        try {
          entries.add(AuditLogEntry.fromDocument(doc));
        } catch (e) {
          debugPrint('⚠️ Error parsing audit log ${doc.id}: $e');
        }
      }

      return AuditLogPage(
        entries: entries,
        lastDoc: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        hasMore: snapshot.docs.length == limit,
      );
    } catch (e) {
      debugPrint('❌ Error fetching audit logs: $e');
      rethrow;
    }
  }
}

/// Single audit log entry
class AuditLogEntry {
  final String id;
  final String adminUid;
  final String adminEmail;
  final String action;
  final String? targetUid;
  final String? targetName;
  final String? details;
  final Map<String, dynamic>? diffs;
  final DateTime timestamp;
  final String? ipAddress;

  const AuditLogEntry({
    required this.id,
    required this.adminUid,
    required this.adminEmail,
    required this.action,
    this.targetUid,
    this.targetName,
    this.details,
    this.diffs,
    required this.timestamp,
    this.ipAddress,
  });

  factory AuditLogEntry.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AuditLogEntry(
      id: doc.id,
      adminUid: data['adminUid'] as String? ?? '',
      adminEmail: data['adminEmail'] as String? ?? '',
      action: data['action'] as String? ?? 'unknown',
      targetUid: data['targetUid'] as String?,
      targetName: data['targetName'] as String?,
      details: data['details'] as String?,
      diffs: data['diffs'] as Map<String, dynamic>?,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ipAddress: data['ipAddress'] as String?,
    );
  }
}

/// Paginated result for audit logs
class AuditLogPage {
  final List<AuditLogEntry> entries;
  final DocumentSnapshot? lastDoc;
  final bool hasMore;

  const AuditLogPage({
    required this.entries,
    this.lastDoc,
    required this.hasMore,
  });
}
