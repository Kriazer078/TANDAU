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

  // ✅ Multi-version 2026 Fallback System
  static const List<String> _endpoints = [
    // Latest 2026 Models
    'https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent', 
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash:generateContent',
    
    // High Compatibility 1.5 Series
    'https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent',
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent',
    
    // Generic Aliases
    'https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent',
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

    // 🛠️ FAILSAFE: Normalize contents (roles must alternate)
    final List<Map<String, dynamic>> normalizedContents = [];
    String lastRole = '';
    for (var i = 0; i < contents.length; i++) {
      final content = Map<String, dynamic>.from(contents[i]);
      final role = content['role'] ?? 'user';
      if (role != lastRole) {
        normalizedContents.add(content);
        lastRole = role;
      }
    }

    int lastStatusCode = 0;
    final List<String> errors = [];
    
    for (final endpoint in _endpoints) {
      try {
        final modelName = endpoint.split('/models/').last.split(':').first;
        final isV1beta = endpoint.contains('/v1beta/');
        final isV1 = endpoint.contains('/v1/');

        final Map<String, dynamic> requestBody = {
          'contents': normalizedContents,
        };

        // 🧠 Proper System Instruction handling for different versions
        if (systemInstruction != null && systemInstruction.isNotEmpty) {
          final systemPart = {
            'parts': [ {'text': systemInstruction} ]
          };
          if (isV1) {
            requestBody['system_instruction'] = systemPart;
          } else {
            requestBody['systemInstruction'] = systemPart;
          }
        }

        // 🔍 Google Search Grounding (ONLY for v1beta)
        if (useGrounding && isV1beta) {
          requestBody['tools'] = [
            {
              'google_search_retrieval': {
                'dynamic_retrieval_config': {
                  'mode': 'MODE_DYNAMIC',
                  'dynamic_threshold': 0.1,
                }
              }
            }
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
          final text = json['candidates']?[0]?['content']?[ 'parts']?[0]?['text'];
          if (text != null) {
            stderr.writeln('✅ Gemini ($modelName) Success via ${isV1 ? "v1" : "v1beta"}');
            _trackTokenUsage(json, modelName);
            return text;
          }
        }
        
        errors.add('$modelName (${response.statusCode}): ${response.body}');
        
        // 🛡️ RECOVERY LAYER: If any error occurs, try a "CLEAN" request as last resort
        if (response.statusCode != 200 && response.statusCode != 429) {
          stderr.writeln('⚠️ Error ${response.statusCode}. Trying "Safe Mode" for $modelName...');
          final lastPromptPart = normalizedContents.last['parts'][0]['text'];
          final safePrompt = 'Follow instructions strictly.\n\nContext: $systemInstruction\n\nQuestion: $lastPromptPart';
          
          final cleanResponse = await http.post(
            Uri.parse('$endpoint?key=$_apiKey'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'role': 'user',
                  'parts': [ {'text': safePrompt} ]
                }
              ]
            }),
          ).timeout(const Duration(seconds: 15));
          
          if (cleanResponse.statusCode == 200) {
            final json = jsonDecode(utf8.decode(cleanResponse.bodyBytes));
            return json['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? 'Ошибка парсинга';
          }
        }
      } catch (e) {
        stderr.writeln('⚠️ $e');
        errors.add('Connection error: $e');
      }
    }

    if (lastStatusCode == 429) {
      return '📍 **Лимит запросов исчерпан.**\n\nИзвините, сейчас слишком много людей пользуются AI-консультантом. Пожалуйста, подождите немного и попробуйте снова.';
    }

    return 'Извините, сервис временно недоступен.\n\n[ДЛЯ РАЗРАБОТЧИКА]:\n${errors.join('\n\n')}';
  }

  Future<Stream<String>> _generateStreamAdvanced({
    String? systemInstruction,
    required List<Map<String, dynamic>> contents,
    bool useGrounding = false,
  }) async {
    if (_apiKey.isEmpty || _apiKey.startsWith('REPLACE')) {
      return Stream.value('Ошибка: API ключ не настроен.');
    }

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
          requestBody['systemInstruction'] = {
            'parts': [
              {'text': systemInstruction}
            ]
          };
        }

        // 🔍 Google Search Grounding
        if (useGrounding) {
          requestBody['tools'] = [
            {
              'google_search_retrieval': {
                'dynamic_retrieval_config': {
                  'mode': 'MODE_DYNAMIC',
                  'dynamic_threshold': 0.1,
                }
              }
            }
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
          stderr.writeln('✅ Stream started: $modelName');
          
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
          stderr.writeln('❌ Stream failed for $modelName (${response.statusCode})');
          
          if (response.statusCode == 400 && useGrounding) {
            stderr.writeln('⚠️ Grounding stream failed. Retrying WITHOUT tools...');
            client.close();
            return _generateStreamAdvanced(
              systemInstruction: systemInstruction,
              contents: contents,
              useGrounding: false,
            );
          }

          errors.add('$modelName (${response.statusCode}): $errorBody');
          client.close();
          continue; 
        }
      } catch (e) {
        stderr.writeln('⚠️ Connection error: $e');
        errors.add('Connection error: $e');
      }
    }

    if (lastStatusCode == 429) {
      return Stream.value('📍 **Лимит запросов исчерпан.**');
    }

    return Stream.value('Сервис временно недоступен.\n\n[ДЛЯ РАЗРАБОТЧИКА]:\n${errors.join('\n\n')}');
  }

  Future<String> generateChat(
    String question, {
    List<Map<String, dynamic>>? history,
    String? ragContext,
    String? userContext,
    String? intentInstruction,
  }) async {
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
