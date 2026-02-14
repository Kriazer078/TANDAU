import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/firebase_service.dart';
import '../services/gemini_service.dart';

class UniversityController {
  final FirebaseService _firebaseService;
  final GeminiService _aiService;
  final Router router = Router();

  UniversityController(this._firebaseService, this._aiService) {
    router.post('/recommend', _recommend);
    router.post('/chat', _chat);
    router.get('/health',
        (Request req) => Response.ok('Antigravity Server is running'));
  }

  Future<Response> _chat(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final question = data['question'] as String?;

      if (question == null) {
        return Response.badRequest(body: 'Missing question');
      }

      final answer = await _aiService.generateChat(question);

      return Response.ok(
        jsonEncode({'answer': answer}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(body: 'Error: $e');
    }
  }

  Future<Response> _recommend(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);

      // Validate input
      // Expected structure: { "userProfile": {...}, "question": "..." }
      if (data['userProfile'] == null || data['question'] == null) {
        return Response.badRequest(body: 'Missing userProfile or question');
      }

      final userProfile = data['userProfile'] as Map<String, dynamic>;
      final userScore = userProfile['score'] as int? ?? 0;
      final preferredCity = userProfile['city'] as String?;
      final preferredSubjects = (userProfile['subjects'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      // 1. Fetch universities from Firebase
      final allUniversities = await _firebaseService.getUniversities();

      // 2. Filter universities logic (Controller Logic as requested)
      // Filter by score (show reachable universities, e.g. score >= min_score - 10)
      // Filter by city if specified
      final filteredUniversities = allUniversities.where((u) {
        bool scoreMatch = u.minScore <=
            (userScore + 10); // Allow slightly higher score as aspirational
        bool cityMatch = preferredCity == null ||
            preferredCity.isEmpty ||
            u.city.toLowerCase() == preferredCity.toLowerCase();

        // Subject match: Check if any subject matches
        bool subjectMatch = preferredSubjects.isEmpty ||
            u.subjects.any((s) => preferredSubjects.contains(s));

        return scoreMatch &&
            (cityMatch ||
                subjectMatch); // At least one main preference matches plus score is feasible
      }).toList();

      // If no filtered results, fallback to general best universities (top rating)
      final finalUniversities = filteredUniversities.isNotEmpty
          ? filteredUniversities
          : allUniversities.take(5).toList();

      // 3. send to OpenAI
      final answer = await _aiService.generateRecommendation(
        universities: finalUniversities,
        userPrompt: data['question'],
        userProfile: userProfile,
      );

      return Response.ok(
        jsonEncode({'answer': answer}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stack) {
      stderr.writeln('Error in recommend: $e\n$stack');
      return Response.internalServerError(body: 'Internal Server Error: $e');
    }
  }
}
