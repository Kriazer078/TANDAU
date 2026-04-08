import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../data/universities.dart';
import '../models/university.dart';

/// Script to upload universities to Firestore.
/// Supports both local list and JSON file import.
/// Call [uploadAllUniversities] from admin panel.
class FirestoreUploadScript {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔧 Firestore batch limit = 500 operations
  static const int _batchLimit = 499;

  /// Upload all universities from [universitiesList] to Firestore.
  /// Uses university.toMap() to include ALL fields (contactPhone,
  /// email, specialtyCodes, hasMilitaryDepartment, etc.).
  static Future<bool> uploadAllUniversities() async {
    return _uploadList(universitiesList);
  }

  /// Upload universities from a JSON file path.
  /// JSON should be an array of university objects.
  static Future<bool> uploadFromJsonFile(String jsonPath) async {
    try {
      final File file = File(jsonPath);
      if (!file.existsSync()) {
        debugPrint('❌ JSON file not found: $jsonPath');
        return false;
      }

      final String content = file.readAsStringSync(encoding: utf8);
      final List<dynamic> jsonList = jsonDecode(content) as List<dynamic>;

      final List<University> universities = jsonList
          .map((e) => University.fromMap(e as Map<String, dynamic>))
          .toList();

      debugPrint('📂 Loaded ${universities.length} universities from JSON');
      return _uploadList(universities);
    } catch (e, stack) {
      debugPrint('❌ Error loading JSON: $e');
      debugPrint('Stack: $stack');
      return false;
    }
  }

  /// Internal: upload a list of universities in batches
  static Future<bool> _uploadList(List<University> universities) async {
    try {
      debugPrint(
        '🚀 Starting upload of ${universities.length} universities...',
      );

      // 🔧 Split into batches of 499 (Firestore limit)
      int uploaded = 0;
      for (int i = 0; i < universities.length; i += _batchLimit) {
        final int end = (i + _batchLimit < universities.length)
            ? i + _batchLimit
            : universities.length;
        final List<University> chunk = universities.sublist(i, end);

        final WriteBatch batch = _firestore.batch();

        for (final university in chunk) {
          final DocumentReference docRef = _firestore
              .collection('universities')
              .doc(university.id);

          // 🔧 Используем toMap() — все поля включены автоматически
          batch.set(docRef, university.toMap());
        }

        await batch.commit();
        uploaded += chunk.length;
        debugPrint('  📦 Batch committed: $uploaded/${universities.length}');
      }

      debugPrint(
        '✅ Successfully uploaded ${universities.length} universities!',
      );
      return true;
    } catch (e, stack) {
      debugPrint('❌ Error uploading universities: $e');
      debugPrint('Stack: $stack');
      return false;
    }
  }

  /// Partial update: update only non-empty fields from new data.
  /// Preserves existing values (likesCount, reviewsCount, averageRating).
  static Future<bool> partialUpdate(List<University> updates) async {
    try {
      debugPrint('🔄 Partial update for ${updates.length} universities...');

      int updated = 0;
      for (final university in updates) {
        final Map<String, dynamic> data = {};
        final Map<String, dynamic> full = university.toMap();

        // Only include non-empty / non-default fields
        full.forEach((key, value) {
          // Skip counters that should be preserved
          if (key == 'likesCount' ||
              key == 'reviewsCount' ||
              key == 'averageRating') {
            return;
          }
          if (value == null) return;
          if (value is String && value.isEmpty) return;
          if (value is List && value.isEmpty) return;
          if (value is int && value == 0 && key != 'passingScore') return;

          data[key] = value;
        });

        if (data.isNotEmpty) {
          await _firestore
              .collection('universities')
              .doc(university.id)
              .set(data, SetOptions(merge: true));
          updated++;
        }
      }

      debugPrint('✅ Partially updated $updated universities');
      return true;
    } catch (e, stack) {
      debugPrint('❌ Error in partial update: $e');
      debugPrint('Stack: $stack');
      return false;
    }
  }
}
