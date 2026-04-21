import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/firebase_service.dart';
import '../services/gemini_service.dart';
import '../services/knowledge_service.dart';
import '../services/intent_detector.dart';
import '../services/system_prompts.dart';
import '../services/ai_logger_service.dart';
import '../models/university.dart';

class UniversityController {
  final FirebaseService _firebaseService;
  final GeminiService _aiService;
  final KnowledgeService _knowledgeService;
  AILoggerService? _aiLogger;
  final Router router = Router();

  UniversityController(
      this._firebaseService, this._aiService, this._knowledgeService) {
    router.post('/recommend', _recommend);
    router.post('/chat', _chat);
    router.post('/zheke-zhospar', _zhekeZhospar);
    router.post('/ai/getAIStrategy', _getAIStrategy);
    router.get('/health', (Request req) {
      final status = {
        'status': 'ok',
        'service': 'TANDAU Backend',
        'version': '1.1.0',
        'firebase_initialized': _firebaseService.isInitialized,
        'knowledge_initialized': _knowledgeService.isInitialized,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      };
      return Response.ok(
        jsonEncode(status),
        headers: {'Content-Type': 'application/json'},
      );
    });
  }

  /// Set AI logger (optional, set from server.dart)
  void setAILogger(AILoggerService logger) {
    _aiLogger = logger;
  }

  // ═══════════════════════════════════════════════════════════════
  //  💎 SHARED TOKEN LIMIT LOGIC (single source of truth)
  // ═══════════════════════════════════════════════════════════════

  /// Check AI token limits for a user. Returns:
  /// - `null` if the user has tokens (or uid is null) → proceed with AI call
  /// - `Response` if tokens are exhausted → return this response immediately
  ///
  /// Also sets [shouldDeduct] to true when a token should be deducted after
  /// the AI call completes successfully.
  Future<({Response? limitResponse, bool shouldDeduct, Map<String, dynamic>? userDoc})>
      _checkTokenLimit(String? uid) async {
    if (uid == null) {
      return (limitResponse: null, shouldDeduct: false, userDoc: null);
    }

    final userDoc = await _firebaseService.getUserDocument(uid);
    if (userDoc == null) {
      return (limitResponse: null, shouldDeduct: false, userDoc: null);
    }

    final plan = userDoc['subscriptionPlan'] as String? ?? 'free';
    int tokens = userDoc['aiTokensRemaining'] as int? ?? 1000;
    final lastResetStr = userDoc['lastTokenResetDate'] as String?;

    // Check if we need to reset tokens (different day)
    DateTime now = DateTime.now().toUtc();
    DateTime? lastResetDate;
    if (lastResetStr != null) {
      lastResetDate = DateTime.tryParse(lastResetStr);
    }

    bool isNewDay = true;
    if (lastResetDate != null) {
      isNewDay = now.day != lastResetDate.day ||
          now.month != lastResetDate.month ||
          now.year != lastResetDate.year;
    }

    if (isNewDay) {
      tokens = plan == 'free' ? 1000 : (plan == 'pro' ? 1000 : 9999);
      await _firebaseService.updateUserFields(
          uid, {'aiTokensRemaining': tokens, 'lastTokenResetDate': now});
    }

    if (plan == 'free' && tokens <= 0) {
      final response = Response.ok(
        jsonEncode({
          'answer':
              '💎 **Лимит запросов исчерпан.**\n\nВы использовали все бесплатные ИИ-запросы на сегодня. Обновите подписку до **TANDAU PRO**, чтобы получить больше возможностей 🚀',
          'message': 'No free tokens left.',
          'description': '💎 **Лимит запросов исчерпан.**',
          'outOfTokens': true,
          'success': false,
        }),
        headers: {'Content-Type': 'application/json'},
      );
      return (limitResponse: response, shouldDeduct: false, userDoc: userDoc);
    }

    final shouldDeduct = plan != 'premium';
    return (limitResponse: null, shouldDeduct: shouldDeduct, userDoc: userDoc);
  }

  /// Deduct one AI token (fire-and-forget, uses atomic decrement)
  Future<void> _deductToken(String? uid, bool shouldDeduct) async {
    if (!shouldDeduct || uid == null) return;
    await _firebaseService.decrementUserTokens(uid, 1);
  }

  Future<Response> _chat(Request request) async {
    final chatStopwatch = Stopwatch()..start();
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final question = data['question'] as String?;
      final uid = data['uid'] as String?; // Added to identify user for limits
      final userContext = data['userContext'] as String?;
      final language = data['language'] as String? ?? 'ru';

      // SECURITY: Parse history and limit length to max 10 messages, max 1500 chars per text
      final rawHistory = data['history'] as List<dynamic>?;
      List<Map<String, dynamic>>? history;

      if (rawHistory != null) {
        // Take only last 10 messages to prevent token bloat
        final limitedHistory = rawHistory.length > 10
            ? rawHistory.sublist(rawHistory.length - 10)
            : rawHistory;

        history = limitedHistory.map((item) {
          final isUser = item['role'] == 'user'; // FIX: Read 'role' from frontend
          String text = item['text']?.toString() ?? '';
          // Truncate overly long history messages
          if (text.length > 1500) {
            text = '${text.substring(0, 1500)}...';
          }
          return {
            'role': isUser ? 'user' : 'model',
            'parts': [
              {'text': text}
            ]
          };
        }).toList();
        
        // Remove empty or malformed histories
        history = history.where((h) => h['parts']![0]['text'].toString().isNotEmpty).toList();
      }

      if (question == null || question.trim().isEmpty) {
        return Response.badRequest(body: 'Missing question');
      }

      // SECURITY: Limit input length to prevent prompt injection / abuse
      if (question.length > 5000) {
        return Response.badRequest(body: 'Question too long (max 5000 chars)');
      }

      // --- 💎 AI LIMITS (shared logic) ---
      final tokenCheck = await _checkTokenLimit(uid);
      if (tokenCheck.limitResponse != null) {
        // Token Limit returns a static JSON, we need to map it to SSE if we want
        final bodyText = await tokenCheck.limitResponse!.readAsString();
        final bodyJson = jsonDecode(bodyText);
        final encodedText = jsonEncode(bodyJson['answer']);
        final sseData = 'data: {"answer": $encodedText}\n\ndata: [DONE]\n\n';
        return Response.ok(
          Stream.value(sseData),
          headers: {
            'Content-Type': 'text/event-stream',
            'Cache-Control': 'no-cache',
            'Connection': 'keep-alive',
          },
        );
      }
      final bool shouldDeductToken = tokenCheck.shouldDeduct;
      final Map<String, dynamic>? userDoc = tokenCheck.userDoc;

      // 🎯 Intent Detection — classify query before calling AI
      final intentResult = IntentDetector.detect(question, language: language);

      // Quick reply for greetings/off-topic (no AI call needed)
      if (!intentResult.needsAI) {
        stderr.writeln('🎯 Intent: ${intentResult.intent.name} (quick reply)');
        final quickReply = intentResult.quickReply!;
        final encodedText = jsonEncode(quickReply);
        final sseData = 'data: {"answer": $encodedText}\n\ndata: [DONE]\n\n';
        return Response.ok(
          Stream.value(sseData),
          headers: {
            'Content-Type': 'text/event-stream',
            'Cache-Control': 'no-cache',
            'Connection': 'keep-alive',
          },
        );
      }

      // Map intent to prompt instruction
      String? intentInstruction;
      switch (intentResult.intent) {
        case QueryIntent.compare:
          intentInstruction = SystemPrompts.intentCompare;
          break;
        case QueryIntent.strategy:
          intentInstruction = SystemPrompts.intentStrategy;
          break;
        case QueryIntent.emotion:
          intentInstruction = SystemPrompts.intentEmotion;
          break;
        case QueryIntent.info:
          intentInstruction = SystemPrompts.intentInfo;
          break;
        default:
          break;
      }

      stderr.writeln('🎯 Intent: ${intentResult.intent.name}');

      // 🔗 Inject real university ID→name mapping for correct app:// links
      String enrichedContext = userContext ?? '';
      
      // 🧑‍🎓 Inject User Context (RAG)
      if (userDoc != null) {
        enrichedContext += '\n\n### ПРОФИЛЬ АБИТУРИЕНТА:\n';
        
        final name = userDoc['name'];
        if (name != null) enrichedContext += '- Имя: $name\n';
        
        final untScore = userDoc['untScore'] ?? userDoc['score'];
        if (untScore != null) enrichedContext += '- Балл ЕНТ: $untScore\n';
        
        final ielts = userDoc['ieltsScore'];
        if (ielts != null) enrichedContext += '- IELTS: $ielts\n';
        
        final gpa = userDoc['gpa'];
        if (gpa != null) enrichedContext += '- GPA: $gpa\n';
        
        final mathScore = userDoc['mathScore'];
        if (mathScore != null) enrichedContext += '- Математика/проф. предмет: $mathScore\n';

        final city = userDoc['city'];
        if (city != null && city.toString().isNotEmpty) {
          enrichedContext += '- Текущий город: $city\n';
        }
        
        final preferredCities = userDoc['preferredCities'];
        if (preferredCities is List && preferredCities.isNotEmpty) {
          enrichedContext += '- Желаемые города обучения: ${preferredCities.join(', ')}\n';
        }
        
        final majors = userDoc['preferredMajors'] ?? userDoc['subjects'];
        if (majors != null) {
          if (majors is List && majors.isNotEmpty) {
            enrichedContext += '- Желаемые специальности/направления: ${majors.join(', ')}\n';
          } else if (majors is String && majors.isNotEmpty) {
            enrichedContext += '- Желаемые специальности/направления: $majors\n';
          }
        }
        
        final budget = userDoc['budget'];
        if (budget != null) enrichedContext += '- Бюджет на обучение: $budget тг\n';
        
        final financial = userDoc['financialSituation'];
        if (financial != null && financial.toString().isNotEmpty) {
          enrichedContext += '- Финансовая ситуация: $financial\n';
        }
        
        final targetProfession = userDoc['targetProfession'];
        if (targetProfession != null && targetProfession.toString().isNotEmpty) {
          enrichedContext += '- Целевая профессия: $targetProfession\n';
        }
        
        final achievements = userDoc['achievements'];
        if (achievements != null) {
          if (achievements is List && achievements.isNotEmpty) {
            enrichedContext += '- Достижения: ${achievements.join(', ')}\n';
          } else if (achievements is String && achievements.isNotEmpty) {
            enrichedContext += '- Достижения: $achievements\n';
          }
        }
        
        final extra = userDoc['extracurriculars'];
        if (extra is List && extra.isNotEmpty) {
          enrichedContext += '- Кружки и активность: ${extra.join(', ')}\n';
        }

        List<String> quotas = [];
        if (userDoc['isRural'] == true) quotas.add('Сельская квота');
        if (userDoc['isOrphan'] == true) quotas.add('Сирота/СУСН квота');
        if (userDoc['hasDisability'] == true) quotas.add('Квота по инвалидности');
        if (quotas.isNotEmpty) enrichedContext += '- Квоты: ${quotas.join(', ')}\n';
      }

      try {
        final universities = await _firebaseService.getUniversities();
        if (universities.isNotEmpty) {
          final idMap = universities
              .map((u) => '- ${u.id}: ${u.name} (${u.city})')
              .join('\n');
          enrichedContext +=
              '\n\n### СПРАВОЧНИК ID ВУЗОВ (используй ТОЛЬКО эти ID для ссылок app://university/ID):\n$idMap';
        }
      } catch (e) {
        stderr.writeln('⚠️ Failed to load uni IDs for context: $e');
      }

      // 🧭 Navigation whitelist — strict allowed targets
      enrichedContext +=
          '\n\n### ДОПУСТИМЫЕ НАВИГАЦИИ (используй ТОЛЬКО эти значения для ACTION NAVIGATE):\n'
          '- favorites — Избранные вузы\n'
          '- profile — Настройка профиля\n'
          '- calculator — Калькулятор шансов\n'
          '- home — Главная страница';

      final stream = await _aiService.generateChatStream(
        question,
        history: history,
        ragContext: await _knowledgeService.searchAndFormatAsync(question),
        userContext: enrichedContext.isNotEmpty ? enrichedContext : null,
        intentInstruction: intentInstruction,
      );

      // Deduct token if successful and not premium
      _deductToken(uid, shouldDeductToken);

      // Write SSE chunks
      final sseStream = () async* {
        try {
          await for (final text in stream) {
            if (text.trim().isEmpty) continue; // Skip empty/whitespace chunks
            final encodedText = jsonEncode(text);
            yield utf8.encode('data: {"answer": $encodedText}\n\n');
          }
        } catch (e) {
          stderr.writeln('⚠️ Stream error mid-chat: $e');
          final errMsg = jsonEncode('\n\n📍 *Ошибка соединения. Попробуйте снова.*');
          yield utf8.encode('data: {"answer": $errMsg}\n\n');
        }
        yield utf8.encode('data: [DONE]\n\n');
      }();

      // 📊 Log AI interaction (fire-and-forget)
      chatStopwatch.stop();
      _aiLogger?.logInteraction(
        endpoint: 'chat',
        question: question,
        intent: intentResult.intent.name,
        latencyMs: chatStopwatch.elapsedMilliseconds,
        success: true,
      );

      return Response.ok(
        sseStream,
        headers: {
          'Content-Type': 'text/event-stream',
          'Cache-Control': 'no-cache',
          'Connection': 'keep-alive',
          'X-Accel-Buffering': 'no',
        },
        context: {
          "shelf.io.buffer_output": false
        }, // Disable buffering for true streaming
      );
    } catch (e) {
      chatStopwatch.stop();
      stderr.writeln('AI Chat Error: $e');
      _aiLogger?.logInteraction(
        endpoint: 'chat',
        question: 'error',
        latencyMs: chatStopwatch.elapsedMilliseconds,
        success: false,
        errorMessage: e.toString(),
      );
      
      final errorAnswer = jsonEncode('📍 **Сервис временно недоступен.**\n\nПроизошла техническая ошибка. Мы уже уведомлены и работаем над исправлением. Пожалуйста, попробуйте позже.');
      // Return error as valid SSE so client UI parses it
      final sseData = 'data: {"answer": $errorAnswer}\n\ndata: [DONE]\n\n';
      return Response.ok(
        Stream.value(sseData),
        headers: {
          'Content-Type': 'text/event-stream',
          'Cache-Control': 'no-cache',
          'Connection': 'keep-alive',
        },
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
    final stratStopwatch = Stopwatch()..start();
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

      // --- 💎 AI LIMITS (shared logic) ---
      final tokenCheck = await _checkTokenLimit(uid);
      if (tokenCheck.limitResponse != null) return tokenCheck.limitResponse!;
      final bool shouldDeductToken = tokenCheck.shouldDeduct;

      // Fetch university name
      final universities = await _firebaseService.getUniversities();
      final university = universities.firstWhere((u) => u.id == universityId,
          orElse: () => University(
                id: 'unknown',
                name: 'Университет',
                city: '',
                logoUrl: '',
                imageUrls: [],
                subjects: [],
                minScore: 0,
                price: '',
                hasGrants: false,
                hasDormitory: false,
                description: '',
                website: '',
                rating: 0,
                studentCount: 0,
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
      _deductToken(uid, shouldDeductToken);

      stratStopwatch.stop();
      _aiLogger?.logInteraction(
        endpoint: 'strategy',
        question: 'strategy:${university.name}',
        latencyMs: stratStopwatch.elapsedMilliseconds,
        success: true,
      );

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
      stratStopwatch.stop();
      stderr.writeln('AI Strategy Error: $e\n$stack');
      _aiLogger?.logInteraction(
        endpoint: 'strategy',
        question: 'error',
        latencyMs: stratStopwatch.elapsedMilliseconds,
        success: false,
        errorMessage: e.toString(),
      );
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
    final zhekeStopwatch = Stopwatch()..start();
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

      // --- 💎 AI LIMITS (shared logic) ---
      final tokenCheck = await _checkTokenLimit(uid);
      if (tokenCheck.limitResponse != null) {
        final bodyText = await tokenCheck.limitResponse!.readAsString();
        final bodyJson = jsonDecode(bodyText);
        final encodedText = jsonEncode(bodyJson['answer']);
        final sseData = 'data: {"answer": $encodedText}\n\ndata: [DONE]\n\n';
        return Response.ok(
          Stream.value(sseData),
          headers: {
            'Content-Type': 'text/event-stream',
            'Cache-Control': 'no-cache',
            'Connection': 'keep-alive',
          },
        );
      }
      final bool shouldDeductToken = tokenCheck.shouldDeduct;

      // RAG context
      final ragContext = await _knowledgeService.searchAndFormatAsync(
          'грант квота специальность ЕНТ план поступление $majors');

      final stream = await _aiService.generateZhekeZhosparStream(
        userProfile: userProfile,
        ragContext: ragContext,
      );

      // Deduct token
      _deductToken(uid, shouldDeductToken);

      zhekeStopwatch.stop();
      _aiLogger?.logInteraction(
        endpoint: 'zheke-zhospar',
        question: 'zheke:$majors',
        latencyMs: zhekeStopwatch.elapsedMilliseconds,
        success: true,
      );

      // 🛡️ BUG#7+BUG#8: Filter empty chunks + handle mid-stream errors
      final sseStream = () async* {
        try {
          await for (final text in stream) {
            if (text.trim().isEmpty) continue; // Skip empty/whitespace chunks
            final encodedText = jsonEncode(text);
            yield utf8.encode('data: {"answer": $encodedText}\n\n');
          }
        } catch (e) {
          stderr.writeln('⚠️ Stream error mid-zheke: $e');
          final errMsg = jsonEncode('\n\n📍 *Ошибка соединения. Попробуйте снова.*');
          yield utf8.encode('data: {"answer": $errMsg}\n\n');
        }
        yield utf8.encode('data: [DONE]\n\n');
      }();

      return Response.ok(
        sseStream,
        headers: {
          'Content-Type': 'text/event-stream',
          'Cache-Control': 'no-cache',
          'Connection': 'keep-alive',
        },
        context: {"shelf.io.buffer_output": false},
      );
    } catch (e) {
      zhekeStopwatch.stop();
      stderr.writeln('Zheke Zhospar Error: $e');
      _aiLogger?.logInteraction(
        endpoint: 'zheke-zhospar',
        question: 'error',
        latencyMs: zhekeStopwatch.elapsedMilliseconds,
        success: false,
        errorMessage: e.toString(),
      );
      
      final errorAnswer = jsonEncode('📍 **Не удалось создать Жеке Жоспар.**\n\nПроизошла ошибка. Попробуйте позже.');
      final sseData = 'data: {"answer": $errorAnswer}\n\ndata: [DONE]\n\n';
      return Response.ok(
        Stream.value(sseData),
        headers: {
          'Content-Type': 'text/event-stream',
          'Cache-Control': 'no-cache',
          'Connection': 'keep-alive',
        },
      );
    }
  }
}
