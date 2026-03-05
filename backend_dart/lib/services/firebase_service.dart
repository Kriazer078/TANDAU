import 'dart:io';
import 'package:googleapis/firestore/v1.dart';
import 'package:googleapis/fcm/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import '../models/university.dart';
import 'cache_service.dart';

class FirebaseService {
  late FirestoreApi _firestoreApi;
  late FirebaseCloudMessagingApi _fcmApi;
  final String _projectId;
  CacheService? _cacheService;

  /// Cache TTL for university data (5 minutes)
  static const Duration _universitiesCacheTtl = Duration(minutes: 5);
  static const String _universitiesCacheKey = 'universities';

  FirebaseService(this._projectId);

  /// Set cache service (optional, set from server.dart)
  void setCacheService(CacheService cache) {
    _cacheService = cache;
  }

  /// Expose FirestoreApi for other services
  FirestoreApi get firestoreApi => _firestoreApi;

  Future<void> init() async {
    // Path to your service account key file.
    // Ensure you download this from Firebase Console: Project Settings -> Service Accounts -> Generate new private key
    final serviceAccountPath =
        Platform.environment['GOOGLE_APPLICATION_CREDENTIALS'] ??
            'service_account.json';

    if (!File(serviceAccountPath).existsSync()) {
      var client = await clientViaApplicationDefaultCredentials(scopes: [
        FirestoreApi.datastoreScope,
        FirebaseCloudMessagingApi.firebaseMessagingScope
      ]);
      _firestoreApi = FirestoreApi(client);
      _fcmApi = FirebaseCloudMessagingApi(client);
    } else {
      final accountCredentials = ServiceAccountCredentials.fromJson(
          await File(serviceAccountPath).readAsString());

      final client = await clientViaServiceAccount(accountCredentials, [
        FirestoreApi.datastoreScope,
        FirebaseCloudMessagingApi.firebaseMessagingScope
      ]);
      _firestoreApi = FirestoreApi(client);
      _fcmApi = FirebaseCloudMessagingApi(client);
    }
  }

  Future<List<University>> getUniversities() async {
    // 📦 Check cache first
    if (_cacheService != null) {
      final cached =
          _cacheService!.get<List<University>>(_universitiesCacheKey);
      if (cached != null) {
        stderr.writeln('📦 [CACHE HIT] universities (${cached.length} items)');
        return cached;
      }
    }

    final parent = 'projects/$_projectId/databases/(default)/documents';

    try {
      // List documents in 'universities' collection
      final response = await _firestoreApi.projects.databases.documents
          .list(parent, 'universities', pageSize: 100);

      if (response.documents == null) return [];

      final universities = response.documents!.map((doc) {
        final fields = doc.fields!;
        final id = doc.name!.split('/').last;

        // Helper to extract value from Firestore Value object
        dynamic getValue(Value v) {
          if (v.stringValue != null) return v.stringValue;
          if (v.integerValue != null) return int.tryParse(v.integerValue!) ?? 0;
          if (v.doubleValue != null) return v.doubleValue;
          if (v.booleanValue != null) return v.booleanValue;
          if (v.arrayValue != null) {
            return v.arrayValue!.values?.map((e) => getValue(e)).toList() ?? [];
          }
          if (v.mapValue != null) {
            final map = <String, dynamic>{};
            v.mapValue!.fields?.forEach((key, val) {
              map[key] = getValue(val);
            });
            return map;
          }
          return null;
        }

        Map<String, dynamic> json = {};
        fields.forEach((key, value) {
          json[key] = getValue(value);
        });

        // Handle some field name mapping if necessary, or rely on model.
        // Ensure array conversion
        if (json['subjects'] is! List) json['subjects'] = [];

        return University.fromJson(json, id);
      }).toList();

      // 📦 Store in cache
      if (_cacheService != null) {
        _cacheService!
            .set(_universitiesCacheKey, universities, _universitiesCacheTtl);
        stderr.writeln(
            '📦 [CACHE SET] universities (${universities.length} items, TTL: $_universitiesCacheTtl)');
      }

      return universities;
    } catch (e) {
      stderr.writeln('Error fetching universities: $e');
      return [];
    }
  }

  Future<String?> getUserToken(String uid) async {
    final name =
        'projects/$_projectId/databases/(default)/documents/users/$uid';
    try {
      final doc = await _firestoreApi.projects.databases.documents.get(name);
      if (doc.fields != null && doc.fields!.containsKey('fcmToken')) {
        return doc.fields!['fcmToken']?.stringValue;
      }
      return null;
    } catch (e) {
      // stderr.writeln('Error fetching token for $uid: $e');
      return null;
    }
  }

  Future<List<String>> getAllUserTokens() async {
    final parent = 'projects/$_projectId/databases/(default)/documents';
    try {
      final response = await _firestoreApi.projects.databases.documents
          .list(parent, 'users', pageSize: 1000); // Pagination needed for >1000

      if (response.documents == null) return [];

      List<String> tokens = [];
      for (var doc in response.documents!) {
        if (doc.fields != null && doc.fields!.containsKey('fcmToken')) {
          final tokenVal = doc.fields!['fcmToken']?.stringValue;
          if (tokenVal != null && tokenVal.isNotEmpty) {
            tokens.add(tokenVal);
          }
        }
      }
      return tokens;
    } catch (e) {
      stderr.writeln('Error fetching user tokens: $e');
      return [];
    }
  }

  Future<void> sendMulticastNotification(
      List<String> tokens, String title, String body,
      {Map<String, String>? data}) async {
    // Note: FCM v1 API doesn't support multicast directly like legacy API.
    // We must send individually or use topics. For simplicity/reliability in this small scale, loop.
    // Better: use batch API if available, or just async parallel.

    for (var token in tokens) {
      await sendNotification(token, title, body, data: data);
    }
  }

  Future<bool> sendNotification(String token, String title, String body,
      {Map<String, String>? data}) async {
    try {
      final message = Message(
        token: token,
        notification: Notification(
          title: title,
          body: body,
        ),
        data: data,
      );

      final request = SendMessageRequest(message: message);
      final parent = 'projects/$_projectId';

      await _fcmApi.projects.messages.send(request, parent);
      return true;
    } catch (e) {
      stderr.writeln('Error sending notification to $token: $e');
      return false;
    }
  }

  /// Get user document by UID
  Future<Map<String, dynamic>?> getUserDocument(String uid) async {
    final name =
        'projects/$_projectId/databases/(default)/documents/users/$uid';
    try {
      final doc = await _firestoreApi.projects.databases.documents.get(name);

      if (doc.fields == null) return null;

      // Extract map
      dynamic getValue(Value v) {
        if (v.stringValue != null) return v.stringValue;
        if (v.integerValue != null) return int.tryParse(v.integerValue!) ?? 0;
        if (v.doubleValue != null) return v.doubleValue;
        if (v.booleanValue != null) return v.booleanValue;
        if (v.timestampValue != null) return v.timestampValue;
        return null; // Simplified for this case
      }

      Map<String, dynamic> userMap = {};
      doc.fields!.forEach((key, val) {
        userMap[key] = getValue(val);
      });
      return userMap;
    } catch (e) {
      // If document not found (404), return null instead of throwing
      if (e.toString().contains('NOT_FOUND')) return null;
      stderr.writeln('Error fetching user $uid: $e');
      return null;
    }
  }

  /// Update user fields (e.g. decrement tokens)
  Future<bool> updateUserFields(
      String uid, Map<String, dynamic> fieldsToUpdate) async {
    final name =
        'projects/$_projectId/databases/(default)/documents/users/$uid';
    try {
      // Construct fields object
      final fields = <String, Value>{};

      fieldsToUpdate.forEach((key, val) {
        if (val is int) {
          fields[key] = Value(integerValue: val.toString());
        } else if (val is String) {
          fields[key] = Value(stringValue: val);
        } else if (val is bool) {
          fields[key] = Value(booleanValue: val);
        } else if (val is DateTime) {
          fields[key] = Value(timestampValue: val.toUtc().toIso8601String());
        }
      });

      final document = Document(name: name, fields: fields);

      await _firestoreApi.projects.databases.documents.patch(document, name,
          updateMask_fieldPaths: fieldsToUpdate.keys.toList());

      return true;
    } catch (e) {
      stderr.writeln('Error updating user $uid: $e');
      return false;
    }
  }

  /// Atomically decrement AI tokens to prevent race conditions
  Future<bool> decrementUserTokens(String uid, [int amount = 1]) async {
    final name =
        'projects/$_projectId/databases/(default)/documents/users/$uid';
    final databasePath = 'projects/$_projectId/databases/(default)';
    try {
      final request = CommitRequest(
        writes: [
          Write(
            transform: DocumentTransform(
              document: name,
              fieldTransforms: [
                FieldTransform(
                  fieldPath: 'aiTokensRemaining',
                  increment: Value(integerValue: (-amount).toString()),
                ),
              ],
            ),
          ),
        ],
      );
      await _firestoreApi.projects.databases.documents
          .commit(request, databasePath);
      return true;
    } catch (e) {
      stderr.writeln('Error decrementing tokens for $uid: $e');
      return false;
    }
  }

  /// Fetch all documents from 'knowledge_base' collection for RAG
  Future<List<Map<String, dynamic>>> getKnowledgeBase() async {
    final parent = 'projects/$_projectId/databases/(default)/documents';
    try {
      final response = await _firestoreApi.projects.databases.documents
          .list(parent, 'knowledge_base', pageSize: 100);

      if (response.documents == null) return [];

      return response.documents!.map((doc) {
        final fields = doc.fields!;
        final id = doc.name!.split('/').last;

        dynamic extractValue(Value v) {
          if (v.stringValue != null) return v.stringValue;
          if (v.integerValue != null) return int.tryParse(v.integerValue!) ?? 0;
          if (v.doubleValue != null) return v.doubleValue;
          if (v.booleanValue != null) return v.booleanValue;
          return null;
        }

        final Map<String, dynamic> result = {'id': id};
        fields.forEach((key, val) {
          result[key] = extractValue(val);
        });
        return result;
      }).toList();
    } catch (e) {
      stderr.writeln('Error fetching knowledge base: $e');
      return [];
    }
  }
}
