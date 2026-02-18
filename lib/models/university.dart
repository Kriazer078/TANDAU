class University {
  final String id;
  final String name;
  final String city;
  final String logoUrl;
  final List<String> imageUrls;
  final List<String> majors;
  final int passingScore;
  final String tuitionRange; // e.g., "500,000 - 1,200,000 ₸"
  final bool hasDormitory;
  final bool hasGrants;
  final String description;
  final List<String> requirements;
  final String applicationDeadline;
  final String address;
  final String website;
  final double rating;
  final int studentCount;

  // ⭐ Новые поля для лайков и отзывов
  final int likesCount; // Количество лайков
  final int reviewsCount; // Количество отзывов
  final double averageRating; // Средний рейтинг из отзывов (1-5)

  University({
    required this.id,
    required this.name,
    required this.city,
    required this.logoUrl,
    required this.imageUrls,
    required this.majors,
    required this.passingScore,
    required this.tuitionRange,
    required this.hasDormitory,
    required this.hasGrants,
    required this.description,
    required this.requirements,
    required this.applicationDeadline,
    required this.address,
    required this.website,
    required this.rating,
    required this.studentCount,
    this.likesCount = 0, // По умолчанию 0
    this.reviewsCount = 0, // По умолчанию 0
    this.averageRating = 0.0, // По умолчанию 0.0
  });

  // Convert University to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'logoUrl': logoUrl,
      'imageUrls': imageUrls,
      'majors': majors,
      'passingScore': passingScore,
      'tuitionRange': tuitionRange,
      'hasDormitory': hasDormitory,
      'hasGrants': hasGrants,
      'description': description,
      'requirements': requirements,
      'applicationDeadline': applicationDeadline,
      'address': address,
      'website': website,
      'rating': rating,
      'studentCount': studentCount,
      'likesCount': likesCount,
      'reviewsCount': reviewsCount,
      'averageRating': averageRating,
    };
  }

  // Create University from Firestore document
  factory University.fromMap(Map<String, dynamic> map) {
    return University(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      city: map['city'] ?? '',
      logoUrl: map['logoUrl'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      majors: List<String>.from(map['majors'] ?? []),
      passingScore: map['passingScore'] ?? 0,
      tuitionRange: map['tuitionRange'] ?? '',
      hasDormitory: map['hasDormitory'] ?? false,
      hasGrants: map['hasGrants'] ?? false,
      description: map['description'] ?? '',
      requirements: List<String>.from(map['requirements'] ?? []),
      applicationDeadline: map['applicationDeadline'] ?? '',
      address: map['address'] ?? '',
      website: map['website'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      studentCount: map['studentCount'] ?? 0,
      likesCount: map['likesCount'] ?? 0,
      reviewsCount: map['reviewsCount'] ?? 0,
      averageRating: (map['averageRating'] ?? 0.0).toDouble(),
    );
  }

  double get maxTuitionValue {
    // Remove separators and symbols to parse pure numbers
    // Example: "500 000 - 1 200 000 ₸" -> "500000-1200000"
    final clean = tuitionRange.replaceAll(RegExp(r'[^\d-]'), '');
    final parts = clean.split('-');
    if (parts.isEmpty || parts.last.isEmpty) return 0;
    return double.tryParse(parts.last) ?? 0;
  }

  // Helper method to check if university matches filters
  bool matchesFilters({
    List<String>? cityFilter,
    List<String>? majorFilter,
    bool? onlyGrants,
    double? maxPrice,
  }) {
    if (cityFilter != null &&
        cityFilter.isNotEmpty &&
        !cityFilter.contains(city)) {
      return false;
    }

    if (majorFilter != null && majorFilter.isNotEmpty) {
      bool majorMatch = majors.any(
        (major) => majorFilter.any(
          (filter) => major.toLowerCase().contains(filter.toLowerCase()),
        ),
      );
      if (!majorMatch) return false;
    }

    // Logic for Education Type:
    // If BOTH specified, it's (Grant) OR (Paid within Price)
    // If only one, strict filter.
    final bool filterByGrant = onlyGrants == true;
    final bool filterByPrice = maxPrice != null && maxPrice > 0;

    if (filterByGrant && filterByPrice) {
      final bool matchesPrice =
          maxTuitionValue > 0 && maxTuitionValue <= maxPrice;
      if (!hasGrants && !matchesPrice) return false;
    } else if (filterByGrant) {
      if (!hasGrants) return false;
    } else if (filterByPrice) {
      final bool matchesPrice =
          maxTuitionValue > 0 && maxTuitionValue <= maxPrice;
      if (!matchesPrice) return false;
    }

    return true;
  }

  // Helper method for search
  bool matchesSearch(String query) {
    final lowerQuery = query.toLowerCase();
    return name.toLowerCase().contains(lowerQuery) ||
        city.toLowerCase().contains(lowerQuery) ||
        majors.any((major) => major.toLowerCase().contains(lowerQuery));
  }
}
