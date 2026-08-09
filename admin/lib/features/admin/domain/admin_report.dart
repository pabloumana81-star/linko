class AdminReport {
  const AdminReport({
    required this.id,
    required this.reporterName,
    required this.requestTitle,
    required this.reason,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.auditHistory = const [],
  });

  final String id;
  final String reporterName;
  final String? requestTitle;
  final String reason;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<AdminReportAuditEntry> auditHistory;
}

class AdminReportAuditEntry {
  const AdminReportAuditEntry({
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

enum AdminReportAction { resolve, dismiss, escalate }

abstract interface class AdminReportsRepository {
  Future<List<AdminReport>> listReports();
  Future<void> performAction(
    String reportId,
    AdminReportAction action,
    String note,
  );
}
