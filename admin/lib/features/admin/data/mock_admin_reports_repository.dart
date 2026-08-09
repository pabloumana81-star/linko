import 'package:linko_admin/features/admin/domain/admin_report.dart';

class MockAdminReportsRepository implements AdminReportsRepository {
  MockAdminReportsRepository({List<AdminReport>? seed}) : _reports = [...?seed];

  final List<AdminReport> _reports;

  @override
  Future<List<AdminReport>> listReports() async => List.unmodifiable(_reports);

  @override
  Future<void> performAction(
    String reportId,
    AdminReportAction action,
    String note,
  ) async {
    if (note.trim().isEmpty) {
      throw ArgumentError('Debes indicar una nota o motivo.');
    }
    final index = _reports.indexWhere((item) => item.id == reportId);
    if (index < 0) throw StateError('Reporte no encontrado.');
    final current = _reports[index];
    if (current.status == 'resolved' || current.status == 'dismissed') {
      throw StateError('El reporte ya está cerrado.');
    }
    final next = switch (action) {
      AdminReportAction.resolve => 'resolved',
      AdminReportAction.dismiss => 'dismissed',
      AdminReportAction.escalate => 'escalated',
    };
    if (current.status == next) {
      throw StateError('El reporte ya tiene ese estado.');
    }
    final now = DateTime.now();
    _reports[index] = AdminReport(
      id: current.id,
      reporterName: current.reporterName,
      requestTitle: current.requestTitle,
      reason: current.reason,
      status: next,
      createdAt: current.createdAt,
      updatedAt: now,
      auditHistory: [
        AdminReportAuditEntry(
          id: 'audit-${current.auditHistory.length + 1}',
          adminId: 'admin-current',
          action: next,
          previousStatus: current.status,
          newStatus: next,
          note: note.trim(),
          createdAt: now,
        ),
        ...current.auditHistory,
      ],
    );
  }
}
