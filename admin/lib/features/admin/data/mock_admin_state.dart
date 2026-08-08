import 'package:linko/core/backend/data/professional_availability_store.dart';
import 'package:linko/features/admin/domain/admin_professional.dart';
import 'package:linko/features/admin/domain/admin_user.dart';

class MockAdminState {
  MockAdminState({ProfessionalAvailabilityStore? availability})
    : availability = availability ?? ProfessionalAvailabilityStore();

  final ProfessionalAvailabilityStore availability;
  final verification = <String, ProfessionalVerificationStatus>{};
  final professionalStatuses = <String, AdminAccountStatus>{};
  final professionalAudit = <ProfessionalAuditEntry>[];
}
