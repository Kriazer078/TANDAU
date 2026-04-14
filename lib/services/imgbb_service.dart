import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Сервис для загрузки изображений на ImgBB
/// Используется для хранения аватарок, фото достижений и документов.
class ImgBBService {
  static final ImgBBService _instance = ImgBBService._internal();
  factory ImgBBService() => _instance;
  ImgBBService._internal();

  // API ключ. Рекомендуется передавать через --dart-define=IMGBB_API_KEY=xxx
  // В качестве значения по умолчанию установлен предоставленный ключ.
  static const String _apiKey = String.fromEnvironment(
    'IMGBB_API_KEY',
    defaultValue: '8a07e48010c273a5927e5d6602a28138',
  );

  static const String _uploadUrl = 'https://api.imgbb.com/1/upload';

  /// Загрузка изображения по файлу
  /// Возвращает прямой URL на изображение или null при ошибке
  Future<String?> uploadImage(File imageFile) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      request.fields['key'] = _apiKey;
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Возвращаем прямой URL (display_url или url)
        return data['data']['url'] as String?;
      } else {
        debugPrint('ImgBB upload error: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('ImgBB Service Exception: $e');
      return null;
    }
  }

  /// Загрузка изображения в base64 (если файл недоступен напрямую)
  Future<String?> uploadBase64(String base64Image) async {
    try {
      final response = await http.post(
        Uri.parse(_uploadUrl),
        body: {
          'key': _apiKey,
          'image': base64Image,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['url'] as String?;
      } else {
        debugPrint('ImgBB base64 upload error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('ImgBB Service Exception: $e');
      return null;
    }
  }
}
