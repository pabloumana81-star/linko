class ProfessionalProfileData {
  const ProfessionalProfileData({
    required this.name,
    required this.profession,
    required this.rating,
    required this.reviewCount,
    required this.location,
  });

  final String name;
  final String profession;
  final double rating;
  final int reviewCount;
  final String location;

  ProfessionalProfileData copyWith({String? profession}) {
    return ProfessionalProfileData(
      name: name,
      profession: profession ?? this.profession,
      rating: rating,
      reviewCount: reviewCount,
      location: location,
    );
  }
}
