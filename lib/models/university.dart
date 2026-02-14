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

  // Helper method to check if university matches filters
  bool matchesFilters({
    List<String>? cityFilter,
    List<String>? majorFilter,
    List<String>? budgetFilter,
  }) {
    if (cityFilter != null &&
        cityFilter.isNotEmpty &&
        !cityFilter.contains(city)) {
      return false;
    }

    if (majorFilter != null && majorFilter.isNotEmpty) {
      bool majorMatch = false;
      for (var filter in majorFilter) {
        if (majors.any(
          (major) => major.toLowerCase().contains(filter.toLowerCase()),
        )) {
          majorMatch = true;
          break;
        }
      }
      if (!majorMatch) return false;
    }

    if (budgetFilter != null && budgetFilter.isNotEmpty) {
      // Budget matching logic
      // This is a simplified example. In a real app, you'd compare numeric values.
      bool budgetMatch = false;
      for (var filter in budgetFilter) {
        if (filter.contains('500,000') &&
            (tuitionRange.contains('Грант') || passingScore < 100)) {
          budgetMatch = true;
          break;
        }
        // Add more budget cases as needed
      }
      // If we have budget filters, at least one selection should satisfy
      if (!budgetMatch) return false;
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
