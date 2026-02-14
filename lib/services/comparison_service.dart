import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/comparison.dart';
import '../models/university.dart';
import 'university_service.dart';

/// Сервис сравнения университетов (работает БЕЗ регистрации, использует локальное хранилище)
class ComparisonService {
  final UniversityService _universityService = UniversityService();

  static const String _storageKey = 'comparison_universities';
  static const int maxComparisonItems =
      2; // Максимум 2 университета для сравнения

  /// Get current comparison list from local storage
  Future<ComparisonItem?> getUserComparison() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString == null) return null;

      final Map<String, dynamic> data = json.decode(jsonString);
      return ComparisonItem.fromMap(data);
    } catch (e) {
      debugPrint('Error getting user comparison: $e');
      return null;
    }
  }

  /// Get comparison stream (not real-time, just returns current state)
  Stream<ComparisonItem?> getComparisonStream() async* {
    while (true) {
      yield await getUserComparison();
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  /// Add university to comparison
  Future<bool> addToComparison(String universityId) async {
    try {
      debugPrint('🔵 Starting addToComparison for university: $universityId');

      final prefs = await SharedPreferences.getInstance();
      final comparison = await getUserComparison();
      final now = DateTime.now();

      if (comparison == null) {
        // Create new comparison
        debugPrint('✅ Creating new comparison list');
        final newComparison = ComparisonItem(
          userId: 'local_user', // Не требуется авторизация
          universityIds: [universityId],
          createdAt: now,
          updatedAt: now,
        );
        await prefs.setString(_storageKey, json.encode(newComparison.toMap()));
        debugPrint('✅ New comparison created successfully');
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
        final updatedComparison = comparison.copyWith(
          universityIds: updatedIds,
          updatedAt: now,
        );
        await prefs.setString(
          _storageKey,
          json.encode(updatedComparison.toMap()),
        );
        debugPrint('✅ Comparison updated successfully');
      }

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

      final updatedIds = comparison.universityIds
          .where((id) => id != universityId)
          .toList();

      if (updatedIds.isEmpty) {
        // Delete comparison if empty
        await prefs.remove(_storageKey);
      } else {
        final updatedComparison = comparison.copyWith(
          universityIds: updatedIds,
          updatedAt: DateTime.now(),
        );
        await prefs.setString(
          _storageKey,
          json.encode(updatedComparison.toMap()),
        );
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

  /// Get remaining slots
  Future<int> getRemainingSlots() async {
    final count = await getComparisonCount();
    return maxComparisonItems - count;
  }
}
