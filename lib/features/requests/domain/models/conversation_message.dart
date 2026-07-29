enum MessageAuthor { customer, professional, system }

enum ConversationMessageType {
  text,
  system,
  scheduleProposal,
  workStarted,
  jobCompleted,
}

enum ScheduleProposalStatus { pending, confirmed, changeRequested }

class ConversationMessage {
  const ConversationMessage({
    required this.id,
    required this.requestId,
    required this.author,
    required this.text,
    required this.timeLabel,
    this.type = ConversationMessageType.text,
    this.scheduleLabel,
    this.scheduleStatus,
  });

  final String id;
  final String requestId;
  final MessageAuthor author;
  final String text;
  final String timeLabel;
  final ConversationMessageType type;
  final String? scheduleLabel;
  final ScheduleProposalStatus? scheduleStatus;

  ConversationMessage copyWith({ScheduleProposalStatus? scheduleStatus}) {
    return ConversationMessage(
      id: id,
      requestId: requestId,
      author: author,
      text: text,
      timeLabel: timeLabel,
      type: type,
      scheduleLabel: scheduleLabel,
      scheduleStatus: scheduleStatus ?? this.scheduleStatus,
    );
  }
}
