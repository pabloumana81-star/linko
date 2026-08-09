import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko/core/backend/backend_config.dart';
import 'package:linko/core/backend/backend_providers.dart';
import 'package:linko_admin/features/admin/data/mock_admin_dashboard_repository.dart';
import 'package:linko_admin/features/admin/data/mock_admin_professionals_repository.dart';
import 'package:linko_admin/features/admin/data/mock_admin_reports_repository.dart';
import 'package:linko_admin/features/admin/data/mock_admin_requests_repository.dart';
import 'package:linko_admin/features/admin/data/mock_admin_users_repository.dart';
import 'package:linko/features/admin/data/supabase_admin_dashboard_repository.dart';
import 'package:linko/features/admin/data/supabase_admin_professionals_repository.dart';
import 'package:linko_admin/features/admin/data/supabase_admin_reports_repository.dart';
import 'package:linko/features/admin/data/supabase_admin_requests_repository.dart';
import 'package:linko/features/admin/data/supabase_admin_users_repository.dart';
import 'package:linko/features/admin/domain/admin_dashboard_repository.dart';
import 'package:linko/features/admin/domain/admin_professionals_repository.dart';
import 'package:linko_admin/features/admin/domain/admin_report.dart';
import 'package:linko/features/admin/domain/admin_request.dart';
import 'package:linko/features/admin/domain/admin_users_repository.dart';
import 'package:linko_admin/features/admin/presentation/admin_mock_providers.dart';

class AdminRepositories {
  const AdminRepositories({
    required this.mode,
    required this.dashboard,
    required this.users,
    required this.professionals,
    required this.requests,
    required this.reports,
  });

  final BackendMode mode;
  final AdminDashboardRepository dashboard;
  final AdminUsersRepository users;
  final AdminProfessionalsRepository professionals;
  final AdminRequestsRepository requests;
  final AdminReportsRepository reports;
}

final adminRepositoriesProvider = Provider<AdminRepositories>((ref) {
  final shared = ref.watch(backendRepositoriesProvider);
  if (shared.mode == BackendMode.mock) {
    final state = ref.watch(mockAdminStateProvider);
    return AdminRepositories(
      mode: BackendMode.mock,
      dashboard: MockAdminDashboardRepository(
        shared.mvpCompatibilityRequests,
        state,
      ),
      users: MockAdminUsersRepository(
        shared.mvpCompatibilityRequests,
        accountStatuses: shared.accountStatuses,
      ),
      professionals: MockAdminProfessionalsRepository(
        shared.mvpCompatibilityRequests,
        state,
      ),
      requests: MockAdminRequestsRepository(shared.mvpCompatibilityRequests),
      reports: MockAdminReportsRepository(),
    );
  }

  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    throw StateError(
      'Supabase no está disponible para los repositorios administrativos.',
    );
  }
  return AdminRepositories(
    mode: BackendMode.supabase,
    dashboard: SupabaseAdminDashboardRepository(client),
    users: SupabaseAdminUsersRepository(client),
    professionals: SupabaseAdminProfessionalsRepository(client),
    requests: SupabaseAdminRequestsRepository(client),
    reports: SupabaseAdminReportsRepository(client),
  );
});
