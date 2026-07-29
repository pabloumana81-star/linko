class ServiceRating {
  const ServiceRating({
    required this.requestId,
    required this.professionalId,
    required this.stars,
    required this.comment,
  });

  final String requestId;
  final String professionalId;
  final int stars;
  final String? comment;
}

class ProfessionalRatingSummary {
  const ProfessionalRatingSummary({
    required this.averageRating,
    required this.reviewCount,
    required this.completedJobsCount,
  });

  final double averageRating;
  final int reviewCount;
  final int completedJobsCount;
}
