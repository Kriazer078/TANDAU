import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/app_feedback.dart';

class FeedbackService {
  static final FeedbackService _instance = FeedbackService._internal();
  factory FeedbackService() => _instance;
  FeedbackService._internal();

  final CollectionReference _feedbackCollection = 
      FirebaseFirestore.instance.collection('feedbacks');

  /// Получить все отзывы/предложения в виде Stream для админки
  Stream<List<AppFeedback>> getFeedbacksStream() {
    return _feedbackCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AppFeedback.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  /// Получить только жалобы/предложения текущего пользователя
  Stream<List<AppFeedback>> getUserFeedbacksStream(String userId) {
    return _feedbackCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AppFeedback.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  /// Добавить новую жалобу/предложение (для пользователей)
  Future<bool> submitFeedback(AppFeedback feedback) async {
    try {
      if (feedback.id.isEmpty) {
        await _feedbackCollection.add(feedback.toMap());
      } else {
        await _feedbackCollection.doc(feedback.id).set(feedback.toMap());
      }
      return true;
    } catch (e) {
      debugPrint('Error submitting feedback: $e');
      return false;
    }
  }

  /// Обновить статус жалобы (для админа)
  Future<bool> updateFeedbackStatus(String id, FeedbackStatus status, {String? adminReply}) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.name,
      };
      
      if (adminReply != null) {
        updateData['adminReply'] = adminReply;
      }

      await _feedbackCollection.doc(id).update(updateData);
      return true;
    } catch (e) {
      debugPrint('Error updating feedback status: $e');
      return false;
    }
  }

  /// Удалить жалобу
  Future<bool> deleteFeedback(String id) async {
    try {
      await _feedbackCollection.doc(id).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting feedback: $e');
      return false;
    }
  }
}
