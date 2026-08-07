import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko_admin/features/admin/domain/admin_user.dart';
import 'package:linko_admin/features/admin/domain/admin_users_repository.dart';
import 'package:linko_admin/features/admin/presentation/admin_repositories_provider.dart';

final adminUsersRepositoryProvider = Provider<AdminUsersRepository>(
  (ref) => ref.watch(adminRepositoriesProvider).users,
);

final adminUserQueryProvider =
    NotifierProvider<AdminUserQueryController, AdminUserQuery>(
      AdminUserQueryController.new,
    );

class AdminUserQueryController extends Notifier<AdminUserQuery> {
  @override
  AdminUserQuery build() => const AdminUserQuery();

  void search(String search) => state = state.copyWith(search: search);

  void status(AdminAccountStatus? status) =>
      state = state.copyWith(status: status, clearStatus: status == null);

  void accountType(AdminAccountType? accountType) => state = state.copyWith(
    accountType: accountType,
    clearAccountType: accountType == null,
  );
}

final adminUsersProvider = FutureProvider<List<AdminUser>>((ref) {
  final query = ref.watch(adminUserQueryProvider);
  return ref.watch(adminUsersRepositoryProvider).listUsers(query);
});

final adminUserDetailProvider = FutureProvider.family<AdminUserDetail?, String>(
  (ref, userId) => ref.watch(adminUsersRepositoryProvider).getUser(userId),
);

class AdminUserActions {
  const AdminUserActions(this.ref);

  final Ref ref;

  Future<void> suspend(String userId) => _run(
    userId,
    () => ref.read(adminUsersRepositoryProvider).suspendUser(userId),
  );

  Future<void> reactivate(String userId) => _run(
    userId,
    () => ref.read(adminUsersRepositoryProvider).reactivateUser(userId),
  );

  Future<void> resetOnboarding(String userId) => _run(
    userId,
    () => ref.read(adminUsersRepositoryProvider).resetOnboarding(userId),
  );

  Future<void> _run(String userId, Future<void> Function() operation) async {
    await operation();
    ref
      ..invalidate(adminUsersProvider)
      ..invalidate(adminUserDetailProvider(userId));
  }
}

final adminUserActionsProvider = Provider<AdminUserActions>(
  AdminUserActions.new,
);
