import '../models/university.dart';
import '../data/universities.dart';
import 'firestore_service.dart';
import 'auth_service.dart';

class UniversityService {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  // Flag to use Firestore or local data
  bool _useFirestore = true; // ✅ Firestore включен!

  /// Toggle between Firestore and local data
  void setUseFirestore(bool value) {
    _useFirestore = value;
  }

  /// Get all universities
  Future<List<University>> getAllUniversities() async {
    if (_useFirestore) {
      final universities = await _firestoreService.getAllUniversities();
      // If Firestore is empty, return local data as fallback
      return universities.isEmpty ? sampleUniversities : universities;
    }
    return sampleUniversities;
  }

  /// Get universities stream (real-time updates from Firestore)
  Stream<List<University>> getUniversitiesStream() {
    if (_useFirestore) {
      return _firestoreService.getUniversitiesStream();
    }
    // Return a stream with local data
    return Stream.value(sampleUniversities);
  }

  /// Filter universities
  Future<List<University>> filterUniversities({
    List<String>? city,
    List<String>? major,
    List<String>? budget,
    String? searchQuery,
  }) async {
    final allUniversities = await getAllUniversities();

    var filtered = allUniversities.where((uni) {
      return uni.matchesFilters(
        cityFilter: city,
        majorFilter: major,
        budgetFilter: budget,
      );
    }).toList();

    if (searchQuery != null && searchQuery.isNotEmpty) {
      filtered = filtered
          .where((uni) => uni.matchesSearch(searchQuery))
          .toList();
    }

    return filtered;
  }

  /// Get favorite university IDs from AuthService
  List<String> getFavoriteIds() {
    return _authService.getFavoriteIds();
  }

  /// Add to favorites using AuthService
  Future<bool> addToFavorites(String universityId) async {
    return await _authService.addToFavorites(universityId);
  }

  /// Remove from favorites using AuthService
  Future<bool> removeFromFavorites(String universityId) async {
    return await _authService.removeFromFavorites(universityId);
  }

  /// Check if university is favorite using AuthService
  bool isFavorite(String universityId) {
    return _authService.isFavorite(universityId);
  }

  /// Get favorite universities
  Future<List<University>> getFavoriteUniversities() async {
    final favoriteIds = getFavoriteIds();
    final allUniversities = await getAllUniversities();

    return allUniversities
        .where((uni) => favoriteIds.contains(uni.id))
        .toList();
  }

  /// Get university by ID
  Future<University?> getUniversityById(String id) async {
    if (_useFirestore) {
      return await _firestoreService.getUniversityById(id);
    }

    try {
      return sampleUniversities.firstWhere((uni) => uni.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get unique cities
  Future<List<String>> getUniqueCities() async {
    if (_useFirestore) {
      return await _firestoreService.getUniqueCities();
    }

    return sampleUniversities.map((uni) => uni.city).toSet().toList()..sort();
  }

  /// Get unique majors
  Future<List<String>> getUniqueMajors() async {
    if (_useFirestore) {
      return await _firestoreService.getUniqueMajors();
    }

    final majors = <String>{};
    for (var uni in sampleUniversities) {
      majors.addAll(uni.majors);
    }
    return majors.toList()..sort();
  }

  /// Migrate local data to Firestore (one-time operation)
  Future<bool> migrateToFirestore() async {
    return await _firestoreService.batchUploadUniversities(sampleUniversities);
  }

  /// Add new university to Firestore
  Future<bool> addUniversity(University university) async {
    if (_useFirestore) {
      return await _firestoreService.addUniversity(university);
    }
    return false;
  }

  /// Update university in Firestore
  Future<bool> updateUniversity(University university) async {
    if (_useFirestore) {
      return await _firestoreService.updateUniversity(university);
    }
    return false;
  }

  /// Delete university from Firestore
  Future<bool> deleteUniversity(String id) async {
    if (_useFirestore) {
      return await _firestoreService.deleteUniversity(id);
    }
    return false;
  }
}
