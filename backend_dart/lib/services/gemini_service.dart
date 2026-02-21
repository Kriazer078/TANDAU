import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/university.dart';

class GeminiService {
  final String _apiKey;

  // List of models available to current key (Prioritizing stable models)
  static const List<String> _endpoints = [
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent',
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent',
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent',
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent',
  ];

  GeminiService(this._apiKey);

  Future<String> _generateAdvanced({
    String? systemInstruction,
    required List<Map<String, dynamic>> contents,
  }) async {
    if (_apiKey.isEmpty || _apiKey.startsWith('REPLACE')) {
      return 'Ошибка: API ключ не настроен. Пожалуйста, обратитесь в поддержку.';
    }

    stderr.write('Sending advanced prompt to Gemini... ');

    int lastStatusCode = 0;

    for (final endpoint in _endpoints) {
      try {
        final modelName = endpoint.split('/models/').last.split(':').first;

        final Map<String, dynamic> requestBody = {
          'contents': contents,
        };

        if (systemInstruction != null && systemInstruction.isNotEmpty) {
          requestBody['system_instruction'] = {
            'parts': [
              {'text': systemInstruction}
            ]
          };
        }

        final response = await http.post(
          Uri.parse('$endpoint?key=$_apiKey'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        );

        lastStatusCode = response.statusCode;

        if (response.statusCode == 200) {
          final json = jsonDecode(utf8.decode(response.bodyBytes));
          final text =
              json['candidates']?[0]?['content']?['parts']?[0]?['text'];
          if (text != null) {
            stderr.writeln('OK ($modelName)');
            return text;
          }
          stderr.writeln('Empty response from $modelName');
        } else {
          stderr.writeln(
              'Model $modelName failed: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        stderr.writeln('Connection Error: $e');
      }
    }

    if (lastStatusCode == 429) {
      return '📍 **Лимит запросов исчерпан.**\n\nИзвините, сейчас слишком много людей пользуются AI-консультантом. Пожалуйста, подождите немного (около 30-60 секунд) и попробуйте снова. Мы работаем над расширением лимитов!';
    }

    return 'Извините, сервис временно недоступен. Пожалуйста, попробуйте отправить сообщение еще раз через минуту.';
  }

  // Backward compatibility
  Future<String> _generate(String prompt) async {
    return _generateAdvanced(contents: [
      {
        'role': 'user',
        'parts': [
          {'text': prompt}
        ]
      }
    ]);
  }

  Future<String> generateChat(String question,
      {List<Map<String, dynamic>>? history}) async {
    final systemPrompt = '''
You are "TANDAU AI", a helpful university consultant for students in Kazakhstan. 
Role: Answer questions about universities, grants, and admission.
Tone: Friendly, professional, encouraging.
Language: Answer in the same language as the question (Russian, Kazakh, or English).
''';

    final List<Map<String, dynamic>> contents = [];

    // Add history if present
    if (history != null && history.isNotEmpty) {
      contents.addAll(history);
    }

    // Add current question
    contents.add({
      'role': 'user',
      'parts': [
        {'text': question}
      ]
    });

    return _generateAdvanced(
      systemInstruction: systemPrompt,
      contents: contents,
    );
  }

  Future<String> generateRecommendation({
    required List<University> universities,
    required String userPrompt,
    required Map<String, dynamic> userProfile,
  }) async {
    final context = universities
        .map((u) =>
            "- ${u.name} (${u.city}): Min Score ${u.minScore}, Price: ${u.price}, Grants: ${u.hasGrants}, Subjects: ${u.subjects.join(', ')}")
        .join('\n');

    final prompt = '''
Role: University Admission Consultant for Kazakhstan (Tandau App).
Task: Recommend universities based on profile and available data.

User Profile:
- Score: ${userProfile['score']}
- City Preference: ${userProfile['city']}
- Majors: ${userProfile['subjects']}
- Achievements: ${userProfile['achievements']}

User Question: $userPrompt

Available Universities (Filtered):
$context

Instructions:
1. Analyze the user's profile and the available universities.
2. Recommend the best 3-5 matching universities from the list.
3. Explain why each university is a good fit.
4. Give specific advice on admission.
5. Answer in the language of the user's question.
''';
    return _generate(prompt);
  }

  Future<String> generateAIStrategy({
    required String universityName,
    required int untScore,
    required String specialty,
    required Map<String, int> subjectScores,
  }) async {
    final scoresText = subjectScores.entries
        .map((e) => "${e.key}: ${e.value} баллов")
        .join('\n');

    final prompt = '''
Role: Главный ИИ-стратег по поступлению в вузы Казахстана (TANDAU AI).
Task: Разработать глубокую, персонализированную стратегию поступления для абитуриента, учитывая реалии ЕНТ, правила присуждения государственных образовательных грантов РК и специфику вуза.

=== ДАННЫЕ АБИТУРИЕНТА ===
Целевой вуз: $universityName
Выбранное направление/специальность: $specialty
Общий балл ЕНТ: $untScore баллов из 140

Детализация по предметам:
$scoresText

=== ИНСТРУКЦИЯ ДЛЯ ИИ ===
Напиши профессиональный, подробный и мотивирующий ответ-стратегию на РУССКОМ языке.
Используй красивое Markdown-форматирование (жирный текст, маркированные списки, эмодзи).

Твоя стратегия ДОЛЖНА состоять из следующих разделов (строго соблюдай заголовки и структуру):

## 🎯 Анализ текущей ситуации
Оцени реальные шансы с указанным баллом ЕНТ ($untScore) на грант и на платное отделение в этот вуз. Учти, что конкуренция на IT, Медицину, Стоматологию, Международные отношения и Юриспруденцию исторически очень высокая.

## 💡 Стратегический план действий
Дай 3-4 конкретных, неочевидных совета: подача на дополнительные квоты (сельская, многодетная), участие во внутренних олимпиадах, гранты ректора/акимата, правильное распределение 4-х выборов вуза при подаче заявления в НЦТ.

## 🔄 Запасной план "Б" (Альтернативы)
Предложи 2-3 конкретных альтернативных университета в Казахстане, куда с баллом $untScore поступить вероятнее, но качество образования по направлению "$specialty" остается достойным.

## 🚀 Напутствие
Короткое, вдохновляющее завершение для абитуриента от TANDAU AI.

Не используй воду. Давай четкую аналитику, применимую именно в Казахстане в 2025/2026 учебном году.
''';
    return _generate(prompt);
  }
}
