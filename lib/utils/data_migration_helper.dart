import 'package:flutter/material.dart';
import '../services/university_service.dart';
import '../services/firestore_service.dart';
import '../data/universities.dart';

/// Utility class for migrating data to Firestore
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

  /// Verify Firestore data integrity
  Future<void> verifyFirestoreData() async {
    try {
      debugPrint('Verifying Firestore data...');

      final universities = await _firestoreService.getAllUniversities();
      debugPrint('Total universities in Firestore: ${universities.length}');

      final cities = await _firestoreService.getUniqueCities();
      debugPrint('Unique cities: ${cities.length} — $cities');

      final majors = await _firestoreService.getUniqueMajors();
      debugPrint('Unique majors: ${majors.length}');

      debugPrint('✅ Firestore data verification complete');
    } catch (e) {
      debugPrint('❌ Error verifying Firestore data: $e');
    }
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
}
