import 'package:linko/features/admin/domain/admin_dashboard.dart';

abstract interface class AdminDashboardRepository {
  Future<AdminDashboardSnapshot> loadDashboard(AdminDashboardRange range);
}
