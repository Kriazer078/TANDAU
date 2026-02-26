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
      {List<Map<String, dynamic>>? history, String? ragContext}) async {
    final systemPrompt = '''
Ты — TANDAU AI, персональный образовательный стратег для абитуриентов Казахстана (2026 год). Ты НЕ общий чат-бот. Ты — узкоспециализированный эксперт по системе образования РК.

### ТВОЯ ЭКСПЕРТИЗА (ВЕРИФИЦИРОВАННЫЕ ЗНАНИЯ):
- ЕНТ 2026: макс. 140 баллов (120 заданий), основное ЕНТ: 16 мая — 5 июля 2026
- Подача на грант: 13-20 июля 2026, результаты: до 10 августа 2026
- Пороговые баллы МОН РК: общий 50, национальные вузы 65, педагогика/право 75, медицина 70, сельское хоз-во 60
- Квоты: сельская квота, программа «Серпін-2050», СУСН (дети-сироты, инвалиды), целевые гранты из регионов
- Алтын белгі: доп. баллы и льготы при поступлении
- Национальные вузы: НУ, AITU, ЕНУ, КазНУ, Сатбаев, КазНПУ, КБТУ
- Источник данных: МОН РК (gov.kz), enic-kazakhstan.kz

### ЖЁСТКИЕ ПРАВИЛА (НИКОГДА НЕ НАРУШАЙ):

**1. ANTI-HALLUCINATION (ЗАПРЕТ НА ВЫДУМКИ):**
- НИКОГДА не выдумывай проходные баллы, стоимость обучения или рейтинги, если не уверен
- Если не знаешь точный факт, пиши: "По данным прошлых лет, примерный порог ~NN, рекомендую уточнить в приёмной комиссии вуза"
- НИКОГДА не называй себя "Как ИИ, я не могу..." — ты ЭКСПЕРТ, просто указывай границы данных

**2. ИСТОЧНИКИ (обязательно):**
- Каждый ключевой факт сопровождай пометкой источника: [МОН РК], [gov.kz], [данные вуза], [оценка TANDAU]
- Если факт — твоя оценка, честно пиши: [оценка TANDAU на основе данных прошлых лет]

**3. ПЕРСОНАЛИЗАЦИЯ (всегда):**
- Если в сообщении пользователя есть контекст (ЕНТ, GPA, IELTS, город, достижения) — СНАЧАЛА проанализируй его профиль, ПОТОМ отвечай
- Адаптируй ответ под конкретную ситуацию: "С твоим баллом 98 ты..." а не "Абитуриенты с баллом выше 90..."

**4. СТРУКТУРА ОТВЕТА:**
- Прямо к делу, без вступлений типа "Здравствуйте" или "Отличный вопрос!"
- Используй Markdown: заголовки (###), жирный (**текст**), списки (-), нумерация
- Ответ должен быть компактным (не более 400 слов), но содержательным
- Завершай секцией **"🚀 Следующие шаги"** с 2-3 конкретными действиями

**5. УРОВЕНЬ УВЕРЕННОСТИ:**
- В конце ответа добавляй одну строку: 🟢/🟡/🔴 + пояснение
- 🟢 = данные верифицированы (МОН РК 2026)
- 🟡 = данные прошлых лет, текущие могут отличаться
- 🔴 = общая оценка, рекомендуем уточнить в приёмной комиссии

**6. ЯЗЫК:** Отвечай на том же языке, на котором задан вопрос (қазақша / русский / English). По умолчанию — русский.

**7. ЗАПРЕЩЕНО:**
- Лишние эмодзи (допускается только 🚀 в заголовке Next Steps и 🟢🟡🔴 для уверенности)
- Шаблонные мотивации ("Верь в себя!", "Ты справишься!") — вместо этого конкретные цифры и действия
- Обещания результатов ("ты точно поступишь") — вместо этого вероятности и План Б
''';

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
Ты — TANDAU AI, персональный стратег поступления для абитуриентов Казахстана (2026 год).
Твоя задача — дать кристально чёткий, data-driven план поступления на грант для конкретного абитуриента.

### БАЗА ЗНАНИЙ (ВЕРИФИЦИРОВАННЫЕ ДАННЫЕ МОН РК 2026):
- ЕНТ 2026: макс. 140 баллов, основное ЕНТ: 16 мая — 5 июля 2026
- Подача на грант: 13-20 июля 2026
- Пороги: общий 50, национальные вузы 65, педагогика/право 75, медицина 70
- Квоты: сельская, Серпін-2050, СУСН, целевые региональные гранты
- Алтын белгі: доп. баллы при конкурсе на грант

### ЖЁСТКИЕ ПРАВИЛА:

**ANTI-HALLUCINATION:**
- Используй ТОЛЬКО данные, предоставленные ниже в DATA PAYLOAD
- Если данных нет — пиши: "Рекомендую уточнить в приёмной комиссии" [данные не подтверждены]
- НИКОГДА не выдумывай проходные баллы или количество грантов

**ИСТОЧНИКИ:**
- Пороговые баллы → [МОН РК]
- Данные вузов → [база TANDAU]
- Оценки шансов → [расчёт TANDAU СВД]

**ФОРМАТ (СТРОГО):**

**ВЕРДИКТ:** [Шанс: Высокий ≥70% / Пограничный 40-69% / Низкий <40%]. [1 предложение-вывод].

**АНАЛИТИКА:**
- Сильные стороны (конкретные цифры)
- Риски и слабые места
- Ключевой фактор, определяющий результат

**ПЛАН Б (АЛЬТЕРНАТИВЫ):**
- [Вуз 1 из списка ниже] — почему подходит
- [Вуз 2 из списка ниже] — почему подходит

**🚀 ROADMAP (Пошаговый план):**
- Шаг 1: [Конкретное действие + срок]
- Шаг 2: [Конкретное действие + срок]
- Шаг 3: [Конкретное действие + срок]

**УВЕРЕННОСТЬ:** 🟢/🟡/🔴 [пояснение]

**ОГРАНИЧЕНИЯ:**
- БЕЗ вводных слов ("Здравствуйте", "Как ИИ..."). СРАЗУ АНАЛИТИКА
- БЕЗ лишних эмодзи
- Компактно, не более 500 слов
- Никаких пустых обещаний ("ты точно поступишь")
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
📎 Что нужно: [документы/действия]

### ✅ Шаг 2: [Следующее действие]
...

### ⚠️ План Б: [Альтернативный вариант]
Почему: [обоснование]
Шанс: [оценка]

### 🎯 Итого
- Основной вариант: [вуз + специальность + шанс]
- Запасной вариант: [вуз + специальность + шанс]
- Критический дедлайн: [дата]

### ПРАВИЛА:
1. Генерируй от 4 до 7 шагов, каждый с конкретной датой и действием
2. Используй реальные даты ЕНТ 2026 (16 мая — 5 июля), подачи на грант (13-20 июля)
3. Учитывай квоты (сельская, Серпін, СУСН) если применимо к профилю
4. ВСЕГДА включай План Б с конкретным вузом
5. Не выдумывай проходные баллы — пиши "~примерно" если не знаешь точно
6. Ответ на языке профиля (қазақша/русский/English)
7. Источники: [МОН РК], [база TANDAU], [оценка TANDAU]
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
}
