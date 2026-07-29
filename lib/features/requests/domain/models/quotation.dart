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
  });

  final String requestId;
  final int laborAmount;
  final int materialsAmount;
  final String workDescription;
  final String estimatedDuration;
  final String startTiming;
  final int validityDays;
  final String warrantyLabel;

  int get totalAmount => laborAmount + materialsAmount;
}
