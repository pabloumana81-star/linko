import 'package:linko_admin/features/admin/domain/admin_user.dart';
import 'package:linko_admin/features/admin/domain/admin_users_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAdminUsersRepository implements AdminUsersRepository {
  SupabaseAdminUsersRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<AdminUser>> listUsers(AdminUserQuery query) async {
    final response = await _client.rpc(
      'list_admin_users',
      params: {
        'p_search': query.search.trim(),
        'p_status': query.status?.name,
        'p_account_type': query.accountType?.name,
      },
    );
    return List.unmodifiable(
      (response as List).map(
        (row) =>
            AdminUserSupabaseMapper.user(Map<String, dynamic>.from(row as Map)),
      ),
    );
  }

  @override
  Future<AdminUserDetail?> getUser(String userId) async {
    final response = await _client.rpc(
      'get_admin_user_detail',
      params: {'p_user_id': userId},
    );
    if (response == null) return null;
    final data = Map<String, dynamic>.from(response as Map);
    return AdminUserDetail(
      user: AdminUserSupabaseMapper.user(
        Map<String, dynamic>.from(data['user'] as Map),
      ),
      activeRequests: (data['active_requests'] as num).toInt(),
      completedRequests: (data['completed_requests'] as num).toInt(),
      ratings: (data['ratings'] as num).toInt(),
      reports: (data['reports'] as num).toInt(),
      onboardingCompleted: data['onboarding_completed'] as bool,
      history: (data['history'] as List? ?? const [])
          .map(
            (row) => AdminUserSupabaseMapper.audit(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList(),
    );
  }

  @override
  Future<void> suspendUser(String userId) =>
      _action(userId, 'accountSuspended');

  @override
  Future<void> reactivateUser(String userId) =>
      _action(userId, 'accountReactivated');

  @override
  Future<void> resetOnboarding(String userId) =>
      _action(userId, 'onboardingReset');

  @override
  Future<List<AdminAuditEntry>> getAuditLog(String userId) async {
    final detail = await getUser(userId);
    return detail?.history ?? const [];
  }

  Future<void> _action(String userId, String action) async {
    await _client.rpc(
      'perform_admin_user_action',
      params: {'p_user_id': userId, 'p_action': action},
    );
  }
}

class AdminUserSupabaseMapper {
  const AdminUserSupabaseMapper._();

  static AdminUser user(Map<String, dynamic> row) => AdminUser(
    id: row['id'] as String,
    name: row['name'] as String,
    email: row['email'] as String?,
    avatarUrl: row['avatar_url'] as String?,
    accountType: AdminAccountType.values.byName(row['account_type'] as String),
    status: AdminAccountStatus.values.byName(row['status'] as String),
    registeredAt: DateTime.parse(row['registered_at'] as String).toLocal(),
    lastLoginAt: row['last_login_at'] == null
        ? null
        : DateTime.parse(row['last_login_at'] as String).toLocal(),
  );

  static AdminAuditEntry audit(Map<String, dynamic> row) => AdminAuditEntry(
    id: row['id'] as String,
    adminId: row['admin_id'] as String,
    userId: row['user_id'] as String,
    action: AdminAuditAction.values.byName(row['action'] as String),
    timestamp: DateTime.parse(row['timestamp'] as String).toLocal(),
  );
}
