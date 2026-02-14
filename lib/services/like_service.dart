import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/like.dart';
import 'auth_service.dart';

/// Сервис для работы с лайками университетов
///
/// Оптимизации:
/// - Отдельная коллекция likes (масштабируемость)
/// - Счетчик likesCount в документе университета (быстрое чтение)
/// - Композитный ID для быстрого поиска
class LikeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  static const String _likesCollection = 'likes';
  static const String _universitiesCollection = 'universities';

  /// Toggle лайка (добавить/удалить)
  ///
  /// Возвращает true если лайк добавлен, false если удален
  Future<bool> toggleLike(String universityId) async {
    try {
      final userId = _authService.currentUser.value?.uid;
      if (userId == null) {
        debugPrint('❌ User not authenticated');
        return false;
      }

      // Генерируем уникальный ID для лайка
      final likeId = Like.generateId(userId, universityId);
      final likeRef = _firestore.collection(_likesCollection).doc(likeId);
      final universityRef = _firestore
          .collection(_universitiesCollection)
          .doc(universityId);

      // Проверяем существует ли лайк
      final likeDoc = await likeRef.get();
      final isLiked = likeDoc.exists;

      // Используем batch для атомарности операции
      final batch = _firestore.batch();

      if (isLiked) {
        // Удаляем лайк
        debugPrint('👎 Removing like: $likeId');
        batch.delete(likeRef);

        // Уменьшаем счетчик
        batch.update(universityRef, {'likesCount': FieldValue.increment(-1)});
      } else {
        // Добавляем лайк
        debugPrint('👍 Adding like: $likeId');
        final like = Like(
          id: likeId,
          userId: userId,
          universityId: universityId,
          createdAt: DateTime.now(),
        );
        batch.set(likeRef, like.toMap());

        // Увеличиваем счетчик
        batch.update(universityRef, {'likesCount': FieldValue.increment(1)});
      }

      // Выполняем все операции атомарно
      await batch.commit();

      debugPrint('✅ Like toggled successfully. New state: ${!isLiked}');
      return true; // Возвращаем true (УСПЕХ ОПЕРАЦИИ), а не состояние!
    } catch (e, stackTrace) {
      debugPrint('❌ Error toggling like: $e');
      debugPrint('Stack trace: $stackTrace');
      return false; // ОШИБКА
    }
  }

  /// Проверить поставил ли пользователь лайк
  Future<bool> isLiked(String universityId) async {
    try {
      final userId = _authService.currentUser.value?.uid;
      if (userId == null) return false;

      final likeId = Like.generateId(userId, universityId);
      final doc = await _firestore
          .collection(_likesCollection)
          .doc(likeId)
          .get();

      return doc.exists;
    } catch (e) {
      debugPrint('Error checking like status: $e');
      return false;
    }
  }

  /// Получить количество лайков университета
  ///
  /// Читаем из счетчика (быстро, 1 чтение)
  Future<int> getLikesCount(String universityId) async {
    try {
      final doc = await _firestore
          .collection(_universitiesCollection)
          .doc(universityId)
          .get();

      return doc.data()?['likesCount'] ?? 0;
    } catch (e) {
      debugPrint('Error getting likes count: $e');
      return 0;
    }
  }

  /// Stream лайков пользователя (для синхронизации UI)
  Stream<bool> getLikeStream(String universityId) {
    final userId = _authService.currentUser.value?.uid;
    if (userId == null) {
      return Stream.value(false);
    }

    final likeId = Like.generateId(userId, universityId);

    return _firestore
        .collection(_likesCollection)
        .doc(likeId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  /// Получить список всех лайкнутых университетов пользователя
  Future<List<String>> getUserLikedUniversities() async {
    try {
      final userId = _authService.currentUser.value?.uid;
      if (userId == null) return [];

      final snapshot = await _firestore
          .collection(_likesCollection)
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => doc.data()['universityId'] as String)
          .toList();
    } catch (e) {
      debugPrint('Error getting user liked universities: $e');
      return [];
    }
  }

  /// ADMIN: Инициализировать счетчики для существующих университетов
  /// (Запустить один раз при первом развертывании)
  Future<void> initializeLikesCounters() async {
    try {
      debugPrint('🔄 Initializing likes counters...');

      final universitiesSnapshot = await _firestore
          .collection(_universitiesCollection)
          .get();

      final batch = _firestore.batch();
      int updated = 0;

      for (var doc in universitiesSnapshot.docs) {
        // Подсчитываем лайки для каждого университета
        final likesSnapshot = await _firestore
            .collection(_likesCollection)
            .where('universityId', isEqualTo: doc.id)
            .get();

        batch.update(doc.reference, {'likesCount': likesSnapshot.docs.length});
        updated++;
      }

      await batch.commit();
      debugPrint('✅ Initialized $updated universities');
    } catch (e) {
      debugPrint('❌ Error initializing counters: $e');
    }
  }
}
