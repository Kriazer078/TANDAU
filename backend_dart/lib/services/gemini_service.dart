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

  Future<Stream<String>> _generateStreamAdvanced({
    String? systemInstruction,
    required List<Map<String, dynamic>> contents,
  }) async {
    if (_apiKey.isEmpty || _apiKey.startsWith('REPLACE')) {
      return Stream.value(
          'Ошибка: API ключ не настроен. Пожалуйста, обратитесь в поддержку.');
    }

    stderr.write('Sending advanced stream prompt to Gemini... ');

    for (final endpoint in _endpoints) {
      try {
        final streamEndpoint =
            endpoint.replaceFirst(':generateContent', ':streamGenerateContent');
        final modelName =
            streamEndpoint.split('/models/').last.split(':').first;

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

        final request = http.Request(
            'POST', Uri.parse('$streamEndpoint?key=$_apiKey&alt=sse'));
        request.headers['Content-Type'] = 'application/json';
        request.body = jsonEncode(requestBody);

        final client = http.Client();
        final response = await client.send(request);

        if (response.statusCode == 200) {
          stderr.writeln('Stream OK ($modelName)');
          return response.stream
              .transform(utf8.decoder)
              .transform(const LineSplitter())
              .where((line) => line.startsWith('data: '))
              .map((line) {
                final dataStr = line.substring(6); // Remove "data: "
                if (dataStr.trim() == '[DONE]') return '';
                try {
                  final json = jsonDecode(dataStr);
                  final text =
                      json['candidates']?[0]?['content']?['parts']?[0]?['text'];
                  return text?.toString() ?? '';
                } catch (e) {
                  return '';
                }
              })
              .where((text) => text.isNotEmpty)
              .cast<String>();
        } else {
          final errorBody = await response.stream.bytesToString();
          stderr.writeln(
              'Model $modelName stream failed: ${response.statusCode} - $errorBody');
          client.close();
        }
      } catch (e) {
        stderr.writeln('Stream Connection Error: $e');
      }
    }

    return Stream.value('Извините, сервис временно недоступен.');
  }

  // Backward compatibility

  Future<String> generateChat(
    String question, {
    List<Map<String, dynamic>>? history,
    String? ragContext,
    String? userContext,
  }) async {
    String systemPrompt = '''
Ты — TANDAU AI, персональный образовательный стратег для абитуриентов Казахстана (2026 год). Ты НЕ общий чат-бот. Ты — узкоспециализированный эксперт по системе образования РК.

### ТВОЯ ЭКСПЕРТИЗА (ВЕРИФИЦИРОВАННЫЕ ЗНАНИЯ):
- ЕНТ 2026: макс. 140 баллов (120 заданий), основное ЕНТ: 16 мая — 5 июля 2026
- Подача на грант: 13-20 июля 2026, результаты: до 10 августа 2026
- Пороговые баллы: общий 50, национальные вузы 65, педагогика/право 75, медицина 70, сельское хоз-во 60
- Квоты: сельская квота, программа «Серпін-2050», СУСН, целевые гранты
- Алтын белгі: доп. баллы и льготы при поступлении

### ЖЁСТКИЕ ПРАВИЛА (НИКОГДА НЕ НАРУШАЙ):

**1. КРАТКОСТЬ И ПОЛЬЗА:**
- ОТВЕЧАЙ МАКСИМАЛЬНО КРАТКО И ПО ДЕЛУ (не более 150 слов).
- Прямо к делу, без вступлений типа "Здравствуйте" или "Отличный вопрос!".
- НИКАКИХ лишних упоминаний министерств (МРН, МОН РК, МНВО) в тексте.

**2. ANTI-HALLUCINATION (ЗАПРЕТ НА ВЫДУМКИ):**
- НИКОГДА не выдумывай проходные баллы, стоимость обучения или рейтинги, если не уверен.
- НИКОГДА не называй себя "Как ИИ, я не могу..." — ты ЭКСПЕРТ, просто указывай примерные данные.

**3. ПЕРСОНАЛИЗАЦИЯ:**
- Адаптируй ответ под конкретную ситуацию пользователя (если данных нет — спроси).

**4. ЯЗЫК:** Отвечай на том же языке, на котором задан вопрос (қазақша / русский / English). По умолчанию — русский.
''';

    if (userContext != null && userContext.isNotEmpty) {
      systemPrompt +=
          '\n\n### КОНТЕКСТ ТЕКУЩЕГО ПОЛЬЗОВАТЕЛЯ (УЧИТЫВАЙ ПРИ ОТВЕТЕ):\n$userContext';
    }

    final List<Map<String, dynamic>> contents = [];

    // Add history if present
    if (history != null && history.isNotEmpty) {
      contents.addAll(history);
    }

    // 🧠 RAG: Prepend knowledge base context to the question
    String enrichedQuestion = question;
    if (ragContext != null && ragContext.isNotEmpty) {
      enrichedQuestion =
          '$ragContext\n\n--- ВОПРОС ПОЛЬЗОВАТЕЛЯ ---\n$question';
    }

    // Add current question
    contents.add({
      'role': 'user',
      'parts': [
        {'text': enrichedQuestion}
      ]
    });

    return _generateAdvanced(
      systemInstruction: systemPrompt,
      contents: contents,
    );
  }

  Future<Stream<String>> generateChatStream(
    String question, {
    List<Map<String, dynamic>>? history,
    String? ragContext,
    String? userContext,
  }) async {
    String systemPrompt = '''
Ты — TANDAU AI, персональный образовательный стратег для абитуриентов Казахстана (2026 год). Ты НЕ общий чат-бот. Ты — узкоспециализированный эксперт по системе образования РК.

### ТВОЯ ЭКСПЕРТИЗА (ВЕРИФИЦИРОВАННЫЕ ЗНАНИЯ):
- ЕНТ 2026: макс. 140 баллов (120 заданий), основное ЕНТ: 16 мая — 5 июля 2026
- Подача на грант: 13-20 июля 2026, результаты: до 10 августа 2026
- Пороговые баллы: общий 50, национальные вузы 65, педагогика/право 75, медицина 70, сельское хоз-во 60
- Квоты: сельская квота, программа «Серпін-2050», СУСН, целевые гранты
- Алтын белгі: доп. баллы и льготы при поступлении

### ЖЁСТКИЕ ПРАВИЛА (НИКОГДА НЕ НАРУШАЙ):

**1. КРАТКОСТЬ И ПОЛЬЗА:**
- ОТВЕЧАЙ МАКСИМАЛЬНО КРАТКО И ПО ДЕЛУ (не более 150 слов).
- Прямо к делу, без вступлений типа "Здравствуйте" или "Отличный вопрос!".
- НИКАКИХ лишних упоминаний министерств (МРН, МОН РК, МНВО) в тексте.

**2. ANTI-HALLUCINATION (ЗАПРЕТ НА ВЫДУМКИ):**
- НИКОГДА не выдумывай проходные баллы, стоимость обучения или рейтинги, если не уверен.
- НИКОГДА не называй себя "Как ИИ, я не могу..." — ты ЭКСПЕРТ, просто указывай примерные данные.

**3. ПЕРСОНАЛИЗАЦИЯ:**
- Адаптируй ответ под конкретную ситуацию пользователя (если данных нет — спроси).

**4. ЯЗЫК:** Отвечай на том же языке, на котором задан вопрос (қазақша / русский / English). По умолчанию — русский.
''';

    if (userContext != null && userContext.isNotEmpty) {
      systemPrompt +=
          '\n\n### КОНТЕКСТ ТЕКУЩЕГО ПОЛЬЗОВАТЕЛЯ (УЧИТЫВАЙ ПРИ ОТВЕТЕ):\n$userContext';
    }

    final List<Map<String, dynamic>> contents = [];

    if (history != null && history.isNotEmpty) {
      contents.addAll(history);
    }

    String enrichedQuestion = question;
    if (ragContext != null && ragContext.isNotEmpty) {
      enrichedQuestion =
          '$ragContext\n\n--- ВОПРОС ПОЛЬЗОВАТЕЛЯ ---\n$question';
    }

    contents.add({
      'role': 'user',
      'parts': [
        {'text': enrichedQuestion}
      ]
    });

    return _generateStreamAdvanced(
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

    final systemInstruction = '''
Role: University Admission Consultant for Kazakhstan (Tandau App).
Task: Recommend universities based on profile and available data.

Instructions:
1. Analyze the user's profile and the available universities.
2. Recommend the best 3-5 matching universities from the list.
3. Explain why each university is a good fit.
4. Give specific advice on admission.
5. Answer in the language of the user's question.
''';

    final prompt = '''
User Profile:
- Score: ${userProfile['score']}
- City Preference: ${userProfile['city']}
- Majors: ${userProfile['subjects']}
- Achievements: ${userProfile['achievements']}

User Question: $userPrompt

Available Universities (Filtered):
$context
''';

    final contents = [
      {
        'role': 'user',
        'parts': [
          {'text': prompt}
        ]
      }
    ];

    return _generateAdvanced(
      systemInstruction: systemInstruction,
      contents: contents,
    );
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
Ты — TANDAU AI, персональный стратег поступления для абитуриентов Казахстана (2026 год).
Твоя задача — дать кристально чёткий, data-driven план поступления на грант для конкретного абитуриента.

### БАЗА ЗНАНИЙ (ВЕРИФИЦИРОВАННЫЕ ДАННЫЕ):
- ЕНТ 2026: макс. 140 баллов, основное ЕНТ: 16 мая — 5 июля 2026
- Подача на грант: 13-20 июля 2026
- Пороги: общий 50, национальные вузы 65, педагогика/право 75, медицина 70
- Квоты: сельская, Серпін-2050, СУСН, целевые региональные гранты

### ЖЁСТКИЕ ПРАВИЛА:

**ANTI-HALLUCINATION:**
- Используй ТОЛЬКО данные, предоставленные ниже в DATA PAYLOAD.
- НИКОГДА не выдумывай проходные баллы или количество грантов.

**КРАТКОСТЬ:**
- ОТВЕЧАЙ МАКСИМАЛЬНО КРАТКО. Убери воду.
- Не используй аббревиатуры министерств (МРН, МОН РК, МНВО).

**ФОРМАТ (СТРОГО):**

**ВЕРДИКТ:** [Шанс: Высокий ≥70% / Пограничный 40-69% / Низкий <40%]. [1 предложение-вывод].

**АНАЛИТИКА:**
- Сильные стороны (конкретные цифры)
- Риски и слабые места

**ПЛАН Б:**
- [Вуз 1 из списка ниже]
- [Вуз 2 из списка ниже]

**🚀 ROADMAP:**
- Шаг 1: [Действие] (Дедлайн: [Дата])
- Шаг 2: [Действие] (Дедлайн: [Дата])
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

  /// Generate a personalized "Жеке Жоспар" (step-by-step admission plan)
  Future<String> generateZhekeZhospar({
    required String userProfile,
    String? ragContext,
  }) async {
    final systemPrompt = '''
Ты — TANDAU AI ЖЕКЕ ЖОСПАР генератор. Твоя задача — создать ПЕРСОНАЛЬНЫЙ ПОШАГОВЫЙ ПЛАН ПОСТУПЛЕНИЯ для конкретного абитуриента.

### ФОРМАТ ОТВЕТА (строго!):

# 📋 ЖЕКЕ ЖОСПАР (Персональный план)

**Профиль:** [краткое описание профиля абитуриента]

### ✅ Шаг 1: [Конкретное действие]
📅 Дедлайн: [дата]

### ✅ Шаг 2: [Следующее действие]
...

### ⚠️ План Б: [Альтернативный вариант]
Почему: [обоснование]

### 🎯 Итого
- Основной: [вуз + специальность]
- Запасной: [вуз + специальность]

### ПРАВИЛА:
1. Генерируй от 4 до 6 шагов.
2. Будь максимально краток. Не добавляй воду.
3. Избегай упоминания названий министерств (МРН, МОН РК). Оперируй только фактами.
4. Ответ на языке профиля (қазақша/русский/English).
''';

    String enrichedProfile = userProfile;
    if (ragContext != null && ragContext.isNotEmpty) {
      enrichedProfile =
          '$ragContext\n\n--- ПРОФИЛЬ АБИТУРИЕНТА ---\n$userProfile';
    }

    final contents = [
      {
        'role': 'user',
        'parts': [
          {
            'text':
                'Создай мне Жеке Жоспар на основе моего профиля:\n$enrichedProfile'
          }
        ]
      }
    ];

    return _generateAdvanced(
      systemInstruction: systemPrompt,
      contents: contents,
    );
  }

  /// Generate a personalized "Жеке Жоспар" (stream)
  Future<Stream<String>> generateZhekeZhosparStream({
    required String userProfile,
    String? ragContext,
  }) async {
    final systemPrompt = '''
Ты — TANDAU AI ЖЕКЕ ЖОСПАР генератор. Твоя задача — создать ПЕРСОНАЛЬНЫЙ ПОШАГОВЫЙ ПЛАН ПОСТУПЛЕНИЯ для конкретного абитуриента.

### ФОРМАТ ОТВЕТА (строго!):

# 📋 ЖЕКЕ ЖОСПАР (Персональный план)

**Профиль:** [краткое описание профиля абитуриента]

### ✅ Шаг 1: [Конкретное действие]
📅 Дедлайн: [дата]

### ✅ Шаг 2: [Следующее действие]
...

### ⚠️ План Б: [Альтернативный вариант]
Почему: [обоснование]

### 🎯 Итого
- Основной: [вуз + специальность]
- Запасной: [вуз + специальность]

### ПРАВИЛА:
1. Генерируй от 4 до 6 шагов.
2. Будь максимально краток. Не добавляй воду.
3. Избегай упоминания названий министерств (МРН, МОН РК). Оперируй только фактами.
4. Ответ на языке профиля (қазақша/русский/English).
''';

    String enrichedProfile = userProfile;
    if (ragContext != null && ragContext.isNotEmpty) {
      enrichedProfile =
          '$ragContext\n\n--- ПРОФИЛЬ АБИТУРИЕНТА ---\n$userProfile';
    }

    final contents = [
      {
        'role': 'user',
        'parts': [
          {
            'text':
                'Создай мне Жеке Жоспар на основе моего профиля:\n$enrichedProfile'
          }
        ]
      }
    ];

    return _generateStreamAdvanced(
      systemInstruction: systemPrompt,
      contents: contents,
    );
  }
}
