import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель лайка университета
class Like {
  final String id;
  final String userId;
  final String universityId;
  final DateTime createdAt;

  Like({
    required this.id,
    required this.userId,
    required this.universityId,
    required this.createdAt,
  });

  /// Создать уникальный ID для лайка (композитный ключ)
  /// Формат: userId_universityId
  static String generateId(String userId, String universityId) {
    return '${userId}_$universityId';
  }

  /// Конвертация в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'universityId': universityId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Создание из Firestore документа
  factory Like.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Like(
      id: doc.id,
      userId: data['userId'] ?? '',
      universityId: data['universityId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Создание из Map
  factory Like.fromMap(Map<String, dynamic> map, String id) {
    return Like(
      id: id,
      userId: map['userId'] ?? '',
      universityId: map['universityId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
