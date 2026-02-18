import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/university_detail_screen.dart';
import 'university_service.dart';
import '../models/notification.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  GlobalKey<NavigatorState>? _navigatorKey;

  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  /// Initialize notification services
  Future<void> init() async {
    // 1. Request permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (kDebugMode) {
      print('User granted permission: ${settings.authorizationStatus}');
    }

    // 2. Setup Local Notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          try {
            final Map<String, dynamic> data = jsonDecode(response.payload!);
            _handleMessageData(data);
          } catch (e) {
            if (kDebugMode) {
              print('Error parsing local notification payload: $e');
            }
          }
        }
      },
    );

    // 3. Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 4. Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showLocalNotification(message);
        _saveNotificationToFirestore(message);
      }
    });

    // 5. Handle clicks
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessageData(message.data);
    });

    // Handle Terminated state (Check after initialization)
    _fcm.getInitialMessage().then((initialMessage) {
      if (initialMessage != null) {
        // Wait for navigator to be ready
        Future.delayed(const Duration(milliseconds: 1500), () {
          _handleMessageData(initialMessage.data);
        });
      }
    });

    // 6. Token handling
    String? token = await getToken();
    if (token != null) {
      saveTokenToFirestore(token);
    }
  }

  Future<void> saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous) {
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        if (kDebugMode) {
          print('FCM Token synced to Firestore for: ${user.uid}');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Firestore token sync error: $e');
        }
      }
    }
  }

  Future<void> _handleMessageData(Map<String, dynamic> data) async {
    if (kDebugMode) print('Handling notification logic: $data');

    final String? screen = data['screen'];
    final String? id = data['id'];

    if (screen == 'university' && id != null) {
      final university = await UniversityService().getUniversityById(id);

      if (university != null && _navigatorKey?.currentState != null) {
        _navigatorKey?.currentState?.push(
          MaterialPageRoute(
            builder: (context) =>
                UniversityDetailScreen(university: university),
          ),
        );
      }
    }
  }

  Future<String?> getToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      return null;
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      platformDetails,
      payload: jsonEncode(message.data),
    );
  }

  /// Get notifications stream for current user
  Stream<List<AppNotification>> getNotificationsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('time', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return AppNotification.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  /// Clear all notifications (handles Firestore batch limit of 500)
  Future<void> clearAllNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final collectionRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications');

    // Delete in chunks of 500 (Firestore batch limit)
    QuerySnapshot snapshot;
    do {
      snapshot = await collectionRef.limit(500).get();
      if (snapshot.docs.isEmpty) break;

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } while (snapshot.docs.length == 500);
  }

  /// Save incoming FCM notification to Firestore
  Future<void> _saveNotificationToFirestore(RemoteMessage message) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return;

    if (message.notification == null) return;

    try {
      final notification = AppNotification(
        id: '', // Will be generated by Firestore
        title: message.notification!.title ?? 'Уведомление',
        message: message.notification!.body ?? '',
        time: DateTime.now(),
        type: _parseNotificationType(message.data['type']),
        isRead: false,
        data: message.data,
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .add(notification.toMap());
    } catch (e) {
      if (kDebugMode) {
        print('Error saving notification to Firestore: $e');
      }
    }
  }

  NotificationType _parseNotificationType(String? typeStr) {
    if (typeStr == null) return NotificationType.news;
    return NotificationType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => NotificationType.news,
    );
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('Background message received: ${message.messageId}');
  }
}
