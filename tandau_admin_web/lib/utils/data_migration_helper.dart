import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/university_service.dart';
import '../services/firestore_service.dart';
import '../models/university.dart';
import '../data/universities.dart';
import 'firestore_upload_script.dart';

/// Utility class for migrating data to Firestore.
///
/// Supports:
/// - Full migration from hardcoded list
/// - JSON file import (from Google Sheets → CSV → JSON pipeline)
/// - Partial updates (merge mode — preserves likes/reviews)
/// - Data quality validation
class DataMigrationHelper {
  final UniversityService _universityService = UniversityService();
  final FirestoreService _firestoreService = FirestoreService();

  /// Migrate all local university data to Firestore
  /// This will OVERWRITE existing data with fresh data from universities.dart
  Future<bool> migrateUniversitiesToFirestore({
    bool forceOverwrite = false,
  }) async {
    try {
      debugPrint('Starting university data migration to Firestore...');

      // Check if universities already exist in Firestore
      final existingUniversities = await _firestoreService.getAllUniversities();

      if (existingUniversities.isNotEmpty && !forceOverwrite) {
        debugPrint(
          'Universities already exist in Firestore '
          '(${existingUniversities.length} found)',
        );
        debugPrint('Use forceOverwrite=true to replace existing data.');
        return true;
      }

      if (forceOverwrite && existingUniversities.isNotEmpty) {
        debugPrint(
          '⚠️ Force overwrite: clearing ${existingUniversities.length} '
          'existing universities...',
        );
        await clearUniversitiesFromFirestore();
      }

      // Migrate universities
      final success = await _universityService.migrateToFirestore(
        universitiesList,
      );

      if (success) {
        debugPrint(
          '✅ Successfully migrated ${universitiesList.length} '
          'universities to Firestore',
        );
        return true;
      } else {
        debugPrint('❌ Failed to migrate universities to Firestore');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error during migration: $e');
      return false;
    }
  }

  /// Import universities from a JSON file (from CSV→JSON pipeline).
  ///
  /// [jsonPath] — absolute path to JSON file.
  /// [mergeMode] — if true, only updates non-empty fields,
  ///               preserving existing likes/reviews/ratings.
  Future<bool> importFromJson({
    required String jsonPath,
    bool mergeMode = true,
  }) async {
    try {
      debugPrint('📂 Importing universities from: $jsonPath');

      final File file = File(jsonPath);
      if (!file.existsSync()) {
        debugPrint('❌ File not found: $jsonPath');
        return false;
      }

      final String content = file.readAsStringSync(encoding: utf8);
      final List<dynamic> jsonList = jsonDecode(content) as List<dynamic>;

      final List<University> universities = jsonList
          .map((e) => University.fromMap(e as Map<String, dynamic>))
          .toList();

      debugPrint('📋 Loaded ${universities.length} universities from JSON');

      if (mergeMode) {
        // Partial update: only non-empty fields, preserve counters
        return FirestoreUploadScript.partialUpdate(universities);
      } else {
        // Full replace
        return FirestoreUploadScript.uploadFromJsonFile(jsonPath);
      }
    } catch (e, stack) {
      debugPrint('❌ Error importing JSON: $e');
      debugPrint('Stack: $stack');
      return false;
    }
  }

  /// Verify Firestore data integrity and report quality
  Future<void> verifyFirestoreData() async {
    try {
      debugPrint('═══ 📊 Verifying Firestore data... ═══');

      final universities = await _firestoreService.getAllUniversities();
      debugPrint('Total universities in Firestore: ${universities.length}');

      final cities = await _firestoreService.getUniqueCities();
      debugPrint('Unique cities: ${cities.length} — $cities');

      final majors = await _firestoreService.getUniqueMajors();
      debugPrint('Unique majors: ${majors.length}');

      // 📊 Data quality report
      _printDataQuality(universities);

      debugPrint('✅ Firestore data verification complete');
    } catch (e) {
      debugPrint('❌ Error verifying Firestore data: $e');
    }
  }

  /// Print data quality report
  void _printDataQuality(List<University> universities) {
    if (universities.isEmpty) return;

    final int total = universities.length;
    debugPrint('');
    debugPrint('═══ Data Quality Report ═══');

    // Check string fields
    final Map<String, int> filledCounts = {
      'name': 0,
      'city': 0,
      'website': 0,
      'email': 0,
      'contactPhone': 0,
      'address': 0,
      'tuitionRange': 0,
      'logoUrl': 0,
      'description': 0,
    };

    int withMajors = 0;
    int withSpecialtyCodes = 0;
    int withDormitory = 0;
    int withGrants = 0;

    for (final uni in universities) {
      if (uni.name.isNotEmpty) filledCounts['name'] = filledCounts['name']! + 1;
      if (uni.city.isNotEmpty) filledCounts['city'] = filledCounts['city']! + 1;
      if (uni.website.isNotEmpty) {
        filledCounts['website'] = filledCounts['website']! + 1;
      }
      if (uni.email.isNotEmpty) {
        filledCounts['email'] = filledCounts['email']! + 1;
      }
      if (uni.contactPhone.isNotEmpty) {
        filledCounts['contactPhone'] = filledCounts['contactPhone']! + 1;
      }
      if (uni.address.isNotEmpty) {
        filledCounts['address'] = filledCounts['address']! + 1;
      }
      if (uni.tuitionRange.isNotEmpty) {
        filledCounts['tuitionRange'] = filledCounts['tuitionRange']! + 1;
      }
      if (uni.logoUrl.isNotEmpty) {
        filledCounts['logoUrl'] = filledCounts['logoUrl']! + 1;
      }
      if (uni.description.isNotEmpty &&
          !uni.description.contains('Официальные данные eGov')) {
        filledCounts['description'] = filledCounts['description']! + 1;
      }
      if (uni.majors.isNotEmpty) withMajors++;
      if (uni.specialtyCodes.isNotEmpty) withSpecialtyCodes++;
      if (uni.hasDormitory) withDormitory++;
      if (uni.hasGrants) withGrants++;
    }

    filledCounts.forEach((field, fieldCount) {
      final int percent = (fieldCount * 100 / total).round();
      final String icon = percent == 100 ? '✅' : (percent > 50 ? '🟡' : '❌');
      debugPrint('  $icon $field: $fieldCount/$total ($percent%)');
    });

    debugPrint('  📋 majors: $withMajors/$total');
    debugPrint('  🎯 specialtyCodes: $withSpecialtyCodes/$total');
    debugPrint('  🏠 hasDormitory: $withDormitory/$total');
    debugPrint('  🎓 hasGrants: $withGrants/$total');
  }

  /// Clear all universities from Firestore (use with caution!)
  Future<bool> clearUniversitiesFromFirestore() async {
    try {
      debugPrint('⚠️ Clearing all universities from Firestore...');

      final universities = await _firestoreService.getAllUniversities();

      for (var university in universities) {
        await _firestoreService.deleteUniversity(university.id);
      }

      debugPrint(
        '✅ Cleared ${universities.length} universities from Firestore',
      );
      return true;
    } catch (e) {
      debugPrint('❌ Error clearing Firestore: $e');
      return false;
    }
  }

  /// 🔄 Синхронизация метаданных (города и специальности) из всех университетов
  Future<void> syncMetadata() async {
    try {
      debugPrint('🔄 Starting metadata sync...');
      final snapshot = await FirebaseFirestore.instance
          .collection('universities')
          .get();

      final Set<String> cities = {};
      final Set<String> majors = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final city = data['city'] as String?;
        if (city != null && city.isNotEmpty) cities.add(city);

        final majorList = data['majors'] as List<dynamic>?;
        if (majorList != null) {
          for (var m in majorList) {
            if (m is String && m.isNotEmpty) majors.add(m);
          }
        }
      }

      await FirebaseFirestore.instance.collection('stats').doc('metadata').set({
        'uniqueCities': cities.toList()..sort(),
        'uniqueMajors': majors.toList()..sort(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'totalUniversities': snapshot.docs.length,
      }, SetOptions(merge: true));

      debugPrint(
        '✅ Metadata synced: ${cities.length} cities, ${majors.length} majors',
      );
    } catch (e) {
      debugPrint('❌ Error syncing metadata: $e');
    }
  }
}
