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
  });

  final String id;
  final String requestId;
  final TimelineStage stage;
  final String title;
  final String description;
  final String? dateLabel;
}
