import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final apiKey = 'AIzaSyC-AIzaSyAI5nhr9xGwrk4wVyEpgiPXZ4PtOrVVjkU';
  final endpoint = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';
  
  final body = {
    'contents': [{'role': 'user', 'parts': [{'text': 'сколько стоит грант'}]}],
    'tools': [{'googleSearch': {}}]
  };
  
  final response = await http.post(
    Uri.parse('\=\'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(body),
  );
  
  print('Status: \');
  print('Body: \');
}
