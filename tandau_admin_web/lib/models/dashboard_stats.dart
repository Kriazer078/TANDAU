class DashboardStats {
  final DateTime date;
  final int newUsers;
  final int newReviews;
  final int activeUsers;

  DashboardStats({
    required this.date,
    required this.newUsers,
    required this.newReviews,
    required this.activeUsers,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      date: DateTime.parse(json['date'] as String),
      newUsers: json['new_users'] as int? ?? 0,
      newReviews: json['new_reviews'] as int? ?? 0,
      activeUsers: json['active_users'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'new_users': newUsers,
      'new_reviews': newReviews,
      'active_users': activeUsers,
    };
  }
}
