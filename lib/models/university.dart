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
  final int? dormitoryPrice; // Цена общежития (тенге/месяц)
  final bool dormitoryForFreshmen; // 100% общежитие первокурсникам?
  final int? dormitoryPriceYear; // Стоимость за ГОД (₸)
  final List<String> dormitoryPhotoUrls; // Фото комнат
  final String? dormitoryDistanceInfo; // "500м от главного корпуса"
  final String? dormitoryDescription; // Описание условий
  final bool hasGrants;
  final bool hasMilitaryDepartment;
  final int? militaryStartCourse; // С какого курса военная кафедра
  final String? militaryCompetition; // Конкурс на военную кафедру
  final double? latitude; // GPS-координаты
  final double? longitude;
  final String description;
  final List<String> requirements;
  final String applicationDeadline;
  final String address;
  final String website;
  // rating удалён — используется averageRating (единый источник)
  // Getter для обратной совместимости:
  double get rating => averageRating;
  final int studentCount;

  // ⭐ Новые поля для лайков и отзывов
  final int likesCount; // Количество лайков
  final int reviewsCount; // Количество отзывов
  final double averageRating; // Средний рейтинг из отзывов (1-5)

  // 📞 Контактные данные
  final String contactPhone; // Телефон университета
  final String email; // Email университета

  // 🎯 ГОП специальности (коды из ent_specialties_2026.dart)
  final List<String> specialtyCodes;

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
    this.dormitoryPrice,
    this.dormitoryForFreshmen = false,
    this.dormitoryPriceYear,
    this.dormitoryPhotoUrls = const [],
    this.dormitoryDistanceInfo,
    this.dormitoryDescription,
    required this.hasGrants,
    this.hasMilitaryDepartment = false,
    this.militaryStartCourse,
    this.militaryCompetition,
    this.latitude,
    this.longitude,
    required this.description,
    required this.requirements,
    required this.applicationDeadline,
    required this.address,
    required this.website,
    // rating больше не передаётся — вычисляется из averageRating
    required this.studentCount,
    this.likesCount = 0, // По умолчанию 0
    this.reviewsCount = 0, // По умолчанию 0
    this.averageRating = 0.0, // По умолчанию 0.0
    this.contactPhone = '', // По умолчанию пусто
    this.email = '', // По умолчанию пусто
    this.specialtyCodes = const [], // По умолчанию пусто
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
      'dormitoryPrice': dormitoryPrice,
      'dormitoryForFreshmen': dormitoryForFreshmen,
      'dormitoryPriceYear': dormitoryPriceYear,
      'dormitoryPhotoUrls': dormitoryPhotoUrls,
      'dormitoryDistanceInfo': dormitoryDistanceInfo,
      'dormitoryDescription': dormitoryDescription,
      'hasGrants': hasGrants,
      'hasMilitaryDepartment': hasMilitaryDepartment,
      'militaryStartCourse': militaryStartCourse,
      'militaryCompetition': militaryCompetition,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'requirements': requirements,
      'applicationDeadline': applicationDeadline,
      'address': address,
      'website': website,
      // rating не сохраняется отдельно — используем averageRating
      'studentCount': studentCount,
      'likesCount': likesCount,
      'reviewsCount': reviewsCount,
      'averageRating': averageRating,
      'contactPhone': contactPhone,
      'email': email,
      'specialtyCodes': specialtyCodes,
    };
  }

  static List<String> _parseStringList(dynamic rawList) {
    if (rawList == null) return [];
    if (rawList is List) {
      return rawList.map((e) {
        if (e is Map) {
          return (e['name'] ?? e['title'] ?? e['id'] ?? e.toString()).toString();
        }
        return e.toString();
      }).toList();
    }
    return [rawList.toString()];
  }

  // Create University from Firestore document
  factory University.fromMap(Map<String, dynamic> map) {
    return University(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      city: map['city']?.toString() ?? '',
      logoUrl: map['logoUrl']?.toString() ?? '',
      imageUrls: _parseStringList(map['imageUrls']),
      majors: _parseStringList(map['majors']),
      passingScore: (map['passingScore'] is int) ? map['passingScore'] : (int.tryParse(map['passingScore']?.toString() ?? '0') ?? 0),
      tuitionRange: map['tuitionRange']?.toString() ?? '',
      hasDormitory: map['hasDormitory'] == true,
      dormitoryPrice: (map['dormitoryPrice'] is int) ? map['dormitoryPrice'] : (int.tryParse(map['dormitoryPrice']?.toString() ?? '')),
      dormitoryForFreshmen: map['dormitoryForFreshmen'] == true,
      dormitoryPriceYear: (map['dormitoryPriceYear'] is int) ? map['dormitoryPriceYear'] : (int.tryParse(map['dormitoryPriceYear']?.toString() ?? '')),
      dormitoryPhotoUrls: _parseStringList(map['dormitoryPhotoUrls']),
      dormitoryDistanceInfo: map['dormitoryDistanceInfo']?.toString(),
      dormitoryDescription: map['dormitoryDescription']?.toString(),
      hasGrants: map['hasGrants'] == true,
      hasMilitaryDepartment: map['hasMilitaryDepartment'] == true,
      militaryStartCourse: (map['militaryStartCourse'] is int)
          ? map['militaryStartCourse']
          : int.tryParse(map['militaryStartCourse']?.toString() ?? ''),
      militaryCompetition: map['militaryCompetition']?.toString(),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      description: map['description']?.toString() ?? '',
      requirements: _parseStringList(map['requirements']),
      applicationDeadline: map['applicationDeadline']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      website: map['website']?.toString() ?? '',
      // rating читается как fallback для averageRating (миграция)
      studentCount: (map['studentCount'] is int) ? map['studentCount'] : (int.tryParse(map['studentCount']?.toString() ?? '0') ?? 0),
      likesCount: (map['likesCount'] is int) ? map['likesCount'] : (int.tryParse(map['likesCount']?.toString() ?? '0') ?? 0),
      reviewsCount: (map['reviewsCount'] is int) ? map['reviewsCount'] : (int.tryParse(map['reviewsCount']?.toString() ?? '0') ?? 0),
      averageRating: ((map['averageRating'] ?? map['rating'] ?? 0.0) as num).toDouble(),
      contactPhone: map['contactPhone']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      specialtyCodes: _parseStringList(map['specialtyCodes']),
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
    bool? onlyMilitary,
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

    // 🎖️ Military department filter
    if (onlyMilitary == true && !hasMilitaryDepartment) {
      return false;
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
