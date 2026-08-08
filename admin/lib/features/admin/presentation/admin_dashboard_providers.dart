import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko/features/admin/domain/admin_dashboard.dart';
import 'package:linko/features/admin/domain/admin_dashboard_repository.dart';
import 'package:linko_admin/features/admin/presentation/admin_repositories_provider.dart';

final adminDashboardRepositoryProvider = Provider<AdminDashboardRepository>(
  (ref) => ref.watch(adminRepositoriesProvider).dashboard,
);

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
