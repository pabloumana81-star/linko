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
  );
}
