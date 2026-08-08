import 'package:linko/features/admin/domain/admin_user.dart';

abstract interface class AdminUsersRepository {
  Future<List<AdminUser>> listUsers(AdminUserQuery query);

  Future<AdminUserDetail?> getUser(String userId);

  Future<void> suspendUser(String userId);

  Future<void> reactivateUser(String userId);

  Future<void> resetOnboarding(String userId);

  Future<List<AdminAuditEntry>> getAuditLog(String userId);
}
