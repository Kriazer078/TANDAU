import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/university.dart';
import '../models/student_profile.dart';

/// AI-консультант для помощи студентам в выборе университета
class AIConsultantService {
  static final AIConsultantService _instance = AIConsultantService._internal();
  factory AIConsultantService() => _instance;
  AIConsultantService._internal();

  // PRODUCTION URL:
  static const String _baseUrl = 'https://tandau-backend.onrender.com/api/v1';

  /// Инициализация (перемещена на backend)
  void init() {
    // No-op for client side logic
  }

  /// Получить подробную стратегию поступления (TANDAU AI Agent)
  Future<String> getAdmissionStrategy({
    required StudentProfile profile,
    required University university,
    bool isPro = false,
  }) async {
    try {
      // 1. Calculate Probability & Risk (Probability Engine simulation)
      final calcResult = _calculateProbabilityAndRisk(profile, university);
      final double probability = calcResult['probability'] as double;
      final String riskLevel = calcResult['riskLevel'] as String;
      final List<String> weakAreas = calcResult['weakAreas'] as List<String>;

      // 2. Prepare JSON Payload for the AI
      final Map<String, dynamic> inputData = {
        "student": {
          "gpa": profile.gpa ?? 0.0,
          "ielts": profile.ieltsScore ?? 0.0,
          "mathScore": profile.mathScore ?? 0,
          "profileStrength": profile.profileStrength ?? 0.5,
          "entScore": profile.entScore ?? 0,
        },
        "university": {
          "name": university.name,
          "requiredScore": university.passingScore,
          "competitionLevel": "high",
        },
        "calculatedProbability": probability,
        "riskLevel": riskLevel,
        "weakAreas": weakAreas,
        "subscription": isPro ? "PRO" : "FREE",
      };

      final String jsonInput = jsonEncode(inputData);

      // 3. Send to AI Agent with Specific Strategy Prompt
      // We wrap the JSON in the specific instruction the user provided
      final String strategyPrompt =
          '''
$_strategySystemInstruction

Input data (JSON):
$jsonInput
''';

      return await sendMessage(strategyPrompt, isInternalStrategyCall: true);
    } catch (e) {
      return 'Error generating strategy: $e';
    }
  }

  /// Helper: Probability Engine Simulation
  Map<String, dynamic> _calculateProbabilityAndRisk(
    StudentProfile profile,
    University university,
  ) {
    double probability = 0.5;
    List<String> weakAreas = [];

    // ENT Score logic
    if (profile.entScore != null && university.passingScore > 0) {
      if (profile.entScore! < university.passingScore) {
        probability -= 0.3;
        weakAreas.add(
          "ЕНТ: Ниже проходного балла (${university.passingScore})",
        );
      } else if (profile.entScore! >= university.passingScore + 20) {
        probability += 0.2;
      }
    }

    // IELTS logic
    if (profile.ieltsScore != null && profile.ieltsScore! < 6.0) {
      probability -= 0.15;
      weakAreas.add("IELTS: Нужно минимум 6.0-6.5");
    }

    // GPA logic
    if (profile.gpa != null && profile.gpa! < 3.2) {
      probability -= 0.1;
      weakAreas.add("GPA: Средний балл ниже 3.2");
    }

    // Clamp & Risk Level
    probability = probability.clamp(0.05, 0.98);
    String riskLevel = "medium";
    if (probability < 0.4) {
      riskLevel = "high";
    } else if (probability > 0.75) {
      riskLevel = "low";
    }

    return {
      'probability': double.parse(probability.toStringAsFixed(2)),
      'riskLevel': riskLevel,
      'weakAreas': weakAreas,
    };
  }

  /// Отправить сообщение AI консультанту (Chat)
  Future<String> sendMessage(
    String message, {
    List<String>? userAchievements,
    int? entScore,
    double? ieltsScore,
    double? gpa,
    List<String>? preferredCities,
    List<String>? preferredMajors,
    String? currentEducation,
    bool isInternalStrategyCall = false,
  }) async {
    try {
      String fullMessage;

      if (isInternalStrategyCall) {
        // For internal strategy calls, the message already contains the prompt and JSON
        fullMessage = message;
      } else {
        // Building context for general chat
        String context = '';
        if (userAchievements != null && userAchievements.isNotEmpty) {
          context += 'Достижения: ${userAchievements.join(", ")}. ';
        }
        if (entScore != null && entScore > 0) {
          context += 'ЕНТ: $entScore. ';
        }
        if (ieltsScore != null && ieltsScore > 0) {
          context += 'IELTS: $ieltsScore. ';
        }
        if (gpa != null && gpa > 0) {
          context += 'GPA: $gpa. ';
        }
        if (preferredCities != null && preferredCities.isNotEmpty) {
          context += 'Города: ${preferredCities.join(", ")}. ';
        }
        if (currentEducation != null && currentEducation.isNotEmpty) {
          context += 'Текущее образование: $currentEducation. ';
        }

        fullMessage =
            '$_chatSystemInstruction\n\n${context.isNotEmpty ? 'Context: $context\n\n' : ''}Question: $message';
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'question': fullMessage}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['answer'] ?? 'No answer received.';
      }
      return 'Server error: ${response.statusCode}';
    } catch (e) {
      return 'Connection error: $e';
    }
  }

  // --- SYSTEM INSTRUCTIONS ---

  static const String _chatSystemInstruction = '''
SYSTEM INSTRUCTIONS:
You are TANDAU AI — a concise UNIVERSITY admission expert in Kazakhstan. 
FOCUS ON UNIVERSITIES only. Be brief (max 150 words). No questions unless necessary.
Language: Russian.
''';

  static const String _strategySystemInstruction = '''
SYSTEM INSTRUCTIONS:

You are TANDAU AI — a university admission assistant. 
Your role is to explain the admission probability calculated by the backend Probability Engine and give actionable guidance to the student.

Rules:
- DO NOT calculate probability yourself. Use only the backend data.
- Explain probability in simple terms: Low / Medium / High risk.
- Highlight the student's weak areas objectively.
- Provide 2–4 actionable steps to improve.
- (PRO subscription only) Suggest 1–2 alternative universities if risk is Medium/High.
- Output headings (in Russian): "Резюме", "Разбор шансов", "Слабые стороны", "План действий", "Альтернативы (PRO)".
- Be concise, professional, and encouraging.
- Never invent numbers or requirements.
- Language: Russian.

Expected output format:

Резюме:
- [Short explanation of the student's situation]

Разбор шансов:
- [Risk level and reasoning based on backend probability]

Слабые стороны:
- [List of areas needing improvement]

План действий:
- [Step-by-step actions for the student]

Альтернативы (PRO):
- [1–2 suggested universities if applicable]
''';
}
