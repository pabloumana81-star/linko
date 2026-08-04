enum AdminDashboardRange {
  today('Hoy', Duration(days: 1)),
  last7Days('Últimos 7 días', Duration(days: 7)),
  last30Days('Últimos 30 días', Duration(days: 30));

  const AdminDashboardRange(this.label, this.duration);

  final String label;
  final Duration duration;
}

class AdminDashboardMetrics {
  const AdminDashboardMetrics({
    required this.totalUsers,
    required this.totalProfessionals,
    required this.activeRequests,
    required this.completedJobs,
    required this.cancelledRequests,
    required this.averageRating,
  });

  final int totalUsers;
  final int totalProfessionals;
  final int activeRequests;
  final int completedJobs;
  final int cancelledRequests;
  final double averageRating;

  bool get isEmpty =>
      totalUsers == 0 &&
      totalProfessionals == 0 &&
      activeRequests == 0 &&
      completedJobs == 0 &&
      cancelledRequests == 0 &&
      averageRating == 0;
}

enum AdminActivityType {
  userRegistered,
  professionalCreated,
  requestCreated,
  quotationSent,
  jobCompleted,
  reportOpened,
}

class AdminActivity {
  const AdminActivity({
    required this.id,
    required this.type,
    required this.title,
    required this.timestamp,
  });

  final String id;
  final AdminActivityType type;
  final String title;
  final DateTime timestamp;
}

class AdminDashboardSnapshot {
  const AdminDashboardSnapshot({
    required this.metrics,
    required this.activities,
  });

  final AdminDashboardMetrics metrics;
  final List<AdminActivity> activities;

  bool get isEmpty => metrics.isEmpty && activities.isEmpty;
}
