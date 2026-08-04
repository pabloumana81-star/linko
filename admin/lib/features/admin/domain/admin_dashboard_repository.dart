import 'package:linko_admin/features/admin/domain/admin_dashboard.dart';

abstract interface class AdminDashboardRepository {
  Future<AdminDashboardSnapshot> loadDashboard(AdminDashboardRange range);
}
