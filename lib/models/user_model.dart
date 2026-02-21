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

  // 💎 Subscription & AI Limits
  final String subscriptionPlan; // 'free', 'pro', 'premium'
  final int aiTokensRemaining;
  final DateTime? lastTokenResetDate;

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
    this.aiTokensRemaining = 5, // Default for free users
    this.lastTokenResetDate,
  });

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
      'gpa': gpa, // ⭐
      'mathScore': mathScore, // ⭐
      'photoUrl': photoUrl, // ⭐
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
      untScore: map['untScore'],
      ieltsScore: (map['ieltsScore'] is String)
          ? double.tryParse(map['ieltsScore'])
          : (map['ieltsScore'] as num?)?.toDouble(),
      gpa: (map['gpa'] is String)
          ? double.tryParse(map['gpa'])
          : (map['gpa'] as num?)?.toDouble(),
      mathScore: (map['mathScore'] is String)
          ? int.tryParse(map['mathScore'])
          : map['mathScore'] as int?,
      photoUrl: map['photoUrl'], // ⭐
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
      aiTokensRemaining: map['aiTokensRemaining'] ?? 5,
      lastTokenResetDate: map['lastTokenResetDate'] != null
          ? (map['lastTokenResetDate'] as Timestamp).toDate()
          : null,
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
    double? gpa, // ⭐
    int? mathScore, // ⭐
    String? photoUrl, // ⭐
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? favoriteUniversities,
    List<String>? achievements, // ⭐
    List<String>? preferredMajors, // ⭐
    String? role, // 🔐
    bool? banned, // 🚫
    String? banReason, // 📝
    String? subscriptionPlan,
    int? aiTokensRemaining,
    DateTime? lastTokenResetDate,
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
      gpa: gpa ?? this.gpa, // ⭐
      mathScore: mathScore ?? this.mathScore, // ⭐
      photoUrl: photoUrl ?? this.photoUrl, // ⭐
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
    );
  }
}
