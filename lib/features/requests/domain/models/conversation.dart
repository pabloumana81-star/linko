class Conversation {
  const Conversation({
    required this.id,
    required this.serviceRequestId,
    required this.customerId,
    required this.professionalId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String serviceRequestId;
  final String customerId;
  final String professionalId;
  final DateTime createdAt;
  final DateTime updatedAt;
}
