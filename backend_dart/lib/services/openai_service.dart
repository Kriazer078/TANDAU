import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/university.dart';

/// @deprecated This service is no longer used. Use GeminiService instead.
/// Kept for reference only. Will be removed in a future cleanup.
@Deprecated('Use GeminiService instead — this service is no longer active.')
class OpenAIService {
  final String _apiKey;

  OpenAIService(this._apiKey);

  Future<String> generateRecommendation({
    required List<University> universities,
    required String userPrompt,
    required Map<String, dynamic> userProfile,
  }) async {
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    // Filter relevant universities based on request (simple matching for context reduction)
    final contextUniversities = universities
        .take(15)
        .map((u) =>
            "- ${u.name} in ${u.city}. Subjects: ${u.subjects.join(', ')}. Min Score: ${u.minScore}. Price: ${u.price}. Grants: ${u.hasGrants}.")
        .join('\n');

    final systemPrompt = '''
You are "TANDAU AI", a university admission navigator for students in Kazakhstan.
Your role is to compare universities and provide recommendations based on the user's profile.
The user will provide their score, preferred city, and subjects.

Available Universities to consider (from database):
$contextUniversities

Instructions:
1. Analyze the user's profile and the available universities.
2. Recommend the best 3-5 matching universities. If none match perfectly, suggest close alternatives.
3. Compare them by price, score, and grant availability.
4. Format your response in clean Markdown.
5. Be encouraging but realistic about admission chances.
6. Answer in the same language as the user (Russian/Kazakh/English).
''';

    final body = jsonEncode({
      'model': 'gpt-4o-mini', // or gpt-3.5-turbo if cost is concern
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {
          'role': 'user',
          'content': 'User Profile: $userProfile\n\nUser Question: $userPrompt'
        }
      ],
      'temperature': 0.7,
      'max_tokens': 1000,
    });

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'];
      } else {
        // print('OpenAI API Error: ${response.body}');
        return 'Error communicating with AI service. Status: ${response.statusCode}';
      }
    } catch (e) {
      // print('Exception calling OpenAI: $e');
      return 'Error: $e';
    }
  }

  Future<String> generateChat(String question) async {
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    final body = jsonEncode({
      'model': 'gpt-4o-mini',
      'messages': [
        {
          'role': 'system',
          'content':
              'You are "TANDAU AI", a university admission navigator for students in Kazakhstan. Answer in the same language as the user. Be friendly, encouraging, and realistic.'
        },
        {'role': 'user', 'content': question}
      ],
      'temperature': 0.7,
    });

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'];
      } else {
        return 'Server error: ${response.statusCode}';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }
}
