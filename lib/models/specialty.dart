class Specialty {
  final String id;
  final String title;
  final List<String> profileSubjects;
  final int minScore2023;
  final int minScore2024;
  final int quota2024;
  final int trend; // +1 (растет), 0 (стабилен), -1 (падает)

  // Для UI и расчётов
  double get trendFactor => trend == 1 ? 1.05 : (trend == -1 ? 0.95 : 1.0);

  Specialty({
    required this.id,
    required this.title,
    required this.profileSubjects,
    required this.minScore2023,
    required this.minScore2024,
    required this.quota2024,
    required this.trend,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'profile_subjects': profileSubjects,
      'min_score_2023': minScore2023,
      'min_score_2024': minScore2024,
      'quota_2024': quota2024,
      'trend': trend,
    };
  }

  factory Specialty.fromMap(Map<String, dynamic> map, String docId) {
    return Specialty(
      id: map['id'] ?? docId,
      title: map['title'] ?? '',
      profileSubjects: List<String>.from(map['profile_subjects'] ?? []),
      minScore2023: map['min_score_2023'] ?? 0,
      minScore2024: map['min_score_2024'] ?? 0,
      quota2024: map['quota_2024'] ?? 0,
      trend: map['trend'] ?? 0,
    );
  }

  // Расчёт прогнозируемого балла на 2025 год
  int get predictedMinScore2025 {
    return (minScore2024 + (minScore2024 - minScore2023) * trendFactor).round();
  }

  // Расчёт шанса (вероятности) гранта (от 0.0 до 1.0)
  double calculateGrantProbability(int userUntScore) {
    if (predictedMinScore2025 <= 0) return 0.0;

    // Weight factor (чем больше балл пользователя, тем выше шанс. Если балл = predicted, то шанс ~80-90%)
    double prob = (userUntScore / predictedMinScore2025) * 0.9;

    // Если балл пользователя больше предсказанного на 10%, шанс 99%
    if (userUntScore >= predictedMinScore2025 * 1.05) return 0.99;

    return prob.clamp(0.0, 1.0);
  }
}
