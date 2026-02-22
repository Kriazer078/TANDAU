import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/university.dart';
import '../models/student_profile.dart';
import 'auth_service.dart';
import 'grant_chance_service.dart';
import 'locale_manager.dart';

import 'moderation_service.dart';

class OutOfTokensException implements Exception {
  final String message;
  const OutOfTokensException([this.message = '']);
}

/// AI-консультант для помощи студентам в выборе университета
class AIConsultantService {
  static final AIConsultantService _instance = AIConsultantService._internal();
  factory AIConsultantService() => _instance;
  AIConsultantService._internal();

  // PRODUCTION URL:
  static const String _baseUrl = 'https://tandau-backend.onrender.com/api/v1';

  final ModerationService _moderationService = ModerationService();

  /// Инициализация (Warm-up backend)
  void init() {
    // Fire and forget request to wake up Render instance
    _wakeUpBackend();
  }

  Future<void> _wakeUpBackend() async {
    try {
      // Отправляем легкий запрос, чтобы "разбудить" сервер (Render Cold Start)
      // Нам не важен ответ (404 или 200), главное — инициировать процесс
      await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Игнорируем ошибки при прогреве
    }
  }

  /// Получить подробную стратегию поступления (TANDAU AI Agent)
  /// Использует СВД (GrantChanceService) для расчёта шансов.
  Future<String> getAdmissionStrategy({
    required StudentProfile profile,
    required University university,
    bool isPro = false,
  }) async {
    try {
      // 1. Используем специализированный endpoint бэкенда для стратегии
      final Map<String, dynamic> result = await getAIStrategy(
        universityId: university.id,
        untScore: profile.entScore ?? 0,
        specialtyId: university.majors.isNotEmpty
            ? university.majors.first
            : 'Другое',
      );

      return result['description'] ??
          'Извините, стратегия не была сформирована.';
    } catch (e) {
      if (e is OutOfTokensException) {
        rethrow;
      }
      return '📍 **Ошибка генерации стратегии.**\n\nНе удалось получить расчет от AI. Пожалуйста, попробуйте еще раз через минуту.';
    }
  }

  /// Рассчитать шансы на грант (мгновенно, без сети)
  GrantChanceResult calculateGrantChance({
    required StudentProfile profile,
    required University university,
  }) {
    final MajorCategory category = university.majors.isNotEmpty
        ? GrantChanceService().detectCategory(university.majors.first)
        : MajorCategory.other;

    final user = AuthService().currentUser.value;

    return GrantChanceService().calculate(
      entScore: profile.entScore,
      universityId: university.id,
      majorCategory: category,
      gpa: profile.gpa,
      ieltsScore: profile.ieltsScore,
      achievements: profile.achievements,
      mathScore: profile.mathScore,
      userCity: user?.city,
      universityCity: university.city,
    );
  }

  /// Получить детальный план стратегии от AI
  Future<Map<String, dynamic>> getAIStrategy({
    required String universityId,
    required int untScore,
    required String specialtyId,
    Map<String, int>? subjectScores,
  }) async {
    try {
      final currentUser = AuthService().currentUser.value;
      final language = LocaleManager().locale.value?.languageCode ?? 'ru';
      final requestBody = {
        'user_unt_score': untScore,
        'specialty_id': specialtyId,
        'university_id': universityId,
        'user_subjects_scores': subjectScores ?? {},
        'language': language,
      };

      if (currentUser != null) {
        requestBody['uid'] = currentUser.uid;
      }

      final response = await http
          .post(
            Uri.parse('$_baseUrl/ai/getAIStrategy'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['outOfTokens'] == true) {
          throw OutOfTokensException(data['description'] ?? '');
        }
        return data;
      } else {
        throw Exception('Failed to load AI strategy: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting AI strategy: $e');
      rethrow;
    }
  }

  /// Отправить сообщение AI консультанту (Chat)
  Future<String> sendMessage(
    String message, {
    List<Map<String, dynamic>>? history,
    List<String>? userAchievements,
    int? entScore,
    double? ieltsScore,
    double? gpa,
    List<String>? preferredCities,
    List<String>? preferredMajors,
    String? currentEducation,
    bool isInternalStrategyCall = false,
  }) async {
    try {
      String fullMessage;

      if (isInternalStrategyCall) {
        // For internal strategy calls, the message already contains the prompt and JSON
        fullMessage = message;
      } else {
        // Building context for general chat
        String context = '';
        if (userAchievements != null && userAchievements.isNotEmpty) {
          context += 'Достижения: ${userAchievements.join(", ")}. ';
        }
        if (entScore != null && entScore > 0) {
          context += 'ЕНТ: $entScore. ';
        }
        if (ieltsScore != null && ieltsScore > 0) {
          context += 'IELTS: $ieltsScore. ';
        }

        // --- MODERATION CHECK (LOCAL) ---
        if (_moderationService.hasProfanity(message)) {
          return 'Мы за вежливое общение. Пожалуйста, переформулируйте ваш вопрос без использования грубых выражений.';
        }
        // --------------------------------
        if (gpa != null && gpa > 0) {
          context += 'GPA: $gpa. ';
        }
        if (preferredCities != null && preferredCities.isNotEmpty) {
          context += 'Города: ${preferredCities.join(", ")}. ';
        }
        if (currentEducation != null && currentEducation.isNotEmpty) {
          context += 'Текущее образование: $currentEducation. ';
        }

        // Important: we append the context to the message so Gemini knows current user state
        fullMessage =
            '${context.isNotEmpty ? 'Мой контекст: $context\n\n' : ''}Мой вопрос: $message';
      }

      final bodyData = <String, dynamic>{'question': fullMessage};

      final currentUser = AuthService().currentUser.value;
      if (currentUser != null) {
        bodyData['uid'] = currentUser.uid;
      }

      if (history != null && history.isNotEmpty) {
        bodyData['history'] = history;
      }

      final response = await http
          .post(
            Uri.parse('$_baseUrl/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(bodyData),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['outOfTokens'] == true) {
          throw OutOfTokensException(data['answer'] ?? '');
        }
        return data['answer'] ?? 'Извините, ответ не получен.';
      }
      return '📍 **Проблема с подключением.**\n\nСервер TANDAU сейчас перегружен или недоступен (Код: ${response.statusCode}). Пожалуйста, попробуйте позже.';
    } catch (e) {
      if (e is OutOfTokensException) {
        rethrow;
      }
      return '📍 **Ошибка сети.**\n\nПроверьте ваше интернет-соединение и попробуйте снова.';
    }
  }

  // --- SYSTEM INSTRUCTIONS ---
  // (Removed unused strategy instructions as we moved logic to backend)
}
