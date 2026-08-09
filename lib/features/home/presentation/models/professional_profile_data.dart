class ProfessionalProfileData {
  const ProfessionalProfileData({
    required this.id,
    required this.name,
    required this.profession,
    required this.rating,
    required this.reviewCount,
    required this.location,
    this.avatarUrl,
    this.biography = '',
    this.services = const [],
    this.experienceYears = 0,
    this.experienceDescription = '',
    this.portfolio = const [],
    this.completedJobsCount = 0,
    this.reviews = const [],
    this.coverageArea = '',
    this.isVerified = false,
  });

  final String id;
  final String name;
  final String profession;
  final double rating;
  final int reviewCount;
  final String location;
  final String? avatarUrl;
  final String biography;
  final List<String> services;
  final int experienceYears;
  final String experienceDescription;
  final List<String> portfolio;
  final int completedJobsCount;
  final List<ProfessionalReviewData> reviews;
  final String coverageArea;
  final bool isVerified;

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
      avatarUrl: avatarUrl,
      biography: biography,
      services: services,
      experienceYears: experienceYears,
      experienceDescription: experienceDescription,
      portfolio: portfolio,
      completedJobsCount: completedJobsCount,
      reviews: reviews,
      coverageArea: coverageArea,
      isVerified: isVerified,
    );
  }
}

class ProfessionalReviewData {
  const ProfessionalReviewData({
    required this.stars,
    required this.createdAt,
    this.comment,
  });

  final int stars;
  final String? comment;
  final DateTime createdAt;
}
