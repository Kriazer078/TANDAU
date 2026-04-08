import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

/// Модель профиля студента.
///
/// Данные хранятся в [UserModel] (единый источник правды).
/// Используйте [StudentProfile.fromUserModel] для создания из UserModel.
class StudentProfile {
  final String userId;
  final String name;
  final int? entScore;
  final double? gpa;
  final double? ieltsScore;
  final int? mathScore;
  final double? profileStrength;
  final List<String> achievements;
  final List<String> preferredCities;
  final List<String> preferredMajors;
  final int? budget;
  // 🆕 Phase 3 — расширенный профиль
  final String? targetProfession;
  final String? financialSituation;
  final bool? hasDisability;
  final bool? isOrphan;
  final bool? isRural;
  final bool? specialExamPassed;
  final List<String> extracurriculars;
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
    this.specialExamPassed,
    this.extracurriculars = const [],
    this.createdAt,
    this.updatedAt,
  });

  // ═══════════════════════════════════════════
  //  АДАПТЕР: создание из UserModel (единый источник)
  // ═══════════════════════════════════════════

  /// Создать StudentProfile из UserModel.
  /// Это основной способ получения StudentProfile —
  /// все данные берутся из единого источника [UserModel].
  factory StudentProfile.fromUserModel(UserModel user) {
    return StudentProfile(
      userId: user.uid,
      name: user.name,
      entScore: user.untScore,
      gpa: user.gpa,
      ieltsScore: user.ieltsScore,
      mathScore: user.mathScore,
      profileStrength: user.profileStrength,
      achievements: user.achievements,
      preferredCities: user.preferredCities.isNotEmpty
          ? user.preferredCities
          : (user.city != null ? [user.city!] : []),
      preferredMajors: user.preferredMajors,
      budget: user.budget,
      targetProfession: user.targetProfession,
      financialSituation: user.financialSituation,
      hasDisability: user.hasDisability,
      isOrphan: user.isOrphan,
      isRural: user.isRural,
      specialExamPassed: user.specialExamPassed,
      extracurriculars: user.extracurriculars,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    );
  }

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
      'specialExamPassed': specialExamPassed,
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
      specialExamPassed: map['specialExamPassed'],
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
    bool? specialExamPassed,
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
      specialExamPassed: specialExamPassed ?? this.specialExamPassed,
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
    int total = 10;
    int filled = 0;

    if (entScore != null) filled++;
    if (achievements.isNotEmpty) filled++;
    if (preferredMajors.isNotEmpty) filled++;
    if (preferredCities.isNotEmpty) filled++;
    if (gpa != null) filled++;
    if (ieltsScore != null) filled++;
    if (mathScore != null) filled++;
    if (targetProfession != null) filled++;
    if (financialSituation != null) filled++;
    if (extracurriculars.isNotEmpty) filled++;

    return ((filled / total) * 100).round();
  }
}
