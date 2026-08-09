import 'package:linko_admin/features/admin/domain/admin_report.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAdminReportsRepository implements AdminReportsRepository {
  const SupabaseAdminReportsRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<AdminReport>> listReports() async {
    final response = await _client.rpc('list_admin_reports');
    return List.unmodifiable(
      (response as List).map(
        (row) => AdminReportSupabaseMapper.fromRow(
          Map<String, dynamic>.from(row as Map),
        ),
      ),
    );
  }

  @override
  Future<void> performAction(
    String reportId,
    AdminReportAction action,
    String note,
  ) => _client.rpc(
    'perform_admin_report_action',
    params: {'p_report_id': reportId, 'p_action': action.name, 'p_note': note},
  );
}

class AdminReportSupabaseMapper {
  const AdminReportSupabaseMapper._();

  static AdminReport fromRow(Map<String, dynamic> row) => AdminReport(
    id: row['id'] as String,
    reporterName: row['reporter_name'] as String,
    requestTitle: row['request_title'] as String?,
    reason: row['reason'] as String,
    status: row['status'] as String,
    createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
    updatedAt: DateTime.parse(row['updated_at'] as String).toLocal(),
    auditHistory: ((row['audit_history'] as List?) ?? const [])
        .map((value) {
          final audit = Map<String, dynamic>.from(value as Map);
          return AdminReportAuditEntry(
            id: audit['id'] as String,
            adminId: audit['admin_id'] as String,
            action: audit['action'] as String,
            previousStatus: audit['previous_status'] as String,
            newStatus: audit['new_status'] as String,
            note: audit['note'] as String,
            createdAt: DateTime.parse(audit['created_at'] as String).toLocal(),
          );
        })
        .toList(growable: false),
  );
}
