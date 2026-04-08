import 'package:cloud_firestore/cloud_firestore.dart';

enum FeedbackStatus {
  newFeedback,
  inProgress,
  resolved
}

class UserFeedback {
  final String id;
  final String uid;
  final String userName;
  final String content;
  final FeedbackStatus status;
  final DateTime timestamp;
  final String? adminNote;

  UserFeedback({
    required this.id,
    required this.uid,
    required this.userName,
    required this.content,
    this.status = FeedbackStatus.newFeedback,
    required this.timestamp,
    this.adminNote,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'userName': userName,
      'content': content,
      'status': status.name,
      'timestamp': FieldValue.serverTimestamp(),
      'adminNote': adminNote,
    };
  }

  factory UserFeedback.fromMap(Map<String, dynamic> map, String id) {
    return UserFeedback(
      id: id,
      uid: map['uid'] ?? '',
      userName: map['userName'] ?? 'Аноним',
      content: map['content'] ?? '',
      status: FeedbackStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => FeedbackStatus.newFeedback,
      ),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      adminNote: map['adminNote'],
    );
  }
}
