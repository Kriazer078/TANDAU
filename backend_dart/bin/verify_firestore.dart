// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:googleapis/firestore/v1.dart';
import 'package:googleapis_auth/auth_io.dart';

/// Quick verify: check how many docs exist in knowledge_base
Future<void> main() async {
  final projectId =
      Platform.environment['FIREBASE_PROJECT_ID'] ?? _loadProjectIdFromEnv();

  print('🔍 Verifying Firestore data for project: $projectId\n');

  final credPath = Platform.environment['GOOGLE_APPLICATION_CREDENTIALS'] ??
      'service_account.json';
  final credFile = File(credPath);

  if (!credFile.existsSync()) {
    print('❌ Service account file not found: $credPath');
    exit(1);
  }

  final cred = json.decode(credFile.readAsStringSync());
  final accountCredentials = ServiceAccountCredentials.fromJson(cred);
  final client = await clientViaServiceAccount(
    accountCredentials,
    [FirestoreApi.datastoreScope],
  );

  try {
    final firestore = FirestoreApi(client);
    final parent = 'projects/$projectId/databases/(default)/documents';

    // List knowledge_base documents
    print('📚 Collection: knowledge_base');
    print('─' * 50);

    final result = await firestore.projects.databases.documents.list(
      parent,
      'knowledge_base',
      pageSize: 50,
    );

    if (result.documents != null && result.documents!.isNotEmpty) {
      int total = result.documents!.length;
      int stories = 0;
      int knowledge = 0;

      for (final doc in result.documents!) {
        final name = doc.name!.split('/').last;
        final category = doc.fields?['category']?.stringValue ?? '?';
        final title = doc.fields?['title']?.stringValue ?? 'N/A';

        if (category == 'success_story') {
          stories++;
        } else {
          knowledge++;
        }
        print('  ✅ $name ($category) — $title');
      }

      print('\n─' * 50);
      print('📊 Total: $total documents');
      print('   📖 Success Stories: $stories');
      print('   📝 Knowledge Base: $knowledge');
    } else {
      print('  ⚠️  No documents found!');
    }

    // Also check users collection
    print('\n👤 Collection: users');
    print('─' * 50);
    final users = await firestore.projects.databases.documents.list(
      parent,
      'users',
      pageSize: 5,
    );
    if (users.documents != null) {
      print('  ✅ ${users.documents!.length} user(s) found');
    } else {
      print('  ⚠️  No users found');
    }
  } finally {
    client.close();
  }

  print('\n✅ Verification complete!');
}

String _loadProjectIdFromEnv() {
  final envFile = File('.env');
  if (envFile.existsSync()) {
    for (final line in envFile.readAsLinesSync()) {
      if (line.startsWith('FIREBASE_PROJECT_ID=')) {
        return line.split('=').skip(1).join('=').trim();
      }
    }
  }
  return 'tandau-app'; // fallback
}
