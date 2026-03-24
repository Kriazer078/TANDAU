import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/university.dart';
import '../models/student_profile.dart';
import 'auth_service.dart';
import 'grant_chance_service.dart';
import 'locale_manager.dart';

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
        specialtyId:
            university.majors.isNotEmpty ? university.majors.first : 'Другое',
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
      final requestBody = <String, dynamic>{
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
    int? mathScore,
    List<String>? preferredCities,
    List<String>? preferredMajors,
    String? currentEducation,
    bool isInternalStrategyCall = false,
  }) async {
    try {
      final bodyData = <String, dynamic>{'question': message};

      // 🔧 BUG C FIX: Send language so backend can localize responses
      final language = LocaleManager().locale.value?.languageCode ?? 'ru';
      bodyData['language'] = language;

      // NOTE: Moderation (profanity) is checked in the UI layer
      // (AIConsultantScreen._sendMessage) before calling this method.

      if (!isInternalStrategyCall) {
        // userContext is now built entirely on the backend securely via `uid`.
      }

      // Send uid for token tracking
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
      throw Exception('Server error: ${response.statusCode}');
    } catch (e) {
      if (e is OutOfTokensException) {
        rethrow;
      }
      throw Exception('Network error: $e');
    }
  }

  /// Отправить сообщение AI консультанту (Stream)
  Stream<String> sendStreamMessage(
    String message, {
    List<Map<String, dynamic>>? history,
    List<String>? userAchievements,
    int? entScore,
    double? ieltsScore,
    double? gpa,
    int? mathScore,
    List<String>? preferredCities,
    List<String>? preferredMajors,
    String? currentEducation,
    String? financialSituation,
    bool? isRural,
    bool? isOrphan,
    bool? hasDisability,
  }) async* {
    final client = http.Client();
    try {
      final bodyData = <String, dynamic>{'question': message};

      // BUG #3 fix: Send language so backend can localize responses
      final language = LocaleManager().locale.value?.languageCode ?? 'ru';
      bodyData['language'] = language;

      // userContext is now built entirely on the backend securely via `uid`.

      final currentUser = AuthService().currentUser.value;
      if (currentUser != null) {
        bodyData['uid'] = currentUser.uid;
      }

      if (history != null && history.isNotEmpty) {
        bodyData['history'] = history;
      }

      // 📋 Extended profile fields for AI context
      if (financialSituation != null) {
        bodyData['financialSituation'] = financialSituation;
      }
      if (isRural == true) bodyData['isRural'] = true;
      if (isOrphan == true) bodyData['isOrphan'] = true;
      if (hasDisability == true) bodyData['hasDisability'] = true;

      final request = http.Request('POST', Uri.parse('$_baseUrl/chat'));
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(bodyData);

      // BUG #4 fix: Increase timeout from 30s to 60s for Render cold start
      final response =
          await client.send(request).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        // Check content type to see if it's JSON (error/out of tokens) or event-stream
        final contentType = response.headers['content-type'] ?? '';
        if (contentType.contains('application/json')) {
          final bodyString = await response.stream.bytesToString();
          final data = jsonDecode(bodyString);
          if (data['outOfTokens'] == true) {
            throw OutOfTokensException(data['answer'] ?? '');
          }
          yield data['answer'] ?? 'Извините, ответ не получен.';
          return;
        }

        // Stream parsing
        await for (final line in response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
          if (line.startsWith('data: ')) {
            final dataStr = line.substring(6);
            if (dataStr.trim() == '[DONE]') break;
            try {
              final json = jsonDecode(dataStr);
              final chunk = json['answer'];
              if (chunk is String && chunk.isNotEmpty) {
                yield chunk;
              }
            } catch (_) {}
          }
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (e is OutOfTokensException) {
        rethrow;
      }
      throw Exception('Network error: $e');
    } finally {
      // BUG #2 fix: Always close the HTTP client to prevent resource leaks
      client.close();
    }
  }

  // --- SYSTEM INSTRUCTIONS ---
  // (Removed unused strategy instructions as we moved logic to backend)

  /// Запросить Жеке Жоспар (персональный план поступления) - Stream
  Stream<String> requestZhekeZhosparStream({
    int? entScore,
    double? gpa,
    double? ieltsScore,
    int? mathScore,
    String? city,
    String? preferredMajors,
    String? currentEducation,
    String? achievements,
    String? financialSituation,
    bool? isRural,
    bool? isOrphan,
    bool? hasDisability,
    List<String>? preferredCities,
  }) async* {
    final client = http.Client();
    try {
      final language = LocaleManager().locale.value?.languageCode ?? 'ru';
      final bodyData = <String, dynamic>{
        'language': language,
      };

      if (entScore != null) bodyData['entScore'] = entScore;
      if (gpa != null) bodyData['gpa'] = gpa;
      if (ieltsScore != null) bodyData['ieltsScore'] = ieltsScore;
      if (mathScore != null) bodyData['mathScore'] = mathScore;
      if (city != null) bodyData['city'] = city;
      if (preferredMajors != null) {
        bodyData['preferredMajors'] = preferredMajors;
      }
      if (currentEducation != null) {
        bodyData['currentEducation'] = currentEducation;
      }
      if (achievements != null) bodyData['achievements'] = achievements;

      // 📋 Extended profile fields
      if (financialSituation != null) {
        bodyData['financialSituation'] = financialSituation;
      }
      if (isRural == true) bodyData['isRural'] = true;
      if (isOrphan == true) bodyData['isOrphan'] = true;
      if (hasDisability == true) bodyData['hasDisability'] = true;
      if (preferredCities != null && preferredCities.isNotEmpty) {
        bodyData['preferredCities'] = preferredCities.join(', ');
      }

      // Send uid for token tracking
      final currentUser = AuthService().currentUser.value;
      if (currentUser != null) {
        bodyData['uid'] = currentUser.uid;
      }

      final request =
          http.Request('POST', Uri.parse('$_baseUrl/zheke-zhospar'));
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(bodyData);

      // BUG #4 fix: Increase timeout from 45s to 60s for Render cold start
      final response =
          await client.send(request).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'] ?? '';
        if (contentType.contains('application/json')) {
          final bodyString = await response.stream.bytesToString();
          final data = jsonDecode(bodyString);
          if (data['outOfTokens'] == true) {
            throw OutOfTokensException(data['answer'] ?? '');
          }
          yield data['answer'] ?? 'Не удалось создать план.';
          return;
        }

        // Stream parsing
        await for (final line in response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
          if (line.startsWith('data: ')) {
            final dataStr = line.substring(6);
            if (dataStr.trim() == '[DONE]') break;
            try {
              final json = jsonDecode(dataStr);
              final chunk = json['answer'];
              if (chunk is String && chunk.isNotEmpty) {
                yield chunk;
              }
            } catch (_) {}
          }
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (e is OutOfTokensException) rethrow;
      throw Exception('Network error: $e');
    } finally {
      // BUG #2 fix: Always close the HTTP client to prevent resource leaks
      client.close();
    }
  }

  /// Запросить Жеке Жоспар (персональный план поступления)
  Future<String> requestZhekeZhospar({
    int? entScore,
    double? gpa,
    double? ieltsScore,
    int? mathScore,
    String? city,
    String? preferredMajors,
    String? currentEducation,
    String? achievements,
  }) async {
    try {
      final language = LocaleManager().locale.value?.languageCode ?? 'ru';
      final bodyData = <String, dynamic>{
        'language': language,
      };

      if (entScore != null) bodyData['entScore'] = entScore;
      if (gpa != null) bodyData['gpa'] = gpa;
      if (ieltsScore != null) bodyData['ieltsScore'] = ieltsScore;
      if (mathScore != null) bodyData['mathScore'] = mathScore;
      if (city != null) bodyData['city'] = city;
      if (preferredMajors != null) {
        bodyData['preferredMajors'] = preferredMajors;
      }
      if (currentEducation != null) {
        bodyData['currentEducation'] = currentEducation;
      }
      if (achievements != null) bodyData['achievements'] = achievements;

      // Send uid for token tracking
      final currentUser = AuthService().currentUser.value;
      if (currentUser != null) {
        bodyData['uid'] = currentUser.uid;
      }

      final response = await http
          .post(
            Uri.parse('$_baseUrl/zheke-zhospar'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(bodyData),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['outOfTokens'] == true) {
          throw OutOfTokensException(data['answer'] ?? '');
        }
        return data['answer'] ?? 'Не удалось создать план.';
      }
      throw Exception('Server error: ${response.statusCode}');
    } catch (e) {
      if (e is OutOfTokensException) rethrow;
      throw Exception('Network error: $e');
    }
  }
}
