import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/university.dart';
import '../models/specialty.dart';
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

  // SharedPreferences keys for disk cache
  static const String _diskCacheKey = 'cached_universities';
  static const String _diskCacheTimeKey = 'cached_universities_time';

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

  // ── Disk persistence ──────────────────────────────────

  /// Save universities to SharedPreferences as JSON.
  Future<void> _saveToDisk(List<University> universities) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> jsonList =
          universities.map((u) => u.toMap()).toList();
      await prefs.setString(_diskCacheKey, jsonEncode(jsonList));
      await prefs.setString(
        _diskCacheTimeKey,
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      debugPrint('💾 Failed to save universities to disk: $e');
    }
  }

  /// Load universities from SharedPreferences disk cache.
  Future<List<University>?> _loadFromDisk() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_diskCacheKey);
      if (raw == null || raw.isEmpty) return null;

      final List<dynamic> jsonList = jsonDecode(raw) as List<dynamic>;
      return jsonList
          .map((e) => University.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('💾 Failed to load universities from disk: $e');
      return null;
    }
  }

  /// Get all universities (with caching + offline persistence)
  Future<List<University>> getAllUniversities({
    bool forceRefresh = false,
  }) async {
    // 1. Fast path — in-memory cache
    if (!forceRefresh && _isCacheValid()) {
      return _cachedAllUniversities!;
    }

    // 2. Try Firestore
    try {
      final List<University> universities =
          await _firestoreService.getAllUniversities();
      _cachedAllUniversities = universities;
      _lastCacheTime = DateTime.now();

      // Persist to disk in background (non-blocking)
      _saveToDisk(universities);

      return universities;
    } catch (e) {
      debugPrint('🌐 Firestore fetch failed: $e');

      // 3a. In-memory fallback
      if (_cachedAllUniversities != null) {
        return _cachedAllUniversities!;
      }

      // 3b. Disk fallback
      final List<University>? diskData = await _loadFromDisk();
      if (diskData != null && diskData.isNotEmpty) {
        _cachedAllUniversities = diskData;
        debugPrint('💾 Loaded ${diskData.length} universities from disk cache');
        return diskData;
      }

      return [];
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

  /// Get specialties for a university
  Stream<List<Specialty>> getSpecialties(String universityId) {
    return _firestoreService.getSpecialties(universityId);
  }
}
