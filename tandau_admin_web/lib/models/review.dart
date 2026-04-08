import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель отзыва о университете
class Review {
  final String id;
  final String userId;
  final String universityId;
  final String userName;
  final int rating; // 1-5 звезд
  final String comment;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Улучшенные отзывы
  final List<String>? photoUrls;
  final int helpfulCount;
  final List<String> helpfulBy;
  final String? adminReply;
  final DateTime? repliedAt;
  final String? replierName;

  Review({
    required this.id,
    required this.userId,
    required this.universityId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.updatedAt,
    this.photoUrls,
    this.helpfulCount = 0,
    this.helpfulBy = const [],
    this.adminReply,
    this.repliedAt,
    this.replierName,
  });

  /// Валидация рейтинга
  bool get isValidRating => rating >= 1 && rating <= 5;

  /// Конвертация в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'universityId': universityId,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'photoUrls': photoUrls,
      'helpfulCount': helpfulCount,
      'helpfulBy': helpfulBy,
      'adminReply': adminReply,
      'repliedAt': repliedAt != null ? Timestamp.fromDate(repliedAt!) : null,
      'replierName': replierName,
    };
  }

  /// Создание из Firestore документа
  factory Review.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Review.fromMap(data, doc.id);
  }

  /// Создание из Map
  factory Review.fromMap(Map<String, dynamic> map, String id) {
    return Review(
      id: id,
      userId: map['userId'] ?? '',
      universityId: map['universityId'] ?? '',
      userName: map['userName'] ?? 'Anonymous',
      rating: map['rating'] ?? 0,
      comment: map['comment'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      photoUrls: (map['photoUrls'] as List<dynamic>?)?.cast<String>(),
      helpfulCount: map['helpfulCount'] ?? 0,
      helpfulBy: (map['helpfulBy'] as List<dynamic>?)?.cast<String>() ?? [],
      adminReply: map['adminReply'],
      repliedAt: map['repliedAt'] != null
          ? (map['repliedAt'] as Timestamp).toDate()
          : null,
      replierName: map['replierName'],
    );
  }

  /// Копирование с изменениями
  Review copyWith({
    String? id,
    String? userId,
    String? universityId,
    String? userName,
    int? rating,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? photoUrls,
    int? helpfulCount,
    List<String>? helpfulBy,
    String? adminReply,
    DateTime? repliedAt,
    String? replierName,
  }) {
    return Review(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      universityId: universityId ?? this.universityId,
      userName: userName ?? this.userName,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      photoUrls: photoUrls ?? this.photoUrls,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      helpfulBy: helpfulBy ?? this.helpfulBy,
      adminReply: adminReply ?? this.adminReply,
      repliedAt: repliedAt ?? this.repliedAt,
      replierName: replierName ?? this.replierName,
    );
  }
}
