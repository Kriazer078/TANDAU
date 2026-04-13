import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/university.dart';
import 'system_prompts.dart';
import 'cost_tracker_service.dart';

class GeminiService {
  final String _apiKey;
  CostTrackerService? _costTracker;

  /// Set cost tracker (optional, set from server.dart)
  void setCostTracker(CostTrackerService tracker) {
    _costTracker = tracker;
  }

  // ✅ 2026 Verified stable Gemini models, ordered by priority (best first)
  static const List<String> _endpoints = [
    'https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent',
    'https://generativelanguage.googleapis.com/v1/models/gemini-2.5-pro:generateContent',
    'https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent',
    'https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash-lite:generateContent',
  ];



  /// Keywords that require fresh data via Google Search Grounding.
  static const List<String> _groundingTriggers = [
    'стоим', 'цена', 'грант', 'quota', 'квот', 'порог', 'проходной',
    'новост', 'сейчас', 'актуальн', 'конкурс', 'current', 'latest',
    'рейтинг', 'ranking', 'бюджет', 'дедлайн', 'deadline',
  ];

  /// Returns true if the question likely needs live Google Search data.
  static bool _needsGrounding(String question) {
    final q = question.toLowerCase();
    return _groundingTriggers.any((kw) => q.contains(kw));
  }

  // ═══════════════════════════════════════════════════════════════
  // PROMPT HELPERS — delegates to SystemPrompts class
  // ═══════════════════════════════════════════════════════════════

  /// Builds contents list from history, RAG context, and question
  static List<Map<String, dynamic>> buildContents({
    required String question,
    List<Map<String, dynamic>>? history,
    String? ragContext,
  }) {
    final List<Map<String, dynamic>> contents = [];

    if (history != null && history.isNotEmpty) {
      contents.addAll(history);
    }

    String enrichedQuestion = '<user_input>\n$question\n</user_input>';
    if (ragContext != null && ragContext.isNotEmpty) {
      enrichedQuestion =
          '$ragContext\n\n--- ВОПРОС ПОЛЬЗОВАТЕЛЯ ---\n$enrichedQuestion';
    }

    contents.add({
      'role': 'user',
      'parts': [
        {'text': enrichedQuestion}
      ]
    });

    return contents;
  }

  GeminiService(this._apiKey);

  Future<String> _generateAdvanced({
    String? systemInstruction,
    required List<Map<String, dynamic>> contents,
    bool useGrounding = false,
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

        // 🔍 Google Search Grounding
        if (useGrounding) {
          requestBody['tools'] = [
            {'googleSearch': {}}
          ];
        }

        final response = await http.post(
          Uri.parse('$endpoint?key=$_apiKey'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        ).timeout(const Duration(seconds: 35));

        lastStatusCode = response.statusCode;

        if (response.statusCode == 200) {
          final json = jsonDecode(utf8.decode(response.bodyBytes));
          final text =
              json['candidates']?[0]?['content']?['parts']?[0]?['text'];
          if (text != null) {
            stderr.writeln('OK ($modelName)');
            // 💰 Track token usage
            _trackTokenUsage(json, modelName);
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
          
          // 🛡️ Circuit Breaker: Continue to fallback model on rate limits
          if (response.statusCode == 429) {
            continue; 
          }
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
    bool useGrounding = false,
  }) async {
    if (_apiKey.isEmpty || _apiKey.startsWith('REPLACE')) {
      return Stream.value(
          'Ошибка: API ключ не настроен. Пожалуйста, обратитесь в поддержку.');
    }

    stderr.write('Sending advanced stream prompt to Gemini... ');

    int lastStatusCode = 0;
    List<String> errors = [];

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

        // 🔍 Google Search Grounding
        if (useGrounding) {
          requestBody['tools'] = [
            {'googleSearch': {}}
          ];
        }

        final request = http.Request(
            'POST', Uri.parse('$streamEndpoint?key=$_apiKey&alt=sse'));
        request.headers['Content-Type'] = 'application/json';
        request.body = jsonEncode(requestBody);

        final client = http.Client();
        final response = await client.send(request).timeout(const Duration(seconds: 35));

        lastStatusCode = response.statusCode;

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
          errors.add('$modelName failed: ${response.statusCode} - $errorBody');
          client.close();
          
          // 🛡️ Circuit Breaker: Continue to fallback model on rate limits
          if (response.statusCode == 429) {
            continue; 
          }
        }
      } catch (e) {
        stderr.writeln('Stream Connection Error: $e');
        errors.add('Connection Error: $e');
      }
    }

    if (lastStatusCode == 429) {
      return Stream.value('📍 **Лимит запросов исчерпан.**\n\nИзвините, сейчас слишком много людей пользуются AI-консультантом. Пожалуйста, подождите немного (около 30-60 секунд) и попробуйте снова. Мы работаем над расширением лимитов!');
    }

    return Stream.value('Извините, сервис временно недоступен.\n\n[ДЛЯ РАЗРАБОТЧИКА]:\n${errors.join('\n\n')}');
  }

  // Backward compatibility

  Future<String> generateChat(
    String question, {
    List<Map<String, dynamic>>? history,
    String? ragContext,
    String? userContext,
    String? intentInstruction,
  }) async {
    // 🔍 Only use grounding when question needs live data
    final shouldGround = _needsGrounding(question);
    return _generateAdvanced(
      systemInstruction: SystemPrompts.buildChatPrompt(
        userContext: userContext,
        intentInstruction: intentInstruction,
      ),
      contents: buildContents(
        question: question,
        history: history,
        ragContext: ragContext,
      ),
      useGrounding: shouldGround,
    );
  }

  Future<Stream<String>> generateChatStream(
    String question, {
    List<Map<String, dynamic>>? history,
    String? ragContext,
    String? userContext,
    String? intentInstruction,
  }) async {
    // 🔍 Only use grounding when question needs live data
    final shouldGround = _needsGrounding(question);
    return _generateStreamAdvanced(
      systemInstruction: SystemPrompts.buildChatPrompt(
        userContext: userContext,
        intentInstruction: intentInstruction,
      ),
      contents: buildContents(
        question: question,
        history: history,
        ragContext: ragContext,
      ),
      useGrounding: shouldGround,
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
      useGrounding: true,
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

    final prompt = SystemPrompts.buildStrategyPrompt(
      universityName: universityName,
      untScore: untScore,
      specialty: specialty,
      scoresText: scoresText,
      alternativesCtx: alternativesCtx,
      language: language,
    );

    return _generateAdvanced(
      systemInstruction: SystemPrompts.strategy,
      contents: [
        {
          'role': 'user',
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      useGrounding: true,
    );
  }

  /// Build Zheke Zhospar contents with RAG context
  static List<Map<String, dynamic>> _buildZhekeContents({
    required String userProfile,
    String? ragContext,
  }) {
    String enrichedProfile = userProfile;
    if (ragContext != null && ragContext.isNotEmpty) {
      enrichedProfile =
          '$ragContext\n\n--- ПРОФИЛЬ АБИТУРИЕНТА ---\n$userProfile';
    }
    return [
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
  }

  /// Generate a personalized "Жеке Жоспар" (non-stream)
  Future<String> generateZhekeZhospar({
    required String userProfile,
    String? ragContext,
  }) async {
    return _generateAdvanced(
      systemInstruction: SystemPrompts.zhekeZhospar,
      contents: _buildZhekeContents(
        userProfile: userProfile,
        ragContext: ragContext,
      ),
      useGrounding: true,
    );
  }

  /// Generate a personalized "Жеке Жоспар" (stream)
  Future<Stream<String>> generateZhekeZhosparStream({
    required String userProfile,
    String? ragContext,
  }) async {
    return _generateStreamAdvanced(
      systemInstruction: SystemPrompts.zhekeZhospar,
      contents: _buildZhekeContents(
        userProfile: userProfile,
        ragContext: ragContext,
      ),
      useGrounding: true,
    );
  }
  // ═══════════════════════════════════════════════════════════════
  // COST TRACKING — parse usageMetadata from Gemini responses
  // ═══════════════════════════════════════════════════════════════

  /// Parse and track token usage from Gemini API response.
  void _trackTokenUsage(Map<String, dynamic> json, String model) {
    if (_costTracker == null) return;
    try {
      final usage = json['usageMetadata'];
      if (usage != null) {
        final inputTokens = usage['promptTokenCount'] as int? ?? 0;
        final outputTokens = usage['candidatesTokenCount'] as int? ?? 0;
        _costTracker!.trackUsage(
          endpoint: model,
          inputTokens: inputTokens,
          outputTokens: outputTokens,
        );
      }
    } catch (e) {
      stderr.writeln('⚠️ Cost tracking error: $e');
    }
  }
}
