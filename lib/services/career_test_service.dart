import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../data/holland_test_data.dart';
import '../data/klimov_test_data.dart';
import '../data/ent_specialties_2026.dart';
import '../models/career_test_result.dart';

/// 🧭 Сервис для карьерных тестов (Голланд RIASEC)
///
/// Singleton: CareerTestService()
/// Ответственность:
/// - Подсчёт результатов теста Голланда
/// - Маппинг RIASEC → ГОП (специальности)
/// - Сохранение/загрузка результатов из Firestore
/// - Кеширование последнего результата в users/{uid}
class CareerTestService {
  static final CareerTestService _instance = CareerTestService._internal();
  factory CareerTestService() => _instance;
  CareerTestService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 📊 Последний результат теста (кеш в памяти)
  final ValueNotifier<CareerTestResult?> lastResult =
      ValueNotifier<CareerTestResult?>(null);

  /// 🧮 Рассчитать результат теста Голланда
  ///
  /// [answers] — `Map<int, String>`, где ключ = id вопроса,
  /// значение = тип RIASEC выбранного варианта ('R', 'I', 'A', 'S', 'E', 'C')
  CareerTestResult calculateHollandResult(Map<int, String> answers) {
    // Подсчёт очков по типам
    final Map<String, int> scores = {
      'R': 0, 'I': 0, 'A': 0, 'S': 0, 'E': 0, 'C': 0,
    };

    for (final type in answers.values) {
      scores[type] = (scores[type] ?? 0) + 1;
    }

    // Определить топ-3 типа (трёхбуквенный код)
    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCode = sorted.take(3).map((e) => e.key).join();

    // Маппинг типа → рекомендуемые ГОП
    final List<String> recommendedGops = _getRecommendedGops(sorted);

    final result = CareerTestResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      testType: 'holland',
      scores: scores,
      topCode: topCode,
      recommendedGops: recommendedGops,
      completedAt: DateTime.now(),
    );

    lastResult.value = result;
    return result;
  }

  /// 🧮 Рассчитать результат теста Климова
  ///
  /// [answers] — `Map<int, String>`, где ключ = id вопроса,
  /// значение = тип Климова ('nature', 'tech', 'human', 'signs', 'art')
  CareerTestResult calculateKlimovResult(Map<int, String> answers) {
    // Подсчёт очков по типам
    final Map<String, int> scores = {
      'nature': 0, 'tech': 0, 'human': 0, 'signs': 0, 'art': 0,
    };

    for (final type in answers.values) {
      scores[type] = (scores[type] ?? 0) + 1;
    }

    // Определить топ тип (выбираем с макс кол-вом очков)
    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // В Климове доминирует 1 тип, для совместимости можем взять его как topCode
    final topCode = sorted.first.key; 

    // Маппинг типа → рекомендуемые ГОП
    final Set<String> gops = {};
    for (int i = 0; i < 2 && i < sorted.length; i++) {
        // берем 1 или 2 верхних если баллы не нулевые
        if (sorted[i].value > 0) {
          final type = sorted[i].key;
          final gopList = klimovGopGropus[type] ?? [];
          gops.addAll(gopList);
        }
    }

    final result = CareerTestResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      testType: 'klimov',
      scores: scores,
      topCode: topCode,
      recommendedGops: gops.toList(),
      completedAt: DateTime.now(),
    );

    lastResult.value = result;
    return result;
  }

  /// 🔗 Получить рекомендуемые ГОП на основе RIASEC-рейтинга
  ///
  /// Берём ГОП из топ-2 типов, убираем дубли
  List<String> _getRecommendedGops(
    List<MapEntry<String, int>> sortedTypes,
  ) {
    final Set<String> gops = {};

    // Топ-2 типа → приоритетные ГОП
    for (int i = 0; i < 2 && i < sortedTypes.length; i++) {
      final type = sortedTypes[i].key;
      final gopList = riasecToGopMapping[type] ?? [];
      gops.addAll(gopList);
    }

    // Третий тип — дополнительные ГОП (если есть уникальные)
    if (sortedTypes.length > 2) {
      final type = sortedTypes[2].key;
      final gopList = riasecToGopMapping[type] ?? [];
      gops.addAll(gopList);
    }

    return gops.toList();
  }

  /// 📋 Получить EntSpecialty объекты по кодам ГОП
  List<EntSpecialty> getSpecialtiesByGopCodes(List<String> gopCodes) {
    final Set<String> uniqueCodes = gopCodes.toSet();
    final Set<String> seenCodes = {};
    final List<EntSpecialty> result = [];

    for (final specialty in entSpecialties2026) {
      if (uniqueCodes.contains(specialty.code) &&
          !seenCodes.contains(specialty.code)) {
        result.add(specialty);
        seenCodes.add(specialty.code);
      }
    }

    return result;
  }

  /// 💾 Сохранить результат в Firestore
  ///
  /// 1. Subcollection: users/{uid}/careerTests/{testId}
  /// 2. Кеш в users/{uid}: hollandCode, klimovType
  Future<String?> saveResult(CareerTestResult result) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'Пользователь не авторизован';

      // 1. Сохранить полный результат в subcollection
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('careerTests')
          .doc(result.id)
          .set(result.toMap());

      // 2. Кеш: обновить hollandCode / klimovType в основном документе
      final Map<String, dynamic> cacheUpdate = {
        'updatedAt': Timestamp.now(),
      };

      if (result.testType == 'holland') {
        cacheUpdate['hollandCode'] = result.topCode;
      } else if (result.testType == 'klimov') {
        cacheUpdate['klimovType'] = result.topCode;
      }
      cacheUpdate['lastCareerTestAt'] = Timestamp.fromDate(result.completedAt);

      await _firestore.collection('users').doc(user.uid).update(cacheUpdate);

      return null; // null = успех
    } catch (e, stack) {
      debugPrint('❌ CareerTestService.saveResult: $e');
      debugPrint('$stack');
      return 'Ошибка сохранения: $e';
    }
  }

  /// 📖 Загрузить последний результат теста из Firestore
  Future<CareerTestResult?> loadLastResult({String? testType}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      var query = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('careerTests')
          .orderBy('completedAt', descending: true)
          .limit(1);

      if (testType != null) {
        query = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('careerTests')
            .where('testType', isEqualTo: testType)
            .orderBy('completedAt', descending: true)
            .limit(1);
      }

      final snapshot = await query.get().timeout(
        const Duration(seconds: 10),
      );

      if (snapshot.docs.isEmpty) return null;

      final result = CareerTestResult.fromMap(snapshot.docs.first.data());
      lastResult.value = result;
      return result;
    } catch (e, stack) {
      debugPrint('❌ CareerTestService.loadLastResult: $e');
      debugPrint('$stack');
      return null;
    }
  }

  /// ✅ Проверить, проходил ли пользователь тест
  Future<bool> hasCompletedTest({String testType = 'holland'}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('careerTests')
          .where('testType', isEqualTo: testType)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 10));

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('❌ CareerTestService.hasCompletedTest: $e');
      return false;
    }
  }
}
