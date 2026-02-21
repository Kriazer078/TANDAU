import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/firebase_service.dart';
import '../services/gemini_service.dart';
import '../models/university.dart';

class UniversityController {
  final FirebaseService _firebaseService;
  final GeminiService _aiService;
  final Router router = Router();

  UniversityController(this._firebaseService, this._aiService) {
    router.post('/recommend', _recommend);
    router.post('/chat', _chat);
    router.post(
        '/ai/getAIStrategy', _getAIStrategy); // Added prefix to match frontend
    router.get('/health',
        (Request req) => Response.ok('Antigravity Server is running'));
  }

  Future<Response> _chat(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final question = data['question'] as String?;
      final uid = data['uid'] as String?; // Added to identify user for limits

      // Parse history if available
      final rawHistory = data['history'] as List<dynamic>?;
      List<Map<String, dynamic>>? history;

      if (rawHistory != null) {
        history = rawHistory.map((item) {
          final isUser = item['isUser'] == true;
          return {
            'role': isUser ? 'user' : 'model',
            'parts': [
              {'text': item['text'].toString()}
            ]
          };
        }).toList();
      }

      if (question == null) {
        return Response.badRequest(body: 'Missing question');
      }

      // --- 💎 AI LIMITS LOGIC START ---
      bool shouldDeductToken = false;
      if (uid != null) {
        final userDoc = await _firebaseService.getUserDocument(uid);
        if (userDoc != null) {
          final plan = userDoc['subscriptionPlan'] as String? ?? 'free';
          int tokens = userDoc['aiTokensRemaining'] as int? ?? 5; // default 5
          final lastResetStr = userDoc['lastTokenResetDate'] as String?;

          DateTime now = DateTime.now().toUtc();
          DateTime? lastResetDate;
          if (lastResetStr != null) {
            lastResetDate = DateTime.tryParse(lastResetStr);
          }

          // Check if we need to reset tokens (different day)
          bool isNewDay = true;
          if (lastResetDate != null) {
            isNewDay = now.day != lastResetDate.day ||
                now.month != lastResetDate.month ||
                now.year != lastResetDate.year;
          }

          if (isNewDay) {
            // Reset logic based on plan
            tokens = plan == 'free' ? 5 : (plan == 'pro' ? 100 : 9999);
            // Update immediately to prevent race conditions (simple approach)
            await _firebaseService.updateUserFields(
                uid, {'aiTokensRemaining': tokens, 'lastTokenResetDate': now});
          }

          if (plan == 'free' && tokens <= 0) {
            return Response.ok(
              jsonEncode({
                'answer':
                    '💎 **Лимит запросов исчерпан.**\n\nВы использовали все бесплатные ИИ-запросы на сегодня. Обновите подписку до **TANDAU PRO**, чтобы получить больше возможностей и открыть генератор стратегии НЦТ 🚀',
                'outOfTokens': true
              }),
              headers: {'Content-Type': 'application/json'},
            );
          }

          if (plan != 'premium') {
            shouldDeductToken = true;
          }
        }
      }
      // --- 💎 AI LIMITS LOGIC END ---

      final answer = await _aiService.generateChat(question, history: history);

      // Deduct token if successful and not premium
      if (shouldDeductToken && uid != null) {
        final userDoc = await _firebaseService.getUserDocument(uid);
        if (userDoc != null) {
          int currentTokens = userDoc['aiTokensRemaining'] as int? ?? 0;
          if (currentTokens > 0) {
            await _firebaseService.updateUserFields(
                uid, {'aiTokensRemaining': currentTokens - 1});
          }
        }
      }

      return Response.ok(
        jsonEncode({'answer': answer}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      stderr.writeln('AI Chat Error: $e');
      return Response.ok(
        jsonEncode({
          'answer':
              '📍 **Сервис временно недоступен.**\n\nПроизошла техническая ошибка. Мы уже уведомлены и работаем над исправлением. Пожалуйста, попробуйте позже.'
        }),
        headers: {'Content-Type': 'application/json'},
      );
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
      stderr.writeln('Recommendation Error: $e\n$stack');
      return Response.ok(
        jsonEncode({
          'answer':
              '📍 **Ошибка обработки рекомендаций.**\n\nНе удалось составить список университетов. Пожалуйста, проверьте ваше интернет-соединение и попробуйте снова.'
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _getAIStrategy(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);

      final universityId = data['university_id'] as String?;
      final untScore = data['user_unt_score'] as int? ?? 0;
      final specialtyId = data['specialty_id'] as String? ?? 'unknown';
      final subjectScores =
          Map<String, int>.from(data['user_subjects_scores'] ?? {});
      final uid = data['uid'] as String?;

      if (universityId == null) {
        return Response.badRequest(body: 'Missing university_id');
      }

      // --- 💎 AI LIMITS LOGIC START ---
      bool shouldDeductToken = false;
      if (uid != null) {
        final userDoc = await _firebaseService.getUserDocument(uid);
        if (userDoc != null) {
          final plan = userDoc['subscriptionPlan'] as String? ?? 'free';
          int tokens = userDoc['aiTokensRemaining'] as int? ?? 5; // default 5
          final lastResetStr = userDoc['lastTokenResetDate'] as String?;

          DateTime now = DateTime.now().toUtc();
          DateTime? lastResetDate;
          if (lastResetStr != null) {
            lastResetDate = DateTime.tryParse(lastResetStr);
          }

          // Check if we need to reset tokens (different day)
          bool isNewDay = true;
          if (lastResetDate != null) {
            isNewDay = now.day != lastResetDate.day ||
                now.month != lastResetDate.month ||
                now.year != lastResetDate.year;
          }

          if (isNewDay) {
            // Reset logic based on plan
            tokens = plan == 'free' ? 5 : (plan == 'pro' ? 100 : 9999);
            // Update immediately to prevent race conditions
            await _firebaseService.updateUserFields(
                uid, {'aiTokensRemaining': tokens, 'lastTokenResetDate': now});
          }

          if (plan == 'free') {
            return Response.ok(
              jsonEncode({
                'title': 'Доступно в PRO',
                'description':
                    '💎 **Функция требует подписки.**\n\nГенератор стратегии «Алгоритм 4-х вузов» доступен только в подписках **TANDAU+**. Обновите подписку для доступа к самым точным планам поступления 🚀',
                'outOfTokens': true, // FLAG FOR FRONTEND
                'alternative_options': [
                  {'name': 'Перейти на PRO', 'icon': 'workspace_premium'},
                ]
              }),
              headers: {'Content-Type': 'application/json; charset=utf-8'},
            );
          }

          if (plan != 'premium') {
            shouldDeductToken = true;
          }
        }
      }
      // --- 💎 AI LIMITS LOGIC END ---

      // Fetch university name
      final universities = await _firebaseService.getUniversities();
      final university = universities.firstWhere((u) => u.id == universityId,
          orElse: () => University(
                id: 'unknown',
                name: 'Университет',
                city: '',
                subjects: [],
                minScore: 0,
                price: '',
                hasGrants: false,
                description: '',
                website: '',
                rating: 0,
              ));

      final strategy = await _aiService.generateAIStrategy(
        universityName: university.name,
        untScore: untScore,
        specialty: specialtyId,
        subjectScores: subjectScores,
      );

      // Deduct token if successful and not premium
      if (shouldDeductToken && uid != null) {
        final userDoc = await _firebaseService.getUserDocument(uid);
        if (userDoc != null) {
          int currentTokens = userDoc['aiTokensRemaining'] as int? ?? 0;
          if (currentTokens > 0) {
            await _firebaseService.updateUserFields(
                uid, {'aiTokensRemaining': currentTokens - 1});
          }
        }
      }

      return Response.ok(
        jsonEncode({
          'title': 'Стратегия: ${university.name}',
          'description': strategy,
          'alternative_options': [
            {'name': 'Усилить подготовку к ЕНТ', 'icon': 'trending_up'},
            {'name': 'Рассмотреть смежные специальности', 'icon': 'list_alt'},
          ]
        }),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
        },
      );
    } catch (e, stack) {
      stderr.writeln('AI Strategy Error: $e\n$stack');
      return Response.internalServerError(body: 'Internal Server Error: $e');
    }
  }
}
