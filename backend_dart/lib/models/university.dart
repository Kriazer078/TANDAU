class University {
  final String id;
  final String name;
  final String city;
  final List<String> subjects;
  final int minScore;
  final String price;
  final bool hasGrants;
  final String description;
  final String website;
  final double rating;

  University({
    required this.id,
    required this.name,
    required this.city,
    required this.subjects,
    required this.minScore,
    required this.price,
    required this.hasGrants,
    required this.description,
    required this.website,
    required this.rating,
  });

  factory University.fromJson(Map<String, dynamic> json, String id) {
    return University(
      id: id,
      name: json['name'] as String? ?? 'Unknown University',
      city: json['city'] as String? ?? 'Unknown City',
      subjects:
          (json['subjects'] as List?)?.map((e) => e.toString()).toList() ?? [],
      minScore: json['min_score'] as int? ?? 0,
      price: json['price'] as String? ?? '0',
      hasGrants: json['has_grants'] as bool? ?? false,
      description: json['description'] as String? ?? '',
      website: json['website'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'city': city,
      'subjects': subjects,
      'min_score': minScore,
      'price': price,
      'has_grants': hasGrants,
      'description': description,
      'website': website,
      'rating': rating,
    };
  }
}
