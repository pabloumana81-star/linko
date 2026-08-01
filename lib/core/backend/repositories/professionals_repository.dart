import 'package:linko/features/requests/domain/models/professional_profile.dart';

abstract interface class ProfessionalsRepository {
  Future<List<ProfessionalProfile>> getProfessionals();
  Future<ProfessionalProfile?> getProfessionalById(String professionalId);
}
