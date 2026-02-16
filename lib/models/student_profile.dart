import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель для хранения достижений студента
class StudentProfile {
  final String userId;
  final String name;
  final int? entScore; // Прогнозируемый или реальный балл ЕНТ
  final double? gpa; // GPA (max 4.0)
  final double? ieltsScore; // IELTS Score (0-9.0)
  final int? mathScore; // Math Score (or similar subject score)
  final double? profileStrength; // 0.0 to 1.0 (calculated or estimated)
  final List<String> achievements; // Список достижений
  final List<String> preferredCities; // Предпочитаемые города
  final List<String> preferredMajors; // Интересующие специальности
  final int? budget; // Бюджет на обучение в тенге
  final DateTime? createdAt;
  final DateTime? updatedAt;

  StudentProfile({
    required this.userId,
    required this.name,
    this.entScore,
    this.gpa,
    this.ieltsScore,
    this.mathScore,
    this.profileStrength,
    this.achievements = const [],
    this.preferredCities = const [],
    this.preferredMajors = const [],
    this.budget,
    this.createdAt,
    this.updatedAt,
  });

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'entScore': entScore,
      'gpa': gpa,
      'ieltsScore': ieltsScore,
      'mathScore': mathScore,
      'profileStrength': profileStrength,
      'achievements': achievements,
      'preferredCities': preferredCities,
      'preferredMajors': preferredMajors,
      'budget': budget,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  /// Создать из Map (Firestore)
  factory StudentProfile.fromMap(Map<String, dynamic> map) {
    return StudentProfile(
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      entScore: map['entScore'],
      gpa: (map['gpa'] as num?)?.toDouble(),
      ieltsScore: (map['ieltsScore'] as num?)?.toDouble(),
      mathScore: map['mathScore'],
      profileStrength: (map['profileStrength'] as num?)?.toDouble(),
      achievements: List<String>.from(map['achievements'] ?? []),
      preferredCities: List<String>.from(map['preferredCities'] ?? []),
      preferredMajors: List<String>.from(map['preferredMajors'] ?? []),
      budget: map['budget'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Создать из DocumentSnapshot
  factory StudentProfile.fromDocument(DocumentSnapshot doc) {
    return StudentProfile.fromMap(doc.data() as Map<String, dynamic>);
  }

  /// Копировать с изменениями
  StudentProfile copyWith({
    String? userId,
    String? name,
    int? entScore,
    double? gpa,
    double? ieltsScore,
    int? mathScore,
    double? profileStrength,
    List<String>? achievements,
    List<String>? preferredCities,
    List<String>? preferredMajors,
    int? budget,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudentProfile(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      entScore: entScore ?? this.entScore,
      gpa: gpa ?? this.gpa,
      ieltsScore: ieltsScore ?? this.ieltsScore,
      mathScore: mathScore ?? this.mathScore,
      profileStrength: profileStrength ?? this.profileStrength,
      achievements: achievements ?? this.achievements,
      preferredCities: preferredCities ?? this.preferredCities,
      preferredMajors: preferredMajors ?? this.preferredMajors,
      budget: budget ?? this.budget,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Проверить, заполнен ли профиль
  bool get isComplete {
    return entScore != null &&
        achievements.isNotEmpty &&
        preferredMajors.isNotEmpty;
  }

  /// Получить процент заполненности профиля
  int get completeness {
    int total = 0;
    int filled = 0;

    // Базовые поля (Base fields)
    total += 4;
    // Расширенные поля (Extended fields for AI strategy)
    total += 3; // gpa, ielts, math

    if (entScore != null) filled++;
    if (achievements.isNotEmpty) filled++;
    if (preferredMajors.isNotEmpty) filled++;
    if (preferredCities.isNotEmpty) filled++;

    if (gpa != null) filled++;
    if (ieltsScore != null) filled++;
    if (mathScore != null) filled++;

    return ((filled / total) * 100).round();
  }
}
