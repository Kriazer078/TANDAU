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
  final CollectionReference universitiesCollection =
      FirebaseFirestore.instance.collection('universities');
  CollectionReference get usersCollection => _firestore.collection('users');

  // ═══ Кэширование перенесено в UniversityService (единая точка) ═══

  /// Устарело — кэш больше не хранится здесь.
  /// Оставлено для обратной совместимости.
  void refreshCache() {
    // Кэширование теперь в UniversityService
  }

  /// Get all universities from Firestore (без кэша — кэш в UniversityService)
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

  /// ⚠️ Удаление ВСЕХ университетов и их специальностей (Только для Админа)
  Future<bool> deleteAllUniversities() async {
    try {
      final snapshot = await universitiesCollection.get();
      
      // В Firestore батчи лимитированы до 500 операций.
      // Если вузов и специальностей много, нужно разбивать на чанки.
      // Для начала делаем просто батчем, если операций < 500.
      // Простой и надежный метод для Flutter - удаление каждого документа и подколлекции по очереди
      // Но оптимизировано через батчи там, где это возможно.
      
      int operationCount = 0;
      WriteBatch batch = _firestore.batch();
      
      for (var doc in snapshot.docs) {
        final specsSnapshot = await doc.reference.collection('specialties').get();
        
        for (var specDoc in specsSnapshot.docs) {
          batch.delete(specDoc.reference);
          operationCount++;
          
          if (operationCount >= 490) {
            await batch.commit();
            batch = _firestore.batch();
            operationCount = 0;
          }
        }
        
        batch.delete(doc.reference);
        operationCount++;
        
        if (operationCount >= 490) {
          await batch.commit();
          batch = _firestore.batch();
          operationCount = 0;
        }
      }
      
      if (operationCount > 0) {
        await batch.commit();
      }
      
      debugPrint('Successfully deleted all universities and their specialties');
      return true;
    } catch (e) {
      debugPrint('Error deleting all universities: $e');
      return false;
    }
  }

  /// Загрузка университета вместе с его специальностями в рамках одной транзакции/батча
  Future<bool> uploadUniversityWithSpecialties(University university, List<Specialty> specialties) async {
    try {
      final batch = _firestore.batch();
      
      // Назначаем ID универу, если он пустой
      final docRef = university.id.isEmpty 
          ? universitiesCollection.doc() 
          : universitiesCollection.doc(university.id);
          
      // Если ID был пустой, обновим объект (хотя в метод передается модель, id желательно чтобы был установлен)
      
      batch.set(docRef, university.toMap());
      
      for (var spec in specialties) {
        final specRef = (spec.id.isEmpty)
            ? docRef.collection('specialties').doc()
            : docRef.collection('specialties').doc(spec.id);
        batch.set(specRef, spec.toMap());
      }
      
      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error uploading university with specialties: $e');
      return false;
    }
  }

  /// Search universities by name or city (uses cached data)
  Future<List<University>> searchUniversities(String query) async {
    try {
      final allUniversities = await getAllUniversities();
      return allUniversities.where((uni) => uni.matchesSearch(query)).toList();
    } catch (e) {
      debugPrint('Error searching universities: $e');
      return [];
    }
  }

  /// Filter universities by city
  Future<List<University>> getUniversitiesByCity(String city) async {
    try {
      final snapshot =
          await universitiesCollection.where('city', isEqualTo: city).get();
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

  /// Sync unique cities and majors to stats/metadata (Admin only or Cloud Function replacement)
  Future<bool> syncAggregationMetadata() async {
    try {
      final snapshot = await universitiesCollection.get();
      final cities = <String>{};
      final majors = <String>{};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['city'] != null) cities.add(data['city'] as String);
        if (data['majors'] != null) {
          majors.addAll(List<String>.from(data['majors']));
        }
      }

      final citiesList = cities.toList()..sort();
      final majorsList = majors.toList()..sort();

      await _firestore.collection('stats').doc('metadata').set({
        'uniqueCities': citiesList,
        'uniqueMajors': majorsList,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('Metadata synced successfully');
      return true;
    } catch (e) {
      debugPrint('Error syncing metadata: $e');
      return false;
    }
  }

  /// Get unique cities from Firestore (Optimized: reads from stats/metadata)
  Future<List<String>> getUniqueCities() async {
    try {
      final doc = await _firestore.collection('stats').doc('metadata').get();
      if (doc.exists && doc.data()!.containsKey('uniqueCities')) {
        final List<dynamic> cities = doc.data()!['uniqueCities'];
        return cities.map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting unique cities: $e');
      return [];
    }
  }

  /// Get unique majors from Firestore (Optimized: reads from stats/metadata)
  Future<List<String>> getUniqueMajors() async {
    try {
      final doc = await _firestore.collection('stats').doc('metadata').get();
      if (doc.exists && doc.data()!.containsKey('uniqueMajors')) {
        final List<dynamic> majors = doc.data()!['uniqueMajors'];
        return majors.map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting unique majors: $e');
      return [];
    }
  }

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
