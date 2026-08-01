import 'package:linko/features/requests/domain/models/service_rating.dart';

abstract interface class RatingsRepository {
  Future<ServiceRating?> getRating(String requestId);
  Future<void> submitRating(ServiceRating rating);
  Future<ProfessionalRatingSummary> getProfessionalSummary(
    String professionalId,
  );
}
