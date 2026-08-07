class AdminReport {
  const AdminReport({
    required this.id,
    required this.reporterName,
    required this.requestTitle,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String reporterName;
  final String? requestTitle;
  final String reason;
  final String status;
  final DateTime createdAt;
}

abstract interface class AdminReportsRepository {
  Future<List<AdminReport>> listReports();
}
