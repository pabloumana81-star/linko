import 'package:linko/features/admin/domain/admin_request.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAdminRequestsRepository implements AdminRequestsRepository {
  const SupabaseAdminRequestsRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<AdminRequest>> listRequests() async {
    final response = await _client.rpc('list_admin_requests');
    return List.unmodifiable(
      (response as List).map(
        (row) => AdminRequestSupabaseMapper.fromRow(
          Map<String, dynamic>.from(row as Map),
        ),
      ),
    );
  }

  @override
  Future<void> performAction(
    String requestId,
    AdminRequestAction action,
    String note,
  ) => _client.rpc(
    'perform_admin_request_action',
    params: {
      'p_request_id': requestId,
      'p_action': action.name,
      'p_note': note,
    },
  );
}

class AdminRequestSupabaseMapper {
  const AdminRequestSupabaseMapper._();

  static AdminRequest fromRow(Map<String, dynamic> row) => AdminRequest(
    id: row['id'] as String,
    title: row['title'] as String,
    category: row['category'] as String,
    status: row['status'] as String,
    customerName: row['customer_name'] as String,
    professionalName: row['professional_name'] as String,
    createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
    updatedAt: DateTime.parse(row['updated_at'] as String).toLocal(),
    description: row['description'] as String? ?? '',
    scheduledAt: row['scheduled_at'] == null
        ? null
        : DateTime.parse(row['scheduled_at'] as String).toLocal(),
    adminReviewFlag: row['admin_review_flag'] as bool? ?? false,
    auditHistory: ((row['audit_history'] as List?) ?? const [])
        .map((value) {
          final audit = Map<String, dynamic>.from(value as Map);
          return AdminRequestAuditEntry(
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
