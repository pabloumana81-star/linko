import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko/features/admin/domain/admin_request.dart';
import 'package:linko_admin/features/admin/presentation/admin_repositories_provider.dart';

final adminRequestsRepositoryProvider = Provider<AdminRequestsRepository>(
  (ref) => ref.watch(adminRepositoriesProvider).requests,
);

final adminRequestsProvider = FutureProvider<List<AdminRequest>>(
  (ref) => ref.watch(adminRequestsRepositoryProvider).listRequests(),
);
