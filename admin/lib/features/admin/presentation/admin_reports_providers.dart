import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko_admin/features/admin/domain/admin_report.dart';
import 'package:linko_admin/features/admin/presentation/admin_repositories_provider.dart';

final adminReportsRepositoryProvider = Provider<AdminReportsRepository>(
  (ref) => ref.watch(adminRepositoriesProvider).reports,
);

final adminReportsProvider = FutureProvider<List<AdminReport>>(
  (ref) => ref.watch(adminReportsRepositoryProvider).listReports(),
);
