import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/university.dart';
import 'cost_tracker_service.dart';
import 'system_prompts.dart';

class OpenAIService {
  final String _apiKey; 
  CostTrackerService? _costTracker;

  final String _model = 'llama-3.3-70b-versatile'; // Meta's model on Groq, supports system role + good Russian
  final Uri _apiUrl = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

  OpenAIService(this._apiKey);

  void setCostTracker(CostTrackerService tracker) {
    _costTracker = tracker;
  }

  static List<Map<String, dynamic>> buildMessages({
    required String question,
    String? systemInstruction,
    List<Map<String, dynamic>>? history,
    String? ragContext,
  }) {
    final List<Map<String, dynamic>> messages = [];
    
    // 1. System Instruction (llama-3.3 supports 'system' role natively)
    String fullSystemPrompt = systemInstruction ?? 'You are TANDAU AI, an expert in Kazakhstan education.';
    if (ragContext != null && ragContext.isNotEmpty) {
      // Truncate RAG context to prevent token overflow
      final truncatedRag = ragContext.length > 3000 ? ragContext.substring(0, 3000) : ragContext;
      fullSystemPrompt += '\n\n$truncatedRag';
    }
    
    // Add system message as proper 'system' role
    messages.add({'role': 'system', 'content': fullSystemPrompt});

    // 2. Chat History
    if (history != null && history.isNotEmpty) {
      for (var item in history) {
        final role = item['role'] == 'model' ? 'assistant' : (item['role'] ?? 'user');
        var content = '';
        if (item['parts'] is List && item['parts'].isNotEmpty) {
          content = item['parts'][0]['text'] ?? '';
        } else {
          content = item['content']?.toString() ?? '';
        }
        
        if (content.trim().isNotEmpty) {
          // Groq requires strictly alternating roles (user -> assistant -> user)
          if (messages.isNotEmpty && messages.last['role'] == role) {
            messages.last['content'] = '${messages.last['content']}\n\n$content';
          } else {
            messages.add({'role': role, 'content': content});
          }
        }
      }
    }

    // 3. User Question
    if (question.trim().isNotEmpty) {
      // Prevent two user messages in a row
      if (messages.isNotEmpty && messages.last['role'] == 'user') {
        messages.last['content'] = '${messages.last['content']}\n\n$question';
      } else {
        messages.add({'role': 'user', 'content': question});
      }
    }
    
    // 4. Ensure last message is from user (Groq requirement)
    if (messages.isNotEmpty && messages.last['role'] != 'user') {
      messages.add({'role': 'user', 'content': 'Продолжай на основе контекста выше.'});
    }
    
    return messages;
  }

  Future<String> _generateCompletion({
    required List<Map<String, dynamic>> messages,
  }) async {
    if (_apiKey.isEmpty || _apiKey.startsWith('REPLACE')) return 'Ошибка: API ключ OpenAI не настроен.';

    final url = _apiUrl;
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 1024,
        }),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final json = jsonDecode(utf8.decode(response.bodyBytes));
        final text = json['choices']?[0]?['message']?['content'];
        _trackTokenUsage(json, _model);
        return text ?? 'Ошибка: Пустой ответ от OpenAI';
      } else {
        stderr.writeln('❌ OpenAI Error: ${response.statusCode} - ${response.body}');
        if (response.statusCode == 429) return '📍 **Лимит запросов OpenAI исчерпан.**';
        return 'Извините, сервис OpenAI временно недоступен. (${response.statusCode})';
      }
    } catch (e) {
      stderr.writeln('⚠️ OpenAI Connection error: $e');
      return 'Ошибка соединения с OpenAI.';
    }
  }

  Future<Stream<String>> _generateStream({
    required List<Map<String, dynamic>> messages,
  }) async {
    if (_apiKey.isEmpty || _apiKey.startsWith('REPLACE')) return Stream.value('Ошибка: API ключ OpenAI не настроен.');

    final url = _apiUrl;
    
    try {
      final request = http.Request('POST', url);
      request.headers['Content-Type'] = 'application/json';
      request.headers['Authorization'] = 'Bearer $_apiKey';
      request.body = jsonEncode({
        'model': _model,
        'messages': messages,
        'temperature': 0.7,
        'max_tokens': 1024,
        'stream': true,
      });

      final client = http.Client();
      final response = await client.send(request).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        // Use a controller to properly close the HTTP client when stream ends
        final controller = StreamController<String>();
        response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .where((line) => line.startsWith('data: '))
            .map((line) {
              final dataStr = line.substring(6);
              if (dataStr.trim() == '[DONE]') return '';
              try {
                final json = jsonDecode(dataStr);
                return json['choices']?[0]?['delta']?['content']?.toString() ?? '';
              } catch (e) { return ''; }
            })
            .where((text) => text.isNotEmpty)
            .listen(
              controller.add,
              onError: controller.addError,
              onDone: () {
                controller.close();
                client.close(); // ✅ Properly close HTTP client
              },
            );
        return controller.stream;
      } else {
        client.close();
        return Stream.value('Ошибка OpenAI: ${response.statusCode}');
      }
    } catch (e) {
      stderr.writeln('⚠️ OpenAI Stream Error: $e');
      return Stream.value('Ошибка стрима OpenAI.');
    }
  }

  // --- Feature Parity Methods ---

  Future<String> generateChat(String question, {List<Map<String, dynamic>>? history, String? ragContext, String? userContext, String? intentInstruction}) async {
    return _generateCompletion(
      messages: buildMessages(
        question: question, 
        systemInstruction: SystemPrompts.buildChatPrompt(userContext: userContext, intentInstruction: intentInstruction), 
        history: history, 
        ragContext: ragContext
      ),
    );
  }

  Future<Stream<String>> generateChatStream(String question, {List<Map<String, dynamic>>? history, String? ragContext, String? userContext, String? intentInstruction}) async {
    return _generateStream(
      messages: buildMessages(
        question: question, 
        systemInstruction: SystemPrompts.buildChatPrompt(userContext: userContext, intentInstruction: intentInstruction), 
        history: history, 
        ragContext: ragContext
      ),
    );
  }

  Future<String> generateAnswer({required String question, required String ragContext, String? userContext}) async {
    return _generateCompletion(
      messages: buildMessages(
        question: question, 
        systemInstruction: SystemPrompts.buildChatPrompt(userContext: userContext), 
        ragContext: ragContext
      ),
    );
  }

  Future<String> generateComparison({required String university1, required String university2, required String context, String language = 'ru'}) async {
    return _generateCompletion(
      messages: buildMessages(
        question: 'Compare $university1 and $university2:\n$context', 
        systemInstruction: SystemPrompts.intentCompare
      ),
    );
  }

  Future<String> generateRoadmap({required String target, required String currentProfile}) async {
    return _generateCompletion(
      messages: buildMessages(
        question: 'Roadmap for Target: $target\nProfile: $currentProfile', 
        systemInstruction: SystemPrompts.strategy
      ),
    );
  }

  Future<String> generateRecommendation({required List<University> universities, required String userPrompt, required Map<String, dynamic> userProfile}) async {
    final context = universities.map((u) => "- ${u.name} (Min Score: ${u.minScore})").join('\n');
    return _generateCompletion(
      messages: buildMessages(
        question: 'Recommend for: $userPrompt\nProfile: $userProfile\nUnis:\n$context', 
        systemInstruction: 'Recommend the best universities from the list.'
      ),
    );
  }

  Future<String> generateAIStrategy({required String universityName, required int untScore, required String specialty, required Map<String, int> subjectScores, required String alternativesCtx, required String language}) async {
    final prompt = SystemPrompts.buildStrategyPrompt(universityName: universityName, untScore: untScore, specialty: specialty, scoresText: subjectScores.toString(), alternativesCtx: alternativesCtx, language: language);
    return _generateCompletion(
      messages: buildMessages(
        question: prompt, 
        systemInstruction: SystemPrompts.strategy
      ),
    );
  }

  Future<String> generateZhekeZhospar({required String userProfile, String? ragContext}) async {
    return _generateCompletion(
      messages: buildMessages(
        question: 'Создай Жеке Жоспар:\n$userProfile', 
        systemInstruction: SystemPrompts.zhekeZhospar, 
        ragContext: ragContext
      ),
    );
  }

  Future<Stream<String>> generateZhekeZhosparStream({required String userProfile, String? ragContext}) async {
    return _generateStream(
      messages: buildMessages(
        question: 'Создай Жеке Жоспар:\n$userProfile', 
        systemInstruction: SystemPrompts.zhekeZhospar, 
        ragContext: ragContext
      ),
    );
  }

  void _trackTokenUsage(Map<String, dynamic> json, String model) {
    if (_costTracker == null) return;
    try {
      final usage = json['usage'];
      if (usage != null) {
        _costTracker!.trackUsage(
          endpoint: model, 
          inputTokens: usage['prompt_tokens'] as int? ?? 0, 
          outputTokens: usage['completion_tokens'] as int? ?? 0
        );
      }
    } catch (e) { stderr.writeln('⚠️ OpenAI Tracking error: $e'); }
  }
}
