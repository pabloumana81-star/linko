enum QuotationStatus { pending, accepted, rejected }

class Quotation {
  const Quotation({
    required this.requestId,
    required this.laborAmount,
    required this.materialsAmount,
    required this.workDescription,
    required this.estimatedDuration,
    required this.startTiming,
    required this.validityDays,
    this.warrantyLabel = '30 días sobre el trabajo realizado',
    this.professionalId,
    this.status = QuotationStatus.pending,
    this.createdAt,
  });

  final String requestId;
  final int laborAmount;
  final int materialsAmount;
  final String workDescription;
  final String estimatedDuration;
  final String startTiming;
  final int validityDays;
  final String warrantyLabel;
  final String? professionalId;
  final QuotationStatus status;
  final DateTime? createdAt;

  int get totalAmount => laborAmount + materialsAmount;

  Quotation copyWith({QuotationStatus? status}) => Quotation(
    requestId: requestId,
    laborAmount: laborAmount,
    materialsAmount: materialsAmount,
    workDescription: workDescription,
    estimatedDuration: estimatedDuration,
    startTiming: startTiming,
    validityDays: validityDays,
    warrantyLabel: warrantyLabel,
    professionalId: professionalId,
    status: status ?? this.status,
    createdAt: createdAt,
  );
}
