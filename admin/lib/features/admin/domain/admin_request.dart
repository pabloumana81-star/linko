class AdminRequest {
  const AdminRequest({
    required this.id,
    required this.title,
    required this.category,
    required this.status,
    required this.customerName,
    required this.professionalName,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String category;
  final String status;
  final String customerName;
  final String professionalName;
  final DateTime createdAt;
  final DateTime updatedAt;
}

abstract interface class AdminRequestsRepository {
  Future<List<AdminRequest>> listRequests();
}
