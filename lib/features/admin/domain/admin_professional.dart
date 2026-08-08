import 'package:linko/features/admin/domain/admin_user.dart';

enum ProfessionalVerificationStatus { pending, verified, rejected }

extension ProfessionalVerificationLabel on ProfessionalVerificationStatus {
  String get label => switch (this) {
    ProfessionalVerificationStatus.pending => 'Pendiente',
    ProfessionalVerificationStatus.verified => 'Verificado',
    ProfessionalVerificationStatus.rejected => 'Rechazado',
  };
}

enum ProfessionalRatingFilter { topRated, lowRated }

class AdminProfessionalQuery {
  const AdminProfessionalQuery({
    this.search = '',
    this.verification,
    this.accountStatus,
    this.rating,
  });

  final String search;
  final ProfessionalVerificationStatus? verification;
  final AdminAccountStatus? accountStatus;
  final ProfessionalRatingFilter? rating;
}

class AdminProfessional {
  const AdminProfessional({
    required this.id,
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.categories,
    required this.verification,
    required this.averageRating,
    required this.completedJobs,
    required this.activeJobs,
    required this.registeredAt,
    required this.accountStatus,
  });

  final String id;
  final String name;
  final String? email;
  final String? photoUrl;
  final List<String> categories;
  final ProfessionalVerificationStatus verification;
  final double averageRating;
  final int completedJobs;
  final int activeJobs;
  final DateTime registeredAt;
  final AdminAccountStatus accountStatus;
}

class AdminProfessionalDetail {
  const AdminProfessionalDetail({
    required this.professional,
    required this.profession,
    required this.location,
    required this.coverageArea,
    required this.experienceYears,
    required this.skills,
    required this.portfolio,
    required this.verificationDocuments,
    required this.reviewCount,
    required this.reviews,
    required this.cancelledJobs,
    required this.currentRequests,
    required this.conversationCount,
    required this.timeline,
  });

  final AdminProfessional professional;
  final String profession;
  final String location;
  final String coverageArea;
  final int experienceYears;
  final List<String> skills;
  final List<String> portfolio;
  final List<String> verificationDocuments;
  final int reviewCount;
  final List<String> reviews;
  final int cancelledJobs;
  final List<String> currentRequests;
  final int conversationCount;
  final List<ProfessionalAuditEntry> timeline;
}

enum ProfessionalAuditAction {
  verificationApproved,
  verificationRejected,
  additionalInformationRequested,
  accountSuspended,
  accountReactivated,
}

extension ProfessionalAuditActionLabel on ProfessionalAuditAction {
  String get label => switch (this) {
    ProfessionalAuditAction.verificationApproved => 'Verificación aprobada',
    ProfessionalAuditAction.verificationRejected => 'Verificación rechazada',
    ProfessionalAuditAction.additionalInformationRequested =>
      'Información adicional solicitada',
    ProfessionalAuditAction.accountSuspended => 'Cuenta suspendida',
    ProfessionalAuditAction.accountReactivated => 'Cuenta reactivada',
  };
}

class ProfessionalAuditEntry {
  const ProfessionalAuditEntry({
    required this.id,
    required this.adminId,
    required this.professionalId,
    required this.action,
    required this.previousValue,
    required this.newValue,
    required this.timestamp,
  });

  final String id;
  final String adminId;
  final String professionalId;
  final ProfessionalAuditAction action;
  final String previousValue;
  final String newValue;
  final DateTime timestamp;
}
