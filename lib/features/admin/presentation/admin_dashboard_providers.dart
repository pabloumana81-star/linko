import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko/core/backend/backend_config.dart';
import 'package:linko/core/backend/backend_providers.dart';
import 'package:linko/features/admin/data/mock_admin_dashboard_repository.dart';
import 'package:linko/features/admin/data/supabase_admin_dashboard_repository.dart';
import 'package:linko/features/admin/domain/admin_dashboard.dart';
import 'package:linko/features/admin/domain/admin_dashboard_repository.dart';

final adminDashboardRepositoryProvider = Provider<AdminDashboardRepository>((
  ref,
) {
  final repositories = ref.watch(backendRepositoriesProvider);
  if (repositories.mode == BackendMode.mock) {
    return MockAdminDashboardRepository(repositories.mvpCompatibilityRequests);
  }
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    throw StateError(
      'Supabase no está disponible para el panel administrativo.',
    );
  }
  return SupabaseAdminDashboardRepository(client);
});

final adminDashboardRangeProvider =
    NotifierProvider<AdminDashboardRangeController, AdminDashboardRange>(
      AdminDashboardRangeController.new,
    );

class AdminDashboardRangeController extends Notifier<AdminDashboardRange> {
  @override
  AdminDashboardRange build() => AdminDashboardRange.last7Days;

  void select(AdminDashboardRange range) => state = range;
}

final adminDashboardProvider = FutureProvider<AdminDashboardSnapshot>((ref) {
  final range = ref.watch(adminDashboardRangeProvider);
  return ref.watch(adminDashboardRepositoryProvider).loadDashboard(range);
});
