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
  final String? photoUrl; // ⭐ URL фото профиля
  final List<String> favoriteUniversities;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.age,
    this.education,
    this.city,
    this.untScore,
    this.ieltsScore,
    this.photoUrl, // ⭐
    required this.createdAt,
    this.updatedAt,
    this.favoriteUniversities = const [],
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
      'photoUrl': photoUrl, // ⭐
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'favoriteUniversities': favoriteUniversities,
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
      ieltsScore: (map['ieltsScore'] as num?)?.toDouble(),
      photoUrl: map['photoUrl'], // ⭐
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      favoriteUniversities: List<String>.from(
        map['favoriteUniversities'] ?? [],
      ),
    );
  }

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
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
    String? photoUrl, // ⭐
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? favoriteUniversities,
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
      photoUrl: photoUrl ?? this.photoUrl, // ⭐
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      favoriteUniversities: favoriteUniversities ?? this.favoriteUniversities,
    );
  }
}
