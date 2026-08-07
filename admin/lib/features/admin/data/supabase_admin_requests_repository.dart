import 'package:linko_admin/features/admin/domain/admin_request.dart';
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
  );
}
