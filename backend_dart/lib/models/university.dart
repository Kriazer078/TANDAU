class University {
  final String id;
  final String name;
  final String city;
  final String logoUrl;
  final List<String> imageUrls;
  final List<String> subjects; // aka majors
  final int minScore; // aka passingScore
  final String price; // aka tuitionRange
  final bool hasGrants;
  final bool hasDormitory;
  final bool hasMilitaryDepartment;
  final int? dormitoryPrice;
  final double? latitude;
  final double? longitude;
  final String description;
  final String website;
  final double rating;
  final int studentCount;
  final String contactPhone;
  final String email;
  final List<String> specialtyCodes;

  University({
    required this.id,
    required this.name,
    required this.city,
    required this.logoUrl,
    required this.imageUrls,
    required this.subjects,
    required this.minScore,
    required this.price,
    required this.hasGrants,
    required this.hasDormitory,
    this.hasMilitaryDepartment = false,
    this.dormitoryPrice,
    this.latitude,
    this.longitude,
    required this.description,
    required this.website,
    required this.rating,
    required this.studentCount,
    this.contactPhone = '',
    this.email = '',
    this.specialtyCodes = const [],
  });

  factory University.fromJson(Map<String, dynamic> json, String id) {
    return University(
      id: id,
      name: json['name'] as String? ?? 'Unknown University',
      city: json['city'] as String? ?? 'Unknown City',
      logoUrl: json['logoUrl'] as String? ?? '',
      imageUrls: (json['imageUrls'] as List?)?.map((e) => e.toString()).toList() ?? [],
      subjects: (json['subjects'] as List?)?.map((e) => e.toString()).toList() ?? 
                (json['majors'] as List?)?.map((e) => e.toString()).toList() ?? [],
      minScore: json['min_score'] as int? ?? (json['passingScore'] as int? ?? 0),
      price: json['price'] as String? ?? (json['tuitionRange'] as String? ?? '0'),
      hasGrants: json['has_grants'] as bool? ?? (json['hasGrants'] as bool? ?? false),
      hasDormitory: json['hasDormitory'] as bool? ?? false,
      hasMilitaryDepartment: json['hasMilitaryDepartment'] as bool? ?? false,
      dormitoryPrice: json['dormitoryPrice'] as int?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      description: json['description'] as String? ?? '',
      website: json['website'] as String? ?? '',
      rating: (json['averageRating'] as num?)?.toDouble() ?? (json['rating'] as num?)?.toDouble() ?? 0.0,
      studentCount: json['studentCount'] as int? ?? 0,
      contactPhone: json['contactPhone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      specialtyCodes: (json['specialtyCodes'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'logoUrl': logoUrl,
      'imageUrls': imageUrls,
      'subjects': subjects,
      'min_score': minScore,
      'price': price,
      'has_grants': hasGrants,
      'hasDormitory': hasDormitory,
      'hasMilitaryDepartment': hasMilitaryDepartment,
      'dormitoryPrice': dormitoryPrice,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'website': website,
      'rating': rating,
      'studentCount': studentCount,
      'contactPhone': contactPhone,
      'email': email,
      'specialtyCodes': specialtyCodes,
    };
  }
}

