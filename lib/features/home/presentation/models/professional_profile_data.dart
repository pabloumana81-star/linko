class ProfessionalProfileData {
  const ProfessionalProfileData({
    required this.id,
    required this.name,
    required this.profession,
    required this.rating,
    required this.reviewCount,
    required this.location,
  });

  final String id;
  final String name;
  final String profession;
  final double rating;
  final int reviewCount;
  final String location;

  ProfessionalProfileData copyWith({
    String? profession,
    double? rating,
    int? reviewCount,
  }) {
    return ProfessionalProfileData(
      id: id,
      name: name,
      profession: profession ?? this.profession,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      location: location,
    );
  }
}
