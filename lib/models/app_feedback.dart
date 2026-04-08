import 'package:cloud_firestore/cloud_firestore.dart';

enum FeedbackType {
  bug,
  suggestion,
  other
}

enum FeedbackStatus {
  new_,
  inProgress,
  resolved,
  rejected
}

/// Модель обратной связи от пользователя
class AppFeedback {
  final String id;
  final String userId;
  final String userName;
  final FeedbackType type;
  final String message;
  final FeedbackStatus status;
  final DateTime createdAt;
  final String? adminReply;

  AppFeedback({
    required this.id,
    required this.userId,
    required this.userName,
    required this.type,
    required this.message,
    this.status = FeedbackStatus.new_,
    required this.createdAt,
    this.adminReply,
  });

  /// Создание из Map (Firestore)
  factory AppFeedback.fromMap(Map<String, dynamic> map, String docId) {
    return AppFeedback(
      id: docId,
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? 'Аноним',
      type: FeedbackType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => FeedbackType.other,
      ),
      message: map['message'] as String? ?? '',
      status: FeedbackStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => FeedbackStatus.new_,
      ),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      adminReply: map['adminReply'] as String?,
    );
  }

  /// Конвертация в Map (Firestore)
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'type': type.name,
      'message': message,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'adminReply': adminReply,
    };
  }

  /// Копия с изменениями
  AppFeedback copyWith({
    String? id,
    String? userId,
    String? userName,
    FeedbackType? type,
    String? message,
    FeedbackStatus? status,
    DateTime? createdAt,
    String? adminReply,
  }) {
    return AppFeedback(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      type: type ?? this.type,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      adminReply: adminReply ?? this.adminReply,
    );
  }
}
