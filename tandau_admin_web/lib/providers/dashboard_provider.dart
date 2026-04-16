import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_stats.dart';

// --- Repository ---

class DashboardRepository {
  final FirebaseFirestore _firestore;

  DashboardRepository(this._firestore);

  Future<List<DashboardStats>> getStatistics({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final startOfDay = DateTime(start.year, start.month, start.day);
      final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);

      // Fetch users and reviews within the date range
      final usersSnapshot = await _firestore
          .collection('users')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      // We don't query activeUsers per day historically since that requires complex tracking.
      // We will leave activeUsers as 0 in the history but newUsers and newReviews will be accurate.

      // Map to hold daily stats
      final Map<String, DashboardStats> dailyStats = {};

      // Initialize all days in the range to 0
      for (int i = 0; i <= endOfDay.difference(startOfDay).inDays; i++) {
        final currentDay = startOfDay.add(Duration(days: i));
        final dateStr = currentDay.toIso8601String().split('T')[0];
        dailyStats[dateStr] = DashboardStats(
          date: currentDay,
          newUsers: 0,
          newReviews: 0,
          activeUsers: 0,
        );
      }

      // Aggregate new users
      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        if (data['createdAt'] != null) {
          final createdAt = (data['createdAt'] as Timestamp).toDate();
          final dateStr = createdAt.toIso8601String().split('T')[0];
          if (dailyStats.containsKey(dateStr)) {
            final stat = dailyStats[dateStr]!;
            dailyStats[dateStr] = DashboardStats(
              date: stat.date,
              newUsers: stat.newUsers + 1,
              newReviews: stat.newReviews,
              activeUsers: stat.activeUsers,
            );
          }
        }
      }

      // Aggregate new reviews
      for (var doc in reviewsSnapshot.docs) {
        final data = doc.data();
        if (data['createdAt'] != null) {
          final createdAt = (data['createdAt'] as Timestamp).toDate();
          final dateStr = createdAt.toIso8601String().split('T')[0];
          if (dailyStats.containsKey(dateStr)) {
            final stat = dailyStats[dateStr]!;
            dailyStats[dateStr] = DashboardStats(
              date: stat.date,
              newUsers: stat.newUsers,
              newReviews: stat.newReviews + 1,
              activeUsers: stat.activeUsers,
            );
          }
        }
      }

      var statsList = dailyStats.values.toList();
      statsList.sort((a, b) => a.date.compareTo(b.date));
      return statsList;
    } catch (e) {
      throw Exception('Failed to fetch statistics: $e');
    }
  }
}

// --- Providers ---

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(FirebaseFirestore.instance);
});

// State for the selected filtered date range
final dashboardDateRangeProvider =
    NotifierProvider<DashboardDateRangeNotifier, DateTimeRange>(() {
      return DashboardDateRangeNotifier();
    });

class DashboardDateRangeNotifier extends Notifier<DateTimeRange> {
  @override
  DateTimeRange build() {
    final now = DateTime.now();
    return DateTimeRange(
      start: now.subtract(const Duration(days: 6)),
      end: now,
    );
  }

  void updateRange(DateTimeRange newRange) {
    state = newRange;
  }
}

// AsyncNotifier for fetching stats based on the date range
final dashboardStatsProvider =
    AsyncNotifierProvider<DashboardStatsNotifier, List<DashboardStats>>(() {
      return DashboardStatsNotifier();
    });

class DashboardStatsNotifier extends AsyncNotifier<List<DashboardStats>> {
  @override
  Future<List<DashboardStats>> build() async {
    final range = ref.watch(dashboardDateRangeProvider);
    return _fetchStats(range);
  }

  Future<List<DashboardStats>> _fetchStats(DateTimeRange range) async {
    final repository = ref.read(dashboardRepositoryProvider);
    final stats = await repository.getStatistics(
      start: range.start,
      end: range.end,
    );

    // Sort by date ascending
    stats.sort((a, b) => a.date.compareTo(b.date));
    return stats;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final range = ref.read(dashboardDateRangeProvider);
      return _fetchStats(range);
    });
  }
}

// --- Active (Real-time) Users Stream ---
final activeUsersStreamProvider = StreamProvider<int>((ref) {
  // Query users online in the last 15 minutes
  final recentTime = DateTime.now().subtract(const Duration(minutes: 15));
  return FirebaseFirestore.instance
      .collection('users')
      .where('lastOnline', isGreaterThan: Timestamp.fromDate(recentTime))
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});
