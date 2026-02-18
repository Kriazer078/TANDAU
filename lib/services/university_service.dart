import '../models/university.dart';

import 'firestore_service.dart';
import 'auth_service.dart';

class UniversityService {
  static final UniversityService _instance = UniversityService._internal();

  factory UniversityService() {
    return _instance;
  }

  UniversityService._internal();
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  // --- ВНУТРЕННИЙ КЭШ ---
  List<University>? _cachedAllUniversities;
  List<String>? _cachedCities;
  List<String>? _cachedMajors;
  DateTime? _lastCacheTime;
  final Duration _cacheDuration = const Duration(minutes: 15);

  bool _isCacheValid() {
    if (_cachedAllUniversities == null || _lastCacheTime == null) return false;
    return DateTime.now().difference(_lastCacheTime!) < _cacheDuration;
  }

  void clearCache() {
    _cachedAllUniversities = null;
    _cachedCities = null;
    _cachedMajors = null;
    _lastCacheTime = null;
  }

  /// Get all universities (with caching)
  Future<List<University>> getAllUniversities({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _isCacheValid()) {
      return _cachedAllUniversities!;
    }

    try {
      final universities = await _firestoreService.getAllUniversities();
      _cachedAllUniversities = universities;
      _lastCacheTime = DateTime.now();
      return universities;
    } catch (e) {
      return _cachedAllUniversities ?? [];
    }
  }

  /// Filter universities
  Future<List<University>> filterUniversities({
    List<String>? city,
    List<String>? major,
    bool? onlyGrants,
    double? maxPrice,
    String? searchQuery,
  }) async {
    final allUniversities = await getAllUniversities();

    var filtered = allUniversities.where((uni) {
      return uni.matchesFilters(
        cityFilter: city,
        majorFilter: major,
        onlyGrants: onlyGrants,
        maxPrice: maxPrice,
      );
    }).toList();

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((uni) => uni.matchesSearch(query)).toList();
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
    // Try to find in cache first
    if (_cachedAllUniversities != null) {
      try {
        return _cachedAllUniversities!.firstWhere((u) => u.id == id);
      } catch (_) {}
    }
    return await _firestoreService.getUniversityById(id);
  }

  /// Get unique cities (with caching)
  Future<List<String>> getUniqueCities() async {
    if (_cachedCities != null && _isCacheValid()) return _cachedCities!;
    final cities = await _firestoreService.getUniqueCities();
    _cachedCities = cities;
    return cities;
  }

  /// Get unique majors (with caching)
  Future<List<String>> getUniqueMajors() async {
    if (_cachedMajors != null && _isCacheValid()) return _cachedMajors!;
    final majors = await _firestoreService.getUniqueMajors();
    _cachedMajors = majors;
    return majors;
  }

  /// Migrate local data to Firestore
  Future<bool> migrateToFirestore(List<University> universities) async {
    final result = await _firestoreService.batchUploadUniversities(
      universities,
    );
    if (result) clearCache();
    return result;
  }

  /// Add new university to Firestore
  Future<bool> addUniversity(University university) async {
    final result = await _firestoreService.addUniversity(university);
    if (result) clearCache();
    return result;
  }

  /// Update university in Firestore
  Future<bool> updateUniversity(University university) async {
    final result = await _firestoreService.updateUniversity(university);
    if (result) clearCache();
    return result;
  }

  /// Delete university from Firestore
  Future<bool> deleteUniversity(String id) async {
    final result = await _firestoreService.deleteUniversity(id);
    if (result) clearCache();
    return result;
  }
}
