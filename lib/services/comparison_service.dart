import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import '../models/comparison.dart';
import '../models/university.dart';
import 'university_service.dart';

/// Сервис сравнения университетов (работает БЕЗ регистрации, использует локальное хранилище)
class ComparisonService {
  static final ComparisonService _instance = ComparisonService._internal();

  factory ComparisonService() {
    return _instance;
  }

  ComparisonService._internal() {
    // Initial load
    getUserComparison();
  }

  final UniversityService _universityService = UniversityService();

  // 📝 StreamController lifecycle note:
  // Since ComparisonService is a Singleton that lives for the entire duration
  // of the application, this StreamController intentionally does not have a
  // dispose() method. It remains active to serve any screen that needs
  // real-time comparison updates.
  final StreamController<ComparisonItem?> _controller =
      StreamController<ComparisonItem?>.broadcast(
    onCancel: () {
      debugPrint(
        'ℹ️ ComparisonService: All listeners unsubscribed from stream',
      );
    },
  );

  ComparisonItem? _cachedComparison;

  static const String _storageKey = 'comparison_universities';
  static const int maxComparisonItems =
      2; // Максимум 2 университета для сравнения

  /// Get current comparison list from local storage
  Future<ComparisonItem?> getUserComparison() async {
    if (_cachedComparison != null) return _cachedComparison;

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString == null) {
        _cachedComparison = null;
        return null;
      }

      final Map<String, dynamic> data = json.decode(jsonString);
      _cachedComparison = ComparisonItem.fromMap(data);
      _controller.add(_cachedComparison);
      return _cachedComparison;
    } catch (e) {
      debugPrint('Error getting user comparison: $e');
      return null;
    }
  }

  /// Get comparison stream
  Stream<ComparisonItem?> getComparisonStream() => _controller.stream;

  /// Add university to comparison
  Future<bool> addToComparison(String universityId) async {
    try {
      debugPrint('🔵 Starting addToComparison for university: $universityId');

      final prefs = await SharedPreferences.getInstance();
      final comparison = await getUserComparison();
      final now = DateTime.now();

      ComparisonItem updatedComparison;

      if (comparison == null) {
        // Create new comparison
        debugPrint('✅ Creating new comparison list');
        updatedComparison = ComparisonItem(
          userId: 'local_user', // Не требуется авторизация
          universityIds: [universityId],
          createdAt: now,
          updatedAt: now,
        );
      } else {
        // Check if already in comparison
        if (comparison.universityIds.contains(universityId)) {
          debugPrint('⚠️ University already in comparison');
          return false; // Already in comparison
        }

        // Check max limit
        if (comparison.universityIds.length >= maxComparisonItems) {
          debugPrint(
            '⚠️ Max comparison limit reached (${comparison.universityIds.length}/$maxComparisonItems)',
          );
          return false; // Max limit reached
        }

        // Add to existing comparison
        final updatedIds = [...comparison.universityIds, universityId];
        debugPrint('✅ Adding to existing comparison. New list: $updatedIds');
        updatedComparison = comparison.copyWith(
          universityIds: updatedIds,
          updatedAt: now,
        );
      }

      await prefs.setString(
        _storageKey,
        json.encode(updatedComparison.toMap()),
      );
      _cachedComparison = updatedComparison;
      _controller.add(updatedComparison);
      debugPrint('✅ Comparison updated successfully');

      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Error adding to comparison: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Remove university from comparison
  Future<bool> removeFromComparison(String universityId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final comparison = await getUserComparison();
      if (comparison == null) return false;

      final updatedIds =
          comparison.universityIds.where((id) => id != universityId).toList();

      if (updatedIds.isEmpty) {
        // Delete comparison if empty
        await prefs.remove(_storageKey);
        _cachedComparison = null;
        _controller.add(null);
      } else {
        final updatedComparison = comparison.copyWith(
          universityIds: updatedIds,
          updatedAt: DateTime.now(),
        );
        await prefs.setString(
          _storageKey,
          json.encode(updatedComparison.toMap()),
        );
        _cachedComparison = updatedComparison;
        _controller.add(updatedComparison);
      }

      return true;
    } catch (e) {
      debugPrint('Error removing from comparison: $e');
      return false;
    }
  }

  /// Clear all comparisons
  Future<bool> clearComparison() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      _cachedComparison = null;
      _controller.add(null);
      return true;
    } catch (e) {
      debugPrint('Error clearing comparison: $e');
      return false;
    }
  }

  /// Check if university is in comparison
  Future<bool> isInComparison(String universityId) async {
    final comparison = await getUserComparison();
    return comparison?.universityIds.contains(universityId) ?? false;
  }

  /// Get comparison count
  Future<int> getComparisonCount() async {
    final comparison = await getUserComparison();
    return comparison?.universityIds.length ?? 0;
  }

  /// Get universities in comparison
  Future<List<University>> getComparisonUniversities() async {
    try {
      final comparison = await getUserComparison();
      if (comparison == null || comparison.universityIds.isEmpty) {
        return [];
      }

      final universities = <University>[];
      for (final id in comparison.universityIds) {
        final uni = await _universityService.getUniversityById(id);
        if (uni != null) {
          universities.add(uni);
        }
      }

      return universities;
    } catch (e) {
      debugPrint('Error getting comparison universities: $e');
      return [];
    }
  }

  /// Check if can add more universities
  Future<bool> canAddMore() async {
    final count = await getComparisonCount();
    return count < maxComparisonItems;
  }

  /// Set specific universities for comparison (replaces existing)
  Future<bool> setComparison(List<String> universityIds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();

      final newComparison = ComparisonItem(
        userId: 'local_user',
        universityIds: universityIds.take(maxComparisonItems).toList(),
        createdAt: now,
        updatedAt: now,
      );

      await prefs.setString(_storageKey, json.encode(newComparison.toMap()));
      _cachedComparison = newComparison;
      _controller.add(newComparison);
      return true;
    } catch (e) {
      debugPrint('Error setting comparison: $e');
      return false;
    }
  }

  /// Get remaining slots
  Future<int> getRemainingSlots() async {
    final count = await getComparisonCount();
    return maxComparisonItems - count;
  }
}
