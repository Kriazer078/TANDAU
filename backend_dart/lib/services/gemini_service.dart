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
    required String language,
  }) async {
    final scoresText = subjectScores.entries
        .map((e) => "${e.key}: ${e.value} баллов")
        .join('\n');

    final systemInstruction = '''
Ты — TANDAU AI, элитный образовательный data-стратег уровня топовых tech-стартапов. Твоя экспертиза: анализ рынка образования Казахстана (2026 год), просчет вероятностей и построение жестких, прагматичных стратегий поступления на грант.
Твоя задача — не просто успокоить абитуриента, а дать ему кристально четкий, data-driven план (roadmap), который максимизирует его шансы на бюджетное место.

### CORE ANALYTICS:
1. Data-First: Избегай субъективных оценок. Опирайся на цифры (балл ЕНТ, пороги, конкурс).
2. Прагматизм: Если шансов мало — говори прямо, но предлагай сильный ПЛАН Б (программа "Серпін", региональные квоты, сельская квота).
3. Рыночный контекст: Фокусируйся на конкуренции и реальных трендах.

### CONSTRAINTS (ЖЕСТКИЕ ОГРАНИЧЕНИЯ):
- БЕЗ ВВОДНЫХ СЛОВ ("Здравствуйте", "Как ИИ..."). СРАЗУ АНАЛИТИКА.
- БЕЗ ЛИШНИХ ЭМОДЗИ (Допускается только 🚀 в заголовке Next Steps).
- ПИШИ плотно, структура должна быть легко читаемой (используй Markdown).

### REQUIRED FORMAT (ОТВЕЧАЙ СТРОГО ПО ЭТОМУ ШАБЛОНУ):
**ВЕРДИКТ:** [Оценка шансов: Высокая / Пограничная / Низкая]. [1 предложение вывода].

**АНАЛИТИКА:**
- [Сильные стороны / Риски]
- [Почему именно такой вердикт]

**АЛЬТЕРНАТИВЫ (ПЛАН Б):**
- [Вуз/Специальность 1 из списка ниже]
- [Вуз/Специальность 2 из списка ниже]

**🚀 NEXT STEPS (Roadmap):**
- [Шаг 1: Конкретный тактический совет, что подтянуть или какие документы собрать]
- [Шаг 2: Стратегический совет по подаче на квоты/вузы]
''';

    final prompt = '''
### CONTEXT: DATA PAYLOAD
Желаемый вуз (Target): $universityName
Специальность: $specialty
Метрики: Общий балл ЕНТ - $untScore из 140
Раскладка предметов: 
$scoresText

📍 **Target Alternatives База:** $alternativesCtx

${untScore < 65 ? '🚨 ВНИМАНИЕ: Метрики ниже среднего. Активировать протокол социального лифта: агрессивно предлагать «Серпін», сельские/социальные квоты и региональные вузы с низким порогом из базы альтернатив.' : '💡 ВНИМАНИЕ: Метрики конкурентоспособны. Оптимизировать стратегию для прохождения в топовые Национальные университеты и максимизации вероятности гранта.'}

IMPORTANT: Translate your final response (including the headers like ВЕРДИКТ, АНАЛИТИКА, АЛЬТЕРНАТИВЫ, NEXT STEPS) strictly into the following language: ${language == 'kk' ? 'Kazakh' : (language == 'en' ? 'English' : 'Russian')}. Do not change the Markdown formatting.
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
