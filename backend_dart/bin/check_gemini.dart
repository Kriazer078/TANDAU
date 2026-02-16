// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dotenv/dotenv.dart';

void main() async {
  var env = DotEnv(includePlatformEnvironment: true)..load();
  final apiKey = env['GEMINI_API_KEY'];

  if (apiKey == null) {
    print('No API Key found in .env');
    return;
  }

  print('Using API Key: ${apiKey.substring(0, 5)}...');
  print('Checking available models...');

  final url =
      'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey';

  try {
    final response = await http.get(Uri.parse(url));
    print('Response Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final models = (json['models'] as List).map((m) => m['name']).toList();
      print('Available Models:');
      for (var model in models) {
        print(' - $model');
      }
    } else {
      print('Error Body: ${response.body}');
    }
  } catch (e) {
    print('Connection Error: $e');
  }
}
