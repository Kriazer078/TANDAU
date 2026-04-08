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
      // Format dates to match document definition (YYYY-MM-DD or similar)
      // Assuming document IDs are YYYY-MM-DD based on previous AdminService code.
      final startStr = start.toIso8601String().split('T')[0];
      final endStr = end.toIso8601String().split('T')[0];

      final snapshot = await _firestore
          .collection('statistics')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: startStr)
          .where(FieldPath.documentId, isLessThanOrEqualTo: endStr)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['date'] = doc.id; // Include document ID as date
        return DashboardStats.fromJson(data);
      }).toList();
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
