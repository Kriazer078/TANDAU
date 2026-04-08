class ComparisonItem {
  final String userId;
  final List<String> universityIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  ComparisonItem({
    required this.userId,
    required this.universityIds,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'universityIds': universityIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from Firestore document
  factory ComparisonItem.fromMap(Map<String, dynamic> map) {
    return ComparisonItem(
      userId: map['userId'] ?? '',
      universityIds: List<String>.from(map['universityIds'] ?? []),
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        map['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  // Copy with method for easy updates
  ComparisonItem copyWith({
    String? userId,
    List<String>? universityIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ComparisonItem(
      userId: userId ?? this.userId,
      universityIds: universityIds ?? this.universityIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
