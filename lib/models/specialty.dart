class Specialty {
  final String id;
  final String title;
  final List<String> profileSubjects;
  final int minScore2024;
  final int minScore2025;
  final int quota2025;
  final int trend; // +1 (растет), 0 (стабилен), -1 (падает)

  // Для UI и расчётов
  double get trendFactor => trend == 1 ? 1.05 : (trend == -1 ? 0.95 : 1.0);

  Specialty({
    required this.id,
    required this.title,
    required this.profileSubjects,
    required this.minScore2024,
    required this.minScore2025,
    required this.quota2025,
    required this.trend,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'profile_subjects': profileSubjects,
      'min_score_2024': minScore2024,
      'min_score_2025': minScore2025,
      'quota_2025': quota2025,
      'trend': trend,
    };
  }

  factory Specialty.fromMap(Map<String, dynamic> map, String docId) {
    return Specialty(
      id: map['id'] ?? docId,
      title: map['title'] ?? '',
      profileSubjects: List<String>.from(map['profile_subjects'] ?? []),
      minScore2024: map['min_score_2024'] ?? 0,
      minScore2025: map['min_score_2025'] ?? 0,
      quota2025: map['quota_2025'] ?? 0,
      trend: map['trend'] ?? 0,
    );
  }

  // Расчёт прогнозируемого балла на 2026 год
  int get predictedMinScore2026 {
    return (minScore2025 + (minScore2025 - minScore2024) * trendFactor).round();
  }

  // Расчёт шанса (вероятности) гранта (от 0.0 до 1.0)
  double calculateGrantProbability(int userUntScore) {
    if (predictedMinScore2026 <= 0) return 0.0;

    // Weight factor (чем больше балл пользователя, тем выше шанс. Если балл = predicted, то шанс ~80-90%)
    double prob = (userUntScore / predictedMinScore2026) * 0.9;

    // Если балл пользователя больше предсказанного на 10%, шанс 99%
    if (userUntScore >= predictedMinScore2026 * 1.05) return 0.99;

    return prob.clamp(0.0, 1.0);
  }
}
