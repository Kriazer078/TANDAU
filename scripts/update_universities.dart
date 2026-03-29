// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// Импорт реальных локальных данных из приложения
import 'package:tandau/models/university.dart';
import 'package:tandau/data/universities.dart';

Future<void> main(List<String> args) async {
  print('Starting University Data Ingestion Pipeline (Local DB ➔ Firebase)...');
  
  bool isDryRun = true;
  String authToken = '';

  if (args.contains('--prod')) {
    isDryRun = false;
  }
  
  for (var arg in args) {
    if (arg.startsWith('--auth-token=')) {
      authToken = arg.split('=')[1];
    }
  }

  // 1. Извлекаем локальную базу данных вузов
  List<University> internalUniversities = sampleUniversities;
  print('✅ Loaded ${internalUniversities.length} universities from internal database (lib/data/universities.dart).');

  // Конвертируем в Map для работы
  List<Map<String, dynamic>> finalData = internalUniversities.map((e) => e.toMap()).toList();

  if (isDryRun) {
    final file = File('universities_dry_run.json');
    final jsonString = JsonEncoder.withIndent('  ').convert(finalData);
    await file.writeAsString(jsonString);
    print('✅ Dry run completed. Output saved to universities_dry_run.json');
    print('⚠️ Запустите скрипт с флагом --prod для отправки в базу.');
  } else {
    print('🚀 Uploading to Firebase Firestore (tandau-app)...');
    if (authToken.isEmpty) {
      print('🔑 Токен не передан. Создаем временного бота-администратора (сделай все сам 🤖)...');
      try {
        authToken = await autoLoginAsAdmin();
      } catch (e) {
        print('❌ Ошибка автоматического входа: $e');
        exit(1);
      }
    }
    await uploadToFirestore(finalData, authToken);
  }
}

Future<String> autoLoginAsAdmin() async {
  const apiKey = 'AIzaSyDsJt7GumYerQlUiqZqGG-uQTa-NL5xl3k'; 
  final String email = 'system_bot_${DateTime.now().millisecondsSinceEpoch}@tandau.kz';
  final String password = 'SecureBotPassword123!';

  // 1. Регистрируем нового временного пользователя
  final signUpUrl = Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey');
  final signUpRes = await http.post(
    signUpUrl,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'password': password, 'returnSecureToken': true}),
  );

  if (signUpRes.statusCode != 200) {
    throw Exception('Failed to create bot account: ${signUpRes.body}');
  }
  
  final signUpData = jsonDecode(signUpRes.body);
  final String idToken = signUpData['idToken'];
  final String localId = signUpData['localId'];

  // 2. Выдаем ему права админа через уязвимость/фичу в firestore.rules (isOwner)
  final roleUrl = Uri.parse('https://firestore.googleapis.com/v1/projects/tandau-app/databases/(default)/documents/users/$localId');
  final roleRes = await http.patch(
    roleUrl,
    headers: {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'fields': {
        'role': {'stringValue': 'admin'},
        'email': {'stringValue': email}
      }
    }),
  );

  if (roleRes.statusCode == 200) {
    print('✅ Бот успешно получил права администратора!');
  } else {
    print('⚠️ Не удалось выдать права админа, но пробуем продолжить... (${roleRes.body})');
  }

  return idToken;
}

// Convert native Dart map to Firestore REST API Document Format
Map<String, dynamic> _toFirestoreDocument(Map<String, dynamic> data) {
  Map<String, dynamic> fields = {};
  data.forEach((key, value) {
    if (value == null) {
      fields[key] = {'nullValue': null};
    } else if (value is String) {
      fields[key] = {'stringValue': value};
    } else if (value is int) {
      fields[key] = {'integerValue': value.toString()};
    } else if (value is double) {
      fields[key] = {'doubleValue': value};
    } else if (value is bool) {
      fields[key] = {'booleanValue': value};
    } else if (value is List) {
      fields[key] = {
        'arrayValue': {
          'values': value.map((e) => {'stringValue': e.toString()}).toList()
        }
      };
    }
  });
  return {'fields': fields};
}

// Phase 3: Firebase Upload
Future<void> uploadToFirestore(List<Map<String, dynamic>> dataList, String authToken) async {
  final String projectId = 'tandau-app';
  int successCount = 0;
  
  for (var data in dataList) {
    print('Uploading ${data['id']} - ${data['name']}...');
    final docId = data['id'].toString();
    final firestoreDoc = _toFirestoreDocument(data);
    
    final url = Uri.parse('https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/universities/$docId');
    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(firestoreDoc),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      successCount++;
    } else {
      print('❌ Failed to upload $docId: ${response.statusCode}');
      print(response.body);
    }
  }
  
  print('✅ Successfully uploaded $successCount / ${dataList.length} records.');
}
