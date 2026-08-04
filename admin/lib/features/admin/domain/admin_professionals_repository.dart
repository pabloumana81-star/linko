import 'package:linko_admin/features/admin/domain/admin_professional.dart';

abstract interface class AdminProfessionalsRepository {
  Future<List<AdminProfessional>> listProfessionals(
    AdminProfessionalQuery query,
  );

  Future<AdminProfessionalDetail?> getProfessional(String professionalId);

  Future<void> approveVerification(String professionalId);
  Future<void> rejectVerification(String professionalId);
  Future<void> suspendProfessional(String professionalId);
  Future<void> reactivateProfessional(String professionalId);
  Future<List<ProfessionalAuditEntry>> getAuditLog(String professionalId);
}
