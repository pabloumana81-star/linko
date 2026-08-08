import 'package:linko/features/admin/domain/admin_dashboard.dart';
import 'package:linko/features/admin/domain/admin_dashboard_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAdminDashboardRepository implements AdminDashboardRepository {
  SupabaseAdminDashboardRepository(this._client, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final SupabaseClient _client;
  final DateTime Function() _clock;

  @override
  Future<AdminDashboardSnapshot> loadDashboard(
    AdminDashboardRange range,
  ) async {
    final since = _clock().toUtc().subtract(range.duration);
    final response = await _client.rpc(
      'get_admin_dashboard',
      params: {'p_since': since.toIso8601String()},
    );
    final data = Map<String, dynamic>.from(response as Map);
    final activeProfessionals =
        (await _client.rpc('count_active_admin_professionals') as num).toInt();
    final metrics = Map<String, dynamic>.from(data['metrics'] as Map);
    final activities = (data['activities'] as List? ?? const [])
        .map((item) => _activity(Map<String, dynamic>.from(item as Map)))
        .toList();
    return AdminDashboardSnapshot(
      metrics: AdminDashboardMetrics(
        totalUsers: (metrics['total_users'] as num).toInt(),
        totalProfessionals: activeProfessionals,
        activeRequests: (metrics['active_requests'] as num).toInt(),
        completedJobs: (metrics['completed_jobs'] as num).toInt(),
        cancelledRequests: (metrics['cancelled_requests'] as num).toInt(),
        averageRating: (metrics['average_rating'] as num).toDouble(),
      ),
      activities: List.unmodifiable(activities),
    );
  }

  AdminActivity _activity(Map<String, dynamic> row) => AdminActivity(
    id: row['id'] as String,
    type: AdminActivityType.values.byName(row['type'] as String),
    title: row['title'] as String,
    timestamp: DateTime.parse(row['timestamp'] as String).toLocal(),
  );
}
