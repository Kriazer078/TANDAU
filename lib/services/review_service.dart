import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review.dart';
import 'auth_service.dart';

/// Сервис для работы с отзывами университетов
///
/// Функции:
/// - Добавление/редактирование отзывов
/// - Автоматический расчет среднего рейтинга
/// - Обновление счетчиков в документе университета
class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  static const String _reviewsCollection = 'reviews';
  static const String _universitiesCollection = 'universities';

  /// Добавить отзыв
  Future<bool> addReview({
    required String universityId,
    required int rating,
    required String comment,
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

      if (comment.trim().isEmpty) {
        debugPrint('❌ Comment is empty');
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
          comment: comment,
        );
      }

      // Создаем отзыв
      final review = Review(
        id: '', // Firestore сгенерирует
        userId: user.uid,
        universityId: universityId,
        userName: user.name,
        rating: rating,
        comment: comment.trim(),
        createdAt: DateTime.now(),
      );

      // Добавляем в Firestore
      final docRef = await _firestore
          .collection(_reviewsCollection)
          .add(review.toMap());

      debugPrint('✅ Review added: ${docRef.id}');

      // Обновляем средний рейтинг университета
      await _updateUniversityRating(universityId);

      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Error adding review: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Обновить отзыв
  Future<bool> updateReview({
    required String reviewId,
    required int rating,
    required String comment,
  }) async {
    try {
      // Валидация
      if (rating < 1 || rating > 5) {
        debugPrint('❌ Invalid rating: $rating');
        return false;
      }

      if (comment.trim().isEmpty) {
        debugPrint('❌ Comment is empty');
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

      // Обновляем отзыв
      await _firestore.collection(_reviewsCollection).doc(reviewId).update({
        'rating': rating,
        'comment': comment.trim(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

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

  /// Удалить отзыв
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

      // Получаем все отзывы университета
      final reviewsSnapshot = await _firestore
          .collection(_reviewsCollection)
          .where('universityId', isEqualTo: universityId)
          .get();

      final reviews = reviewsSnapshot.docs
          .map((doc) => Review.fromDocument(doc))
          .toList();

      if (reviews.isEmpty) {
        // Нет отзывов - сбрасываем рейтинг
        await _firestore
            .collection(_universitiesCollection)
            .doc(universityId)
            .update({'averageRating': 0.0, 'reviewsCount': 0});
        debugPrint('✅ Rating reset (no reviews)');
        return;
      }

      // Рассчитываем средний рейтинг
      final totalRating = reviews.fold<int>(
        0,
        (accumulator, review) => accumulator + review.rating,
      );
      final averageRating = totalRating / reviews.length;

      // Обновляем университет
      await _firestore
          .collection(_universitiesCollection)
          .doc(universityId)
          .update({
            'averageRating': double.parse(
              averageRating.toStringAsFixed(1),
            ), // Округляем до 1 знака
            'reviewsCount': reviews.length,
          });

      debugPrint(
        '✅ Rating updated: $averageRating (from ${reviews.length} reviews)',
      );
    } catch (e) {
      debugPrint('❌ Error updating university rating: $e');
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
}
