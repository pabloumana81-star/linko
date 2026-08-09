class AdminRequest {
  const AdminRequest({
    required this.id,
    required this.title,
    required this.category,
    required this.status,
    required this.customerName,
    required this.professionalName,
    required this.createdAt,
    required this.updatedAt,
    this.description = '',
    this.scheduledAt,
    this.adminReviewFlag = false,
    this.auditHistory = const [],
  });

  final String id;
  final String title;
  final String category;
  final String status;
  final String customerName;
  final String professionalName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String description;
  final DateTime? scheduledAt;
  final bool adminReviewFlag;
  final List<AdminRequestAuditEntry> auditHistory;
}

class AdminRequestAuditEntry {
  const AdminRequestAuditEntry({
    required this.id,
    required this.adminId,
    required this.action,
    required this.previousStatus,
    required this.newStatus,
    required this.note,
    required this.createdAt,
  });
  final String id, adminId, action, previousStatus, newStatus, note;
  final DateTime createdAt;
}

enum AdminRequestAction { flagForReview, addInterventionNote, cancel }

abstract interface class AdminRequestsRepository {
  Future<List<AdminRequest>> listRequests();
  Future<void> performAction(
    String requestId,
    AdminRequestAction action,
    String note,
  );
}
