import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

/// Service to save AI response feedback (👍/👎) to Firestore.
/// Collection: `ai_feedback`
/// Used for analytics and AI improvement.
class AIFeedbackService {
  static final AIFeedbackService _instance = AIFeedbackService._internal();
  factory AIFeedbackService() => _instance;
  AIFeedbackService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Save feedback for an AI response.
  /// [isHelpful] — true for 👍, false for 👎
  /// [aiResponse] — truncated AI response text (max 500 chars for storage)
  /// [userQuestion] — the user's question that prompted this response
  Future<void> saveFeedback({
    required bool isHelpful,
    required String aiResponse,
    String? userQuestion,
  }) async {
    try {
      final user = AuthService().currentUser.value;
      final String uid = user?.uid ?? 'anonymous';

      await _firestore.collection('ai_feedback').add({
        'uid': uid,
        'isHelpful': isHelpful,
        'aiResponse': aiResponse.length > 500
            ? '${aiResponse.substring(0, 500)}...'
            : aiResponse,
        'userQuestion': userQuestion,
        'timestamp': FieldValue.serverTimestamp(),
        'appVersion': '2.0',
      });

      debugPrint('AI Feedback saved: ${isHelpful ? "👍" : "👎"}');
    } catch (e, stack) {
      debugPrint('Failed to save AI feedback: $e');
      debugPrint('$stack');
    }
  }
}
