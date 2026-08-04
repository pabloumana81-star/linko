abstract interface class ReportsRepository {
  Future<void> createReport({
    required String reporterId,
    required String requestId,
    required String reason,
  });
}
