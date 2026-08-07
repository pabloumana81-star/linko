import 'package:linko_admin/features/admin/domain/admin_report.dart';

class MockAdminReportsRepository implements AdminReportsRepository {
  const MockAdminReportsRepository();

  @override
  Future<List<AdminReport>> listReports() async => const [];
}
