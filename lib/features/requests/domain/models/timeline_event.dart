enum TimelineStage {
  requestSent,
  professionalReviewing,
  quotationSent,
  quotationAccepted,
  workScheduled,
  workInProgress,
  workCompleted,
}

class TimelineEvent {
  const TimelineEvent({
    required this.id,
    required this.requestId,
    required this.stage,
    required this.title,
    required this.description,
    this.dateLabel,
    this.type,
    this.payload = const {},
    this.createdAt,
  });

  final String id;
  final String requestId;
  final TimelineStage stage;
  final String title;
  final String description;
  final String? dateLabel;
  final String? type;
  final Map<String, dynamic> payload;
  final DateTime? createdAt;
}
