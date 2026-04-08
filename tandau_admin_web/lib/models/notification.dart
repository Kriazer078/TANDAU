import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType { grant, news, ai, alert }

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime time;
  final NotificationType type;
  final bool isRead;
  final Map<String, dynamic>? data;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    this.isRead = false,
    this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'time': Timestamp.fromDate(time),
      'type': type.name,
      'isRead': isRead,
      'data': data,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map, String id) {
    return AppNotification(
      id: id,
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      time: (map['time'] as Timestamp).toDate(),
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.news,
      ),
      isRead: map['isRead'] ?? false,
      data: map['data'],
    );
  }
}
