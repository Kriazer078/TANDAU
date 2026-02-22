import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/university.dart';

class GeminiService {
  final String _apiKey;

  // List of models available to current key (Prioritizing stable models)
  static const List<String> _endpoints = [
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent',
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent',
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent',
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
    List<String> errors = [];

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
          stderr.writeln('Empty response from $modelName:\n${response.body}');
          errors.add(
              '$modelName returned 200 but text is null. Body: ${response.body}');
        } else {
          stderr.writeln(
              'Model $modelName failed: ${response.statusCode} - ${response.body}');
          errors.add(
              '$modelName failed: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        stderr.writeln('Connection Error: $e');
        errors.add('Connection Error: $e');
      }
    }

    if (lastStatusCode == 429) {
      return '📍 **Лимит запросов исчерпан.**\n\nИзвините, сейчас слишком много людей пользуются AI-консультантом. Пожалуйста, подождите немного (около 30-60 секунд) и попробуйте снова. Мы работаем над расширением лимитов!';
    }

    return 'Извините, сервис временно недоступен.\n\n[ДЛЯ РАЗРАБОТЧИКА]:\n${errors.join('\n\n')}';
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
Ты — TANDAU AI, элитный образовательный стратег уровня tech-startup. Твоя цель — помочь абитуриентам Казахстана поступить в вуз в 2026 году.
Вместо шаблонных ответов, предоставляй конкретные, data-driven стратегии (учитывая рынок IT, квоты СУСН, Серпін и т.д.).

### ПРАВИЛА (СТРОГО):
1. Прямолинейность: Никакой воды, излишней вежливости или длинных вступлений. Сразу к делу.
2. Использование контекста пользователя: Максимально используй предоставленный GPA, ЕНТ, баллы IELTS и город пользователя для выдачи гипер-персонализированных советов.
3. Форматирование: ВСЕГДА используй списки, жирный шрифт и заголовки для читабельности.
4. Действия: Каждое сообщение должно заканчиваться секцией **"🚀 Next Steps"** (Следующие шаги).
5. БЕЗ ЭМОДЗИ: Не используй смайлики в тексте, за исключением иконки ракеты 🚀 в заголовке Next Steps. Строгий IT-стиль.
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
    required String alternativesCtx,
  }) async {
    final scoresText = subjectScores.entries
        .map((e) => "${e.key}: ${e.value} баллов")
        .join('\n');

    final systemInstruction = '''
Ты — TANDAU AI, интеллектуальное ядро образовательного навигатора Казахстана. Проводи глубокий аудит шансов абитуриента на грант, опираясь на актуальную статистику МОН РК.
Выступай как мощный социальный лифт, предлагая 100% рабочие варианты для поступления для любого уровня подготовки.

### CORE ANALYTICS (Логика анализа)
1. Пороговые баллы: Сверяй балл с минимальными требованиями.
2. Динамика грантов: Учитывай конкуренцию по выбранной ГОП.
3. Приоритетность квот: Вспоминай про Сельскую квоту (30%), СУСН, программу Серпін.

### CONSTRAINTS (ЖЕСТКИЕ ОГРАНИЧЕНИЯ)
- СТРОГИЙ ЗАПРЕТ НА ВВОДНЫЕ СЛОВА ("Приветствую", "Уважаемый абитуриент"). НАЧИНАЙ СРАЗУ.
- БЕЗ ЭМОДЗИ (0 EMOJIS). НИКАКИХ СМАЙЛОВ. НИКАКИХ ЗНАЧКОВ.
- ПИШИ МАКСИМАЛЬНО КРАТКО И ПО ДЕЛУ. 
- Используй Markdown для оформления (**жирный текст** для акцентов, `-` для списков).

### REQUIRED FORMAT (ОТВЕЧАЙ СТРОГО ПО ЭТОМУ ШАБЛОНУ)
**ВЕРДИКТ:** [Оценка: Высокая / Средняя / Низкая]. [Одно предложение вывода].

**ДЕТАЛИЗАЦИЯ:**
- [Причина 1 кратко]
- [Причина 2 кратко]

**АЛЬТЕРНАТИВЫ:**
- [Точная альтернатива 1]
- [Точная альтернатива 2]
''';

    final prompt = '''
### CONTEXT: ДАННЫЕ АБИТУРИЕНТА
Желаемый вуз (Dream): $universityName
Специальность: $specialty
Общий балл ЕНТ: $untScore из 140
Профильные предметы: $scoresText

📍 **Реальные вузы для подстраховки:** $alternativesCtx

${untScore < 65 ? '🚨 ВАЖНО: У пользователя невысокий балл. Как социальный лифт, ОБЯЗАТЕЛЬНО предложи программу «Серпін», региональные квоты или вузы из списка выше с низкими пороговыми баллами!' : '💡 ВАЖНО: У пользователя отличный балл. Проанализируй агрессивные стратегии для прохождения в топовые Национальные Вузы.'}
''';

    return _generateAdvanced(
      systemInstruction: systemInstruction,
      contents: [
        {
          'role': 'user',
          'parts': [
            {'text': prompt}
          ]
        }
      ],
    );
  }
}
