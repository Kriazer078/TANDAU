import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/university.dart';

/// AI-консультант для помощи студентам в выборе университета
class AIConsultantService {
  static final AIConsultantService _instance = AIConsultantService._internal();
  factory AIConsultantService() => _instance;
  AIConsultantService._internal();

  // URL for Antigravity Backend
  // Use 10.0.2.2 for Android Emulator, localhost for iOS simulator, or IP for physical device
  // URL for Antigravity Backend
  // Use 10.0.2.2 for Android Emulator, localhost for iOS simulator, or IP for physical device
  // PRODUCTION URL:
  static const String _baseUrl = 'https://tandau-backend.onrender.com/api/v1';

  /// Инициализация (перемещена на backend)
  void init() {
    // No-op for client side logic
  }

  /// Отправить сообщение AI консультанту (Chat)
  Future<String> sendMessage(
    String message, {
    List<String>? userAchievements,
    int? entScore,
    List<String>? preferredCities,
    List<String>? preferredMajors,
  }) async {
    try {
      // Build context string if needed, or send structured data if backend supports it.
      // For /chat endpoint, we send a single question string with context included.

      String context = '';
      if (userAchievements != null) {
        context += 'Achievements: ${userAchievements.join(", ")}. ';
      }
      if (entScore != null) {
        context += 'ENT Score: $entScore. ';
      }
      if (preferredCities != null) {
        context += 'Preferred Cities: ${preferredCities.join(", ")}. ';
      }
      if (preferredMajors != null) {
        context += 'Majors: ${preferredMajors.join(", ")}. ';
      }

      final fullMessage = context.isNotEmpty
          ? 'Context: $context\n\nQuestion: $message'
          : message;

      final response = await http.post(
        Uri.parse('$_baseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'question': fullMessage}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['answer'] ?? 'No answer received.';
      } else {
        return 'Server error: ${response.statusCode}';
      }
    } catch (e) {
      return 'Connection error: $e. Check server status.';
    }
  }

  /// Получить рекомендации по университетам
  Future<String> getUniversityRecommendations({
    required List<String> achievements,
    required int entScore,
    List<String>? preferredCities,
    List<String>? preferredMajors,
    int? budget,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/recommend'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userProfile': {
            'score': entScore,
            'city': preferredCities?.firstOrNull ?? '',
            'subjects': preferredMajors ?? [],
            'achievements': achievements,
            'budget': budget,
          },
          'question': 'Please recommend universities based on my profile.',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['answer'] ?? 'No recommendation received.';
      } else {
        return 'Server error: ${response.statusCode}';
      }
    } catch (e) {
      return 'Connection error: $e. Check server status.';
    }
  }

  /// Оценить шансы на грант в конкретном университете
  Future<String> evaluateGrantChances({
    required University university,
    required List<String> achievements,
    required int entScore,
  }) async {
    // We can reuse the /chat endpoint by constructing a specific prompt
    final prompt =
        '''
Evaluate grant chances for:
University: ${university.name} (${university.city})
Passing Score: ${university.passingScore}
Student Score: $entScore
Achievements: ${achievements.join(', ')}

Please estimate chances and give advice.
''';
    return sendMessage(prompt);
  }

  /// Получить совет по подготовке к поступлению
  Future<String> getAdmissionAdvice(String question) async {
    return sendMessage(question);
  }
}
