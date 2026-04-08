import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? age;
  final String? education;
  final String? city;
  final int? untScore;
  final double? ieltsScore;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final double? gpa; // ⭐ GPA (max 4.0)
  final int? mathScore; // ⭐ Math Score
  final String? photoUrl; // ⭐ URL фото профиля
  final List<String> favoriteUniversities;
  final List<String> achievements; // ⭐ Достижения студента
  final List<String> preferredMajors; // ⭐ Предпочитаемые специальности
  final String role; // 🔐 Роль: 'user' или 'admin'
  final bool banned; // 🚫 Забанен ли пользователь
  final String? banReason; // 📝 Причина бана

  // 🛡️ Admin / Moderator tracking
  final DateTime? lastOnline;
  final String? lastIp;
  final String? lastDevice;

  // 💎 Subscription & AI Limits
  final String subscriptionPlan; // 'free', 'pro', 'premium'
  final int aiTokensRemaining;
  final DateTime? lastTokenResetDate;

  // 📋 Расширенный профиль (перенесено из StudentProfile)
  final List<String> preferredCities; // Предпочитаемые города
  final int? budget; // Бюджет на обучение в тенге
  final String? targetProfession; // "Frontend разработчик"
  final String? financialSituation; // "only_grant" | "up_to_1m" | "any"
  final bool? hasDisability; // для квоты инвалидов
  final bool? isOrphan; // для квоты СУСН
  final bool? isRural; // для сельской квоты
  final List<String> extracurriculars; // кружки, проекты, олимпиады
  final double? profileStrength; // 0.0 to 1.0

  // 🎯 ЕНТ направление и профильные предметы
  final String? subjectType; // 'physMath' | 'humanities'
  final String? entSubject1; // 1-й профильный предмет ЕНТ
  final String? entSubject2; // 2-й профильный предмет ЕНТ (опц.)

  // 🎓 Специальные экзамены (творческие, медицинские, психометрические)
  final bool? specialExamPassed;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.age,
    this.education,
    this.city,
    this.untScore,
    this.ieltsScore,
    this.gpa,
    this.mathScore,
    this.photoUrl,
    required this.createdAt,
    this.updatedAt,
    this.favoriteUniversities = const [],
    this.achievements = const [],
    this.preferredMajors = const [],
    this.role = 'user',
    this.banned = false,
    this.banReason,
    this.subscriptionPlan = 'free',
    this.aiTokensRemaining = 100,
    this.lastTokenResetDate,
    this.lastOnline,
    this.lastIp,
    this.lastDevice,
    // 📋 Расширенный профиль
    this.preferredCities = const [],
    this.budget,
    this.targetProfession,
    this.financialSituation,
    this.hasDisability,
    this.isOrphan,
    this.isRural,
    this.extracurriculars = const [],
    this.profileStrength,
    // 🎯 ЕНТ направление
    this.subjectType,
    this.entSubject1,
    this.entSubject2,
    this.specialExamPassed,
  });

  /// Алиас для совместимости с StudentProfile
  int? get entScore => untScore;

  /// Проверить, заполнен ли профиль (перенесено из StudentProfile)
  bool get isProfileComplete {
    return untScore != null &&
        achievements.isNotEmpty &&
        preferredMajors.isNotEmpty;
  }

  /// Получить процент заполненности профиля (перенесено из StudentProfile)
  int get profileCompleteness {
    int total = 10;
    int filled = 0;

    if (untScore != null) filled++;
    if (achievements.isNotEmpty) filled++;
    if (preferredMajors.isNotEmpty) filled++;
    if (preferredCities.isNotEmpty || city != null) filled++;
    if (gpa != null) filled++;
    if (ieltsScore != null) filled++;
    if (mathScore != null) filled++;
    if (targetProfession != null) filled++;
    if (financialSituation != null) filled++;
    if (extracurriculars.isNotEmpty) filled++;

    return ((filled / total) * 100).round();
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'age': age,
      'education': education,
      'city': city,
      'untScore': untScore,
      'ieltsScore': ieltsScore,
      'gpa': gpa,
      'mathScore': mathScore,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'favoriteUniversities': favoriteUniversities,
      'achievements': achievements,
      'preferredMajors': preferredMajors,
      'role': role,
      'banned': banned,
      'banReason': banReason,
      'subscriptionPlan': subscriptionPlan,
      'aiTokensRemaining': aiTokensRemaining,
      'lastTokenResetDate': lastTokenResetDate != null
          ? Timestamp.fromDate(lastTokenResetDate!)
          : null,
      'lastOnline': lastOnline != null ? Timestamp.fromDate(lastOnline!) : null,
      'lastIp': lastIp,
      'lastDevice': lastDevice,
      // 📋 Расширенный профиль
      'preferredCities': preferredCities,
      'budget': budget,
      'targetProfession': targetProfession,
      'financialSituation': financialSituation,
      'hasDisability': hasDisability,
      'isOrphan': isOrphan,
      'isRural': isRural,
      'extracurriculars': extracurriculars,
      'profileStrength': profileStrength,
      // 🎯 ЕНТ направление
      'subjectType': subjectType,
      'entSubject1': entSubject1,
      'entSubject2': entSubject2,
      'specialExamPassed': specialExamPassed,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      age: map['age'],
      education: map['education'],
      city: map['city'],
      untScore: map['untScore'] ?? map['entScore'],
      ieltsScore: (map['ieltsScore'] is String)
          ? double.tryParse(map['ieltsScore'])
          : (map['ieltsScore'] as num?)?.toDouble(),
      gpa: (map['gpa'] is String)
          ? double.tryParse(map['gpa'])
          : (map['gpa'] as num?)?.toDouble(),
      mathScore: (map['mathScore'] is String)
          ? int.tryParse(map['mathScore'])
          : map['mathScore'] as int?,
      photoUrl: map['photoUrl'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      favoriteUniversities: List<String>.from(
        map['favoriteUniversities'] ?? [],
      ),
      achievements: List<String>.from(map['achievements'] ?? []),
      preferredMajors: List<String>.from(map['preferredMajors'] ?? []),
      role: map['role'] ?? 'user',
      banned: map['banned'] ?? false,
      banReason: map['banReason'],
      subscriptionPlan: map['subscriptionPlan'] ?? 'free',
      aiTokensRemaining: map['aiTokensRemaining'] ?? 100,
      lastTokenResetDate: map['lastTokenResetDate'] != null
          ? (map['lastTokenResetDate'] as Timestamp).toDate()
          : null,
      lastOnline: map['lastOnline'] != null
          ? (map['lastOnline'] as Timestamp).toDate()
          : null,
      lastIp: map['lastIp'],
      lastDevice: map['lastDevice'],
      // 📋 Расширенный профиль
      preferredCities: List<String>.from(map['preferredCities'] ?? []),
      budget: map['budget'],
      targetProfession: map['targetProfession'],
      financialSituation: map['financialSituation'],
      hasDisability: map['hasDisability'],
      isOrphan: map['isOrphan'],
      isRural: map['isRural'],
      extracurriculars: List<String>.from(map['extracurriculars'] ?? []),
      profileStrength: (map['profileStrength'] as num?)?.toDouble(),
      // 🎯 ЕНТ направление
      subjectType: map['subjectType'],
      entSubject1: map['entSubject1'],
      entSubject2: map['entSubject2'],
      specialExamPassed: map['specialExamPassed'],
    );
  }

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel.fromMap(data);
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? age,
    String? education,
    String? city,
    int? untScore,
    double? ieltsScore,
    double? gpa,
    int? mathScore,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? favoriteUniversities,
    List<String>? achievements,
    List<String>? preferredMajors,
    String? role,
    bool? banned,
    String? banReason,
    String? subscriptionPlan,
    int? aiTokensRemaining,
    DateTime? lastTokenResetDate,
    DateTime? lastOnline,
    String? lastIp,
    String? lastDevice,
    // 📋 Расширенный профиль
    List<String>? preferredCities,
    int? budget,
    String? targetProfession,
    String? financialSituation,
    bool? hasDisability,
    bool? isOrphan,
    bool? isRural,
    List<String>? extracurriculars,
    double? profileStrength,
    // 🎯 ЕНТ направление
    String? subjectType,
    String? entSubject1,
    String? entSubject2,
    bool? specialExamPassed,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
      education: education ?? this.education,
      city: city ?? this.city,
      untScore: untScore ?? this.untScore,
      ieltsScore: ieltsScore ?? this.ieltsScore,
      gpa: gpa ?? this.gpa,
      mathScore: mathScore ?? this.mathScore,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      favoriteUniversities: favoriteUniversities ?? this.favoriteUniversities,
      achievements: achievements ?? this.achievements,
      preferredMajors: preferredMajors ?? this.preferredMajors,
      role: role ?? this.role,
      banned: banned ?? this.banned,
      banReason: banReason ?? this.banReason,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      aiTokensRemaining: aiTokensRemaining ?? this.aiTokensRemaining,
      lastTokenResetDate: lastTokenResetDate ?? this.lastTokenResetDate,
      lastOnline: lastOnline ?? this.lastOnline,
      lastIp: lastIp ?? this.lastIp,
      lastDevice: lastDevice ?? this.lastDevice,
      // 📋 Расширенный профиль
      preferredCities: preferredCities ?? this.preferredCities,
      budget: budget ?? this.budget,
      targetProfession: targetProfession ?? this.targetProfession,
      financialSituation: financialSituation ?? this.financialSituation,
      hasDisability: hasDisability ?? this.hasDisability,
      isOrphan: isOrphan ?? this.isOrphan,
      isRural: isRural ?? this.isRural,
      extracurriculars: extracurriculars ?? this.extracurriculars,
      profileStrength: profileStrength ?? this.profileStrength,
      // 🎯 ЕНТ направление
      subjectType: subjectType ?? this.subjectType,
      entSubject1: entSubject1 ?? this.entSubject1,
      entSubject2: entSubject2 ?? this.entSubject2,
      specialExamPassed: specialExamPassed ?? this.specialExamPassed,
    );
  }
}
