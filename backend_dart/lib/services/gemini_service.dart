import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/university.dart';

class GeminiService {
  final String _apiKey;

  // List of models available to current key (updated based on check_gemini.dart output)
  static const List<String> _endpoints = [
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent',
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent',
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro-latest:generateContent',
  ];

  GeminiService(this._apiKey);

  Future<String> _generate(String prompt) async {
    if (_apiKey.isEmpty || _apiKey.startsWith('REPLACE')) {
      return 'Error: Gemini API Key is missing. Please check .env file.';
    }

    stderr.writeln(
        'Sending prompt to Gemini... (Attempting with multiple models)');

    String lastError = '';

    // Iterate through available endpoints until one works
    for (final endpoint in _endpoints) {
      try {
        final modelName = endpoint.split('/models/').last.split(':').first;
        stderr.writeln('Attempting model: $modelName... ($endpoint)');

        final response = await http.post(
          Uri.parse('$endpoint?key=$_apiKey'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt}
                ]
              }
            ]
          }),
        );

        if (response.statusCode == 200) {
          stderr.writeln('Success with model: $modelName');
          final json = jsonDecode(utf8.decode(response.bodyBytes));
          return json['candidates']?[0]?['content']?['parts']?[0]?['text'] ??
              'No response content.';
        } else {
          lastError =
              'Error $modelName: ${response.statusCode} - ${response.body}';
          stderr.writeln(lastError);
          // Continue to next model...
        }
      } catch (e) {
        lastError = 'Connection Error: $e';
        stderr.writeln(lastError);
        // Continue to next model...
      }
    }

    return 'All Gemini models failed. Last error: $lastError';
  }

  Future<String> generateChat(String question) async {
    final prompt = '''
You are "TANDAU AI", a helpful university consultant for students in Kazakhstan. 
Role: Answer questions about universities, grants, and admission.
Tone: Friendly, professional, encouraging.
Language: Answer in the same language as the question (Russian, Kazakh, or English).

User Question: $question
''';
    return _generate(prompt);
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
}
