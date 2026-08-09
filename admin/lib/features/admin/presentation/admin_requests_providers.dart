import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko/features/admin/domain/admin_request.dart';
import 'package:linko_admin/features/admin/presentation/admin_repositories_provider.dart';

final adminRequestsRepositoryProvider = Provider<AdminRequestsRepository>(
  (ref) => ref.watch(adminRepositoriesProvider).requests,
);

final adminRequestsProvider = FutureProvider<List<AdminRequest>>(
  (ref) => ref.watch(adminRequestsRepositoryProvider).listRequests(),
);

final adminRequestOperationsProvider = Provider(
  (ref) => AdminRequestOperations(ref),
);

class AdminRequestOperations {
  const AdminRequestOperations(this._ref);
  final Ref _ref;
  Future<void> perform(
    String id,
    AdminRequestAction action,
    String note,
  ) async {
    await _ref
        .read(adminRequestsRepositoryProvider)
        .performAction(id, action, note);
    _ref.invalidate(adminRequestsProvider);
  }
}
