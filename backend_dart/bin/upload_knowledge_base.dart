// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:googleapis_auth/auth_io.dart';

/// Upload ALL seed data to Firestore knowledge_base collection
/// Uploads: knowledge_base_seed.json + success_stories_seed.json
/// Run from backend_dart/: dart run bin/upload_knowledge_base.dart
void main() async {
  print('📚 Uploading Knowledge Base to Firestore...');

  final env = DotEnv(includePlatformEnvironment: true);
  if (File('.env').existsSync()) {
    env.load();
  }

  final projectId = env['FIREBASE_PROJECT_ID'] ?? 'tandau-app';
  final serviceAccountPath =
      Platform.environment['GOOGLE_APPLICATION_CREDENTIALS'] ??
          'service_account.json';

  if (!File(serviceAccountPath).existsSync()) {
    print('❌ Service account not found: $serviceAccountPath');
    exit(1);
  }

  final accountCredentials = ServiceAccountCredentials.fromJson(
      await File(serviceAccountPath).readAsString());
  final client = await clientViaServiceAccount(
      accountCredentials, [FirestoreApi.datastoreScope]);
  final firestoreApi = FirestoreApi(client);
  final parent = 'projects/$projectId/databases/(default)/documents';

  // Upload all seed files
  final seedFiles = [
    'data/knowledge_base_seed.json',
    'data/success_stories_seed.json',
  ];

  int totalOk = 0;
  int totalFiles = 0;

  for (final path in seedFiles) {
    final file = File(path);
    if (!file.existsSync()) {
      print('⚠️  Skipping $path (not found)');
      continue;
    }

    print('\n📁 Processing: $path');
    final Map<String, dynamic> data = jsonDecode(await file.readAsString());
    totalFiles += data.length;

    for (final entry in data.entries) {
      final docId = entry.key;
      final Map<String, dynamic> docData = entry.value;

      final fields = <String, Value>{};
      docData.forEach((key, val) {
        if (val is String) fields[key] = Value(stringValue: val);
      });

      try {
        await firestoreApi.projects.databases.documents.createDocument(
          Document(fields: fields),
          parent,
          'knowledge_base',
          documentId: docId,
        );
        totalOk++;
        print('  ✅ $docId');
      } catch (e) {
        if (e.toString().contains('ALREADY_EXISTS')) {
          await firestoreApi.projects.databases.documents.patch(
            Document(name: '$parent/knowledge_base/$docId', fields: fields),
            '$parent/knowledge_base/$docId',
          );
          totalOk++;
          print('  🔄 $docId (updated)');
        } else {
          print('  ❌ $docId: $e');
        }
      }
    }
  }

  print('\n📊 $totalOk/$totalFiles documents uploaded');
  client.close();
  exit(0);
}
