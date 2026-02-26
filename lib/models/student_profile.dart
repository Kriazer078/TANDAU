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
  // 🆕 Phase 3 — расширенный профиль
  final String? targetProfession; // "Frontend разработчик"
  final String? financialSituation; // "only_grant" | "up_to_1m" | "any"
  final bool? hasDisability; // для квоты инвалидов
  final bool? isOrphan; // для квоты СУСН
  final bool? isRural; // для сельской квоты
  final List<String> extracurriculars; // кружки, проекты, олимпиады
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
    this.targetProfession,
    this.financialSituation,
    this.hasDisability,
    this.isOrphan,
    this.isRural,
    this.extracurriculars = const [],
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
      'targetProfession': targetProfession,
      'financialSituation': financialSituation,
      'hasDisability': hasDisability,
      'isOrphan': isOrphan,
      'isRural': isRural,
      'extracurriculars': extracurriculars,
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
      targetProfession: map['targetProfession'],
      financialSituation: map['financialSituation'],
      hasDisability: map['hasDisability'],
      isOrphan: map['isOrphan'],
      isRural: map['isRural'],
      extracurriculars: List<String>.from(map['extracurriculars'] ?? []),
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
    String? targetProfession,
    String? financialSituation,
    bool? hasDisability,
    bool? isOrphan,
    bool? isRural,
    List<String>? extracurriculars,
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
      targetProfession: targetProfession ?? this.targetProfession,
      financialSituation: financialSituation ?? this.financialSituation,
      hasDisability: hasDisability ?? this.hasDisability,
      isOrphan: isOrphan ?? this.isOrphan,
      isRural: isRural ?? this.isRural,
      extracurriculars: extracurriculars ?? this.extracurriculars,
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
    int total = 10; // all trackable fields
    int filled = 0;

    // Базовые поля
    if (entScore != null) filled++;
    if (achievements.isNotEmpty) filled++;
    if (preferredMajors.isNotEmpty) filled++;
    if (preferredCities.isNotEmpty) filled++;

    // Расширенные поля
    if (gpa != null) filled++;
    if (ieltsScore != null) filled++;
    if (mathScore != null) filled++;

    // Новые поля Phase 3
    if (targetProfession != null) filled++;
    if (financialSituation != null) filled++;
    if (extracurriculars.isNotEmpty) filled++;

    return ((filled / total) * 100).round();
  }
}
