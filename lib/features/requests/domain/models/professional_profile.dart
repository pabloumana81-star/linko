import 'package:linko/features/requests/domain/models/app_user.dart';

class ProfessionalProfile {
  const ProfessionalProfile({
    required this.id,
    required this.user,
    required this.profession,
    required this.rating,
    required this.reviewCount,
    required this.location,
    this.isVerified = false,
    this.avatarUrl,
    this.biography = '',
    this.services = const [],
    this.experienceYears = 0,
    this.experienceDescription = '',
    this.portfolio = const [],
    this.completedJobsCount = 0,
    this.reviews = const [],
    this.coverageArea = '',
  });

  final String id;
  final AppUser user;
  final String profession;
  final double rating;
  final int reviewCount;
  final String location;
  final bool isVerified;
  final String? avatarUrl;
  final String biography;
  final List<String> services;
  final int experienceYears;
  final String experienceDescription;
  final List<String> portfolio;
  final int completedJobsCount;
  final List<ProfessionalReview> reviews;
  final String coverageArea;
}

class ProfessionalReview {
  const ProfessionalReview({
    required this.stars,
    required this.createdAt,
    this.comment,
  });

  final int stars;
  final String? comment;
  final DateTime createdAt;
}

class ProfessionalProfileUpdate {
  const ProfessionalProfileUpdate({
    required this.profession,
    required this.location,
    required this.biography,
    required this.services,
    required this.experienceYears,
    required this.experienceDescription,
    required this.coverageArea,
  });

  final String profession;
  final String location;
  final String biography;
  final List<String> services;
  final int experienceYears;
  final String experienceDescription;
  final String coverageArea;
}
