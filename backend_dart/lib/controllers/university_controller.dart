import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/firebase_service.dart';
import '../services/gemini_service.dart';
import '../services/knowledge_service.dart';
import '../models/university.dart';

class UniversityController {
  final FirebaseService _firebaseService;
  final GeminiService _aiService;
  final KnowledgeService _knowledgeService;
  final Router router = Router();

  UniversityController(
      this._firebaseService, this._aiService, this._knowledgeService) {
    router.post('/recommend', _recommend);
    router.post('/chat', _chat);
    router.post('/zheke-zhospar', _zhekeZhospar);
    router.post('/ai/getAIStrategy', _getAIStrategy);
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

      if (question == null || question.trim().isEmpty) {
        return Response.badRequest(body: 'Missing question');
      }

      // SECURITY: Limit input length to prevent prompt injection / abuse
      if (question.length > 5000) {
        return Response.badRequest(body: 'Question too long (max 5000 chars)');
      }

      // --- 💎 AI LIMITS LOGIC START ---
      bool shouldDeductToken = false;
      if (uid != null) {
        final userDoc = await _firebaseService.getUserDocument(uid);
        if (userDoc != null) {
          final plan = userDoc['subscriptionPlan'] as String? ?? 'free';
          int tokens =
              userDoc['aiTokensRemaining'] as int? ?? 1000; // default 1000
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
            tokens = plan == 'free' ? 1000 : (plan == 'pro' ? 1000 : 9999);
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

      final answer = await _aiService.generateChat(
        question,
        history: history,
        ragContext: _knowledgeService.searchAndFormat(question),
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
      final language = data['language'] as String? ?? 'ru';

      if (universityId == null) {
        return Response.badRequest(body: 'Missing university_id');
      }

      // --- 💎 AI LIMITS LOGIC START ---
      bool shouldDeductToken = false;
      if (uid != null) {
        final userDoc = await _firebaseService.getUserDocument(uid);
        if (userDoc != null) {
          final plan = userDoc['subscriptionPlan'] as String? ?? 'free';
          int tokens =
              userDoc['aiTokensRemaining'] as int? ?? 1000; // default 1000
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
            tokens = plan == 'free' ? 1000 : (plan == 'pro' ? 1000 : 9999);
            // Update immediately to prevent race conditions
            await _firebaseService.updateUserFields(
                uid, {'aiTokensRemaining': tokens, 'lastTokenResetDate': now});
          }

          if (plan == 'free' && tokens <= 0) {
            return Response.ok(
              jsonEncode({
                'success': false,
                'outOfTokens': true,
                'message': 'No free tokens left.'
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

      // 💡 NEW: AI CONTEXT INJECTION (Threshold scores and alternatives)
      final minScoreCtx = university.minScore > 0
          ? 'Пороговый балл в этот вуз: ${university.minScore}.'
          : '';

      // Find alternatives that require equal or less score and have grants
      final alternativeList = universities.where((u) {
        if (u.id == universityId) return false;
        if (untScore < 50) return u.minScore <= 50; // Give anything accessible
        return u.minScore > 0 && u.minScore <= untScore + 10;
      }).toList();
      alternativeList.shuffle(); // Randomize a bit
      final alternativesCtx = alternativeList
          .take(3)
          .map((u) => '${u.name} (Порог ЕНТ: ${u.minScore})')
          .join(', ');

      final strategy = await _aiService.generateAIStrategy(
        universityName: '${university.name} $minScoreCtx', // INJECTING CONTEXT
        untScore: untScore,
        specialty: specialtyId,
        subjectScores: subjectScores,
        alternativesCtx:
            alternativesCtx.isNotEmpty ? alternativesCtx : 'Нет данных',
        language: language,
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
      // SECURITY: Do NOT expose error details to client
      return Response.internalServerError(
        body: jsonEncode({'error': 'Internal Server Error'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// POST /api/v1/zheke-zhospar
  /// Generates a personalized step-by-step admission plan
  Future<Response> _zhekeZhospar(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final uid = data['uid'] as String?;

      // Build user profile string from provided data
      final entScore = data['entScore'];
      final gpa = data['gpa'];
      final city = data['city'] ?? '';
      final majors = data['preferredMajors'] ?? '';
      final ielts = data['ieltsScore'];
      final mathScore = data['mathScore'];
      final achievements = data['achievements'] ?? '';
      final education = data['currentEducation'] ?? '';

      final profileBuffer = StringBuffer();
      profileBuffer.writeln('ЕНТ: ${entScore ?? "не указан"}');
      profileBuffer.writeln('GPA: ${gpa ?? "не указан"}');
      if (ielts != null) profileBuffer.writeln('IELTS: $ielts');
      if (mathScore != null) profileBuffer.writeln('Математика: $mathScore');
      profileBuffer.writeln('Город: $city');
      profileBuffer.writeln('Мамандық: $majors');
      profileBuffer.writeln('Образование: $education');
      if (achievements.toString().isNotEmpty) {
        profileBuffer.writeln('Достижения: $achievements');
      }

      final userProfile = profileBuffer.toString();

      // --- Token check (same as _chat) ---
      bool shouldDeductToken = false;
      if (uid != null) {
        final userDoc = await _firebaseService.getUserDocument(uid);
        if (userDoc != null) {
          final plan = userDoc['subscriptionPlan'] as String? ?? 'free';
          int tokens = userDoc['aiTokensRemaining'] as int? ?? 1000;

          if (plan == 'free' && tokens <= 0) {
            return Response.ok(
              jsonEncode({
                'answer':
                    '💎 **Лимит запросов исчерпан.**\n\nОбновите подписку до **TANDAU PRO** для генерации Жеке Жоспар 🚀',
                'outOfTokens': true
              }),
              headers: {'Content-Type': 'application/json'},
            );
          }
          if (plan != 'premium') shouldDeductToken = true;
        }
      }

      // RAG context
      final ragContext = _knowledgeService.searchAndFormat(
          'грант квота специальность ЕНТ план поступление $majors');

      final answer = await _aiService.generateZhekeZhospar(
        userProfile: userProfile,
        ragContext: ragContext,
      );

      // Deduct token
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
      stderr.writeln('Zheke Zhospar Error: $e');
      return Response.ok(
        jsonEncode({
          'answer':
              '📍 **Не удалось создать Жеке Жоспар.**\n\nПроизошла ошибка. Попробуйте позже.'
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
