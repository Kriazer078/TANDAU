import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/university.dart';
import '../models/specialty.dart';

class FirestoreService {
  // Singleton instance
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get universitiesCollection =>
      _firestore.collection('universities');
  CollectionReference get usersCollection => _firestore.collection('users');

  /// Get all universities from Firestore
  Future<List<University>> getAllUniversities() async {
    try {
      final snapshot = await universitiesCollection.get().timeout(
        const Duration(seconds: 15),
      );
      return snapshot.docs
          .map((doc) => University.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting universities: $e');
      return [];
    }
  }

  /// Get universities stream (real-time updates)
  Stream<List<University>> getUniversitiesStream() {
    return universitiesCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => University.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  /// Get university by ID
  Future<University?> getUniversityById(String id) async {
    try {
      final doc = await universitiesCollection.doc(id).get();
      if (doc.exists) {
        return University.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting university: $e');
      return null;
    }
  }

  /// Add university to Firestore
  Future<bool> addUniversity(University university) async {
    try {
      await universitiesCollection.doc(university.id).set(university.toMap());
      return true;
    } catch (e) {
      debugPrint('Error adding university: $e');
      return false;
    }
  }

  /// Update university in Firestore
  Future<bool> updateUniversity(University university) async {
    try {
      await universitiesCollection
          .doc(university.id)
          .update(university.toMap());
      return true;
    } catch (e) {
      debugPrint('Error updating university: $e');
      return false;
    }
  }

  /// Delete university from Firestore
  Future<bool> deleteUniversity(String id) async {
    try {
      await universitiesCollection.doc(id).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting university: $e');
      return false;
    }
  }

  /// Search universities by name or city
  Future<List<University>> searchUniversities(String query) async {
    try {
      final snapshot = await universitiesCollection.get();
      final allUniversities = snapshot.docs
          .map((doc) => University.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      return allUniversities.where((uni) => uni.matchesSearch(query)).toList();
    } catch (e) {
      debugPrint('Error searching universities: $e');
      return [];
    }
  }

  /// Filter universities by city
  Future<List<University>> getUniversitiesByCity(String city) async {
    try {
      final snapshot = await universitiesCollection
          .where('city', isEqualTo: city)
          .get();
      return snapshot.docs
          .map((doc) => University.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error filtering universities by city: $e');
      return [];
    }
  }

  /// Get universities with grants
  Future<List<University>> getUniversitiesWithGrants() async {
    try {
      final snapshot = await universitiesCollection
          .where('hasGrants', isEqualTo: true)
          .get();
      return snapshot.docs
          .map((doc) => University.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting universities with grants: $e');
      return [];
    }
  }

  /// Get universities with dormitory
  Future<List<University>> getUniversitiesWithDormitory() async {
    try {
      final snapshot = await universitiesCollection
          .where('hasDormitory', isEqualTo: true)
          .get();
      return snapshot.docs
          .map((doc) => University.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting universities with dormitory: $e');
      return [];
    }
  }

  /// Batch upload universities (for initial data migration)
  Future<bool> batchUploadUniversities(List<University> universities) async {
    try {
      final batch = _firestore.batch();

      for (var university in universities) {
        final docRef = universitiesCollection.doc(university.id);
        batch.set(docRef, university.toMap());
      }

      await batch.commit();
      debugPrint('Successfully uploaded ${universities.length} universities');
      return true;
    } catch (e) {
      debugPrint('Error batch uploading universities: $e');
      return false;
    }
  }

  /// Get unique cities from Firestore
  Future<List<String>> getUniqueCities() async {
    try {
      final snapshot = await universitiesCollection.get().timeout(
        const Duration(seconds: 15),
      );
      final cities = snapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['city'] as String)
          .toSet()
          .toList();
      cities.sort();
      return cities;
    } catch (e) {
      debugPrint('Error getting unique cities: $e');
      return [];
    }
  }

  /// Get unique majors from Firestore
  Future<List<String>> getUniqueMajors() async {
    try {
      final snapshot = await universitiesCollection.get().timeout(
        const Duration(seconds: 15),
      );
      final majors = <String>{};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final universityMajors = List<String>.from(data['majors'] ?? []);
        majors.addAll(universityMajors);
      }

      final majorsList = majors.toList();
      majorsList.sort();
      return majorsList;
    } catch (e) {
      debugPrint('Error getting unique majors: $e');
      return [];
    }
  }

  // --- SPECIALTIES CURRENTLY ADDED:
  /// Get specialties for a university
  Stream<List<Specialty>> getSpecialties(String universityId) {
    return _firestore
        .collection('universities')
        .doc(universityId)
        .collection('specialties')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Specialty.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }
}
