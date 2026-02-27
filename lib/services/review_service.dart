import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/review.dart';
import 'auth_service.dart';
import 'moderation_service.dart';

/// Сервис для работы с отзывами университетов
///
/// Функции:
/// - Добавление/редактирование отзывов
/// - Автоматический расчет среднего рейтинга
/// - Обновление счетчиков в документе университета
class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final ModerationService _moderationService = ModerationService();

  static const String _reviewsCollection = 'reviews';
  static const String _universitiesCollection = 'universities';

  /// Strip HTML tags and trim whitespace to prevent XSS
  String _sanitizeInput(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(
          RegExp(r'&[a-z]+;', caseSensitive: false),
          '',
        ) // Remove HTML entities
        .trim();
  }

  /// Добавить отзыв
  Future<bool> addReview({
    required String universityId,
    required int rating,
    required String comment,
    List<String>? photoUrls,
  }) async {
    try {
      final user = _authService.currentUser.value;
      if (user == null) {
        debugPrint('❌ User not authenticated');
        return false;
      }

      // Валидация
      if (rating < 1 || rating > 5) {
        debugPrint('❌ Invalid rating: $rating');
        return false;
      }

      final sanitizedComment = _sanitizeInput(comment);
      if (sanitizedComment.isEmpty) {
        debugPrint('❌ Comment is empty');
        return false;
      }

      // Profanity check
      if (_moderationService.hasProfanity(sanitizedComment)) {
        debugPrint('❌ Profanity detected in comment');
        return false;
      }

      debugPrint('📝 Adding review for university: $universityId');

      // Проверяем есть ли уже отзыв от этого пользователя
      final existingReview = await getUserReview(universityId);
      if (existingReview != null) {
        debugPrint('⚠️ User already has a review, updating instead');
        return await updateReview(
          reviewId: existingReview.id,
          rating: rating,
          comment: sanitizedComment,
          photoUrls: photoUrls ?? existingReview.photoUrls,
        );
      }

      // Создаем отзыв
      final review = Review(
        id: '', // Firestore сгенерирует
        userId: user.uid,
        universityId: universityId,
        userName: user.name,
        rating: rating,
        comment: sanitizedComment,
        createdAt: DateTime.now(),
        photoUrls: photoUrls,
      );

      // Добавляем в Firestore
      final docRef = await _firestore
          .collection(_reviewsCollection)
          .add(review.toMap());

      debugPrint('✅ Review added: ${docRef.id}');

      // Обновляем средний рейтинг университета
      await _updateUniversityRating(universityId);

      // Track statistics on backend (fire and forget)
      _trackNewReview();

      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Error adding review: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Обновить отзыв (только автор может редактировать)
  Future<bool> updateReview({
    required String reviewId,
    required int rating,
    required String comment,
    List<String>? photoUrls,
  }) async {
    try {
      // Валидация
      if (rating < 1 || rating > 5) {
        debugPrint('❌ Invalid rating: $rating');
        return false;
      }

      final sanitizedComment = _sanitizeInput(comment);
      if (sanitizedComment.isEmpty) {
        debugPrint('❌ Comment is empty');
        return false;
      }

      // Profanity check
      if (_moderationService.hasProfanity(sanitizedComment)) {
        debugPrint('❌ Profanity detected in comment');
        return false;
      }

      debugPrint('✏️ Updating review: $reviewId');

      // Получаем текущий отзыв
      final reviewDoc = await _firestore
          .collection(_reviewsCollection)
          .doc(reviewId)
          .get();

      if (!reviewDoc.exists) {
        debugPrint('❌ Review not found');
        return false;
      }

      final currentReview = Review.fromDocument(reviewDoc);

      // SECURITY: Verify ownership
      final currentUserId = _authService.currentUser.value?.uid;
      if (currentUserId == null || currentUserId != currentReview.userId) {
        debugPrint('❌ Unauthorized: user does not own this review');
        return false;
      }

      // Обновляем отзыв
      final updateData = <String, dynamic>{
        'rating': rating,
        'comment': sanitizedComment,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (photoUrls != null) {
        updateData['photoUrls'] = photoUrls;
      }

      await _firestore
          .collection(_reviewsCollection)
          .doc(reviewId)
          .update(updateData);

      debugPrint('✅ Review updated');

      // Пересчитываем средний рейтинг если рейтинг изменился
      if (currentReview.rating != rating) {
        await _updateUniversityRating(currentReview.universityId);
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error updating review: $e');
      return false;
    }
  }

  /// Удалить отзыв (только автор или админ)
  Future<bool> deleteReview(String reviewId) async {
    try {
      debugPrint('🗑️ Deleting review: $reviewId');

      // Получаем отзыв перед удалением (нужен universityId)
      final reviewDoc = await _firestore
          .collection(_reviewsCollection)
          .doc(reviewId)
          .get();

      if (!reviewDoc.exists) {
        debugPrint('❌ Review not found');
        return false;
      }

      final review = Review.fromDocument(reviewDoc);

      // SECURITY: Verify ownership or admin
      final currentUserId = _authService.currentUser.value?.uid;
      final isAdmin = _authService.isAdmin;
      if (currentUserId == null ||
          (currentUserId != review.userId && !isAdmin)) {
        debugPrint(
          '❌ Unauthorized: user does not own this review and is not admin',
        );
        return false;
      }

      // Удаляем отзыв
      await _firestore.collection(_reviewsCollection).doc(reviewId).delete();

      debugPrint('✅ Review deleted');

      // Обновляем средний рейтинг
      await _updateUniversityRating(review.universityId);

      return true;
    } catch (e) {
      debugPrint('❌ Error deleting review: $e');
      return false;
    }
  }

  /// 🔥 CORE: Пересчитать и обновить средний рейтинг университета
  ///
  /// Формула: averageRating = SUM(all ratings) / COUNT(reviews)
  Future<void> _updateUniversityRating(String universityId) async {
    try {
      debugPrint('📊 Recalculating rating for university: $universityId');

      // Получаем агрегированные данные (количество и средний рейтинг) без загрузки всех документов
      final query = _firestore
          .collection(_reviewsCollection)
          .where('universityId', isEqualTo: universityId);

      final aggregateQuery = await query
          .aggregate(count(), average('rating'))
          .get();

      final reviewsCount = aggregateQuery.count ?? 0;

      if (reviewsCount == 0) {
        // Нет отзывов - сбрасываем рейтинг
        await _firestore
            .collection(_universitiesCollection)
            .doc(universityId)
            .update({'averageRating': 0.0, 'reviewsCount': 0});
        debugPrint('✅ Rating reset (no reviews)');
        return;
      }

      final averageRating = aggregateQuery.getAverage('rating') ?? 0.0;

      // Обновляем университет
      await _firestore
          .collection(_universitiesCollection)
          .doc(universityId)
          .update({
            'averageRating': double.parse(
              averageRating.toStringAsFixed(1),
            ), // Округляем до 1 знака
            'reviewsCount': reviewsCount,
          });

      debugPrint(
        '✅ Rating updated: $averageRating (from $reviewsCount reviews)',
      );
    } catch (e) {
      debugPrint('❌ Error updating university rating: $e');
    }
  }

  /// Голосование за полезность отзыва (toggle)
  Future<bool> toggleHelpful(String reviewId) async {
    try {
      final userId = _authService.currentUser.value?.uid;
      if (userId == null) return false;

      final reviewRef = _firestore.collection(_reviewsCollection).doc(reviewId);

      return await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(reviewRef);
        if (!snapshot.exists) return false;

        final review = Review.fromDocument(snapshot);
        final isHelpful = review.helpfulBy.contains(userId);

        if (isHelpful) {
          // Удалить лайк полезности
          transaction.update(reviewRef, {
            'helpfulBy': FieldValue.arrayRemove([userId]),
            'helpfulCount': FieldValue.increment(-1),
          });
          return false; // Теперь не полезно
        } else {
          // Добавить лайк полезности
          transaction.update(reviewRef, {
            'helpfulBy': FieldValue.arrayUnion([userId]),
            'helpfulCount': FieldValue.increment(1),
          });
          return true; // Теперь полезно
        }
      });
    } catch (e) {
      debugPrint('Error toggling helpful: $e');
      return false;
    }
  }

  /// Официальный ответ администрации на отзыв
  Future<bool> addReply({
    required String reviewId,
    required String replyText,
  }) async {
    try {
      final user = _authService.currentUser.value;
      if (user == null || !_authService.isAdmin) {
        debugPrint('❌ Not authorized to reply');
        return false;
      }

      final sanitizedReply = _sanitizeInput(replyText);
      if (sanitizedReply.isEmpty) return false;

      final reviewRef = _firestore.collection(_reviewsCollection).doc(reviewId);

      await reviewRef.update({
        'adminReply': sanitizedReply,
        'repliedAt': FieldValue.serverTimestamp(),
        'replierName': user.name.isNotEmpty
            ? user.name
            : 'Администрация TANDAU',
      });

      debugPrint('✅ Reply added to $reviewId');
      return true;
    } catch (e) {
      debugPrint('❌ Error adding reply: $e');
      return false;
    }
  }

  /// Получить отзыв текущего пользователя для университета
  Future<Review?> getUserReview(String universityId) async {
    try {
      final userId = _authService.currentUser.value?.uid;
      if (userId == null) return null;

      final snapshot = await _firestore
          .collection(_reviewsCollection)
          .where('userId', isEqualTo: userId)
          .where('universityId', isEqualTo: universityId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return Review.fromDocument(snapshot.docs.first);
    } catch (e) {
      debugPrint('Error getting user review: $e');
      return null;
    }
  }

  /// Получить все отзывы университета
  Future<List<Review>> getUniversityReviews(String universityId) async {
    try {
      final snapshot = await _firestore
          .collection(_reviewsCollection)
          .where('universityId', isEqualTo: universityId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => Review.fromDocument(doc)).toList();
    } catch (e) {
      debugPrint('Error getting university reviews: $e');
      return [];
    }
  }

  /// Stream отзывов университета (real-time)
  Stream<List<Review>> getUniversityReviewsStream(String universityId) {
    return _firestore
        .collection(_reviewsCollection)
        .where('universityId', isEqualTo: universityId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Review.fromDocument(doc)).toList(),
        );
  }

  /// ADMIN: Stream всех отзывов (для модерации)
  Stream<List<Review>> getAllReviewsStream() {
    return _firestore
        .collection(_reviewsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Review.fromDocument(doc)).toList(),
        );
  }

  /// ADMIN: Инициализировать рейтинги для всех университетов
  Future<void> initializeRatings() async {
    try {
      debugPrint('🔄 Initializing ratings for all universities...');

      final universitiesSnapshot = await _firestore
          .collection(_universitiesCollection)
          .get();

      for (var doc in universitiesSnapshot.docs) {
        await _updateUniversityRating(doc.id);
      }

      debugPrint('✅ All ratings initialized');
    } catch (e) {
      debugPrint('❌ Error initializing ratings: $e');
    }
  }

  /// Track stats on backend
  Future<void> _trackNewReview() async {
    try {
      // Note: Assuming backend is deployed at this URL
      final uri = Uri.parse(
        'https://tandau-backend.onrender.com/v1/stats/review-created',
      );

      // Fire and forget - don't await/block UI
      http
          .post(uri)
          .then((response) {
            if (response.statusCode != 200) {
              debugPrint('⚠️ Failed to track review: ${response.body}');
            } else {
              debugPrint('✅ Review stats tracked');
            }
          })
          .catchError((e) {
            debugPrint('⚠️ Error tracking review: $e');
          });
    } catch (e) {
      debugPrint('⚠️ Error initiating tracking: $e');
    }
  }
}
