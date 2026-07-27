enum QuotationDuration {
  underTwoHours('Menos de 2 horas'),
  halfDay('Medio día'),
  oneDay('1 día'),
  twoToThreeDays('2–3 días'),
  overThreeDays('Más de 3 días');

  const QuotationDuration(this.label);
  final String label;
}

enum QuotationStartTiming {
  asSoonAsPossible('Lo antes posible'),
  proposedDate('Proponer una fecha'),
  coordinateWithCustomer('Por coordinar con el cliente');

  const QuotationStartTiming(this.label);
  final String label;
}

class QuotationDraft {
  const QuotationDraft({
    required this.requestId,
    required this.customerName,
    required this.serviceCategory,
    required this.workDescription,
    required this.laborAmount,
    required this.estimatedDuration,
    required this.startTiming,
    required this.validityDays,
    this.materialsAmount = 0,
    this.additionalDetails,
    this.proposedStartDate,
  });

  final String requestId;
  final String customerName;
  final String serviceCategory;
  final String workDescription;
  final int laborAmount;
  final int materialsAmount;
  final String? additionalDetails;
  final QuotationDuration estimatedDuration;
  final QuotationStartTiming startTiming;
  final DateTime? proposedStartDate;
  final int validityDays;

  int get totalAmount => laborAmount + materialsAmount;
}
