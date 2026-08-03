import 'package:linko/features/requests/domain/models/conversation.dart';
import 'package:linko/features/requests/domain/models/conversation_message.dart';

class ConversationSupabaseMapper {
  const ConversationSupabaseMapper();

  Conversation conversationFromRow(Map<String, dynamic> row) => Conversation(
    id: row['id'] as String,
    serviceRequestId: row['service_request_id'] as String,
    customerId: row['customer_id'] as String,
    professionalId: row['professional_id'] as String,
    createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
    updatedAt: DateTime.parse(row['updated_at'] as String).toUtc(),
  );

  ConversationMessage messageFromRow(
    Map<String, dynamic> row, {
    required String serviceRequestId,
    required String customerId,
    required String professionalId,
  }) {
    final metadata = row['metadata'] is Map
        ? Map<String, dynamic>.from(row['metadata'] as Map)
        : <String, dynamic>{};
    final senderId = row['sender_id'] as String?;
    final actionKind = metadata['action_type'] as String?;
    final type = switch (row['type']) {
      'text' => ConversationMessageType.text,
      'system' => ConversationMessageType.system,
      'actionCard' => _actionType(actionKind),
      _ => throw const FormatException('El tipo de mensaje no es válido.'),
    };
    final scheduleStatusValue = metadata['schedule_status'] as String?;
    final createdAt = DateTime.parse(row['created_at'] as String).toUtc();
    return ConversationMessage(
      id: row['id'] as String,
      requestId: serviceRequestId,
      conversationId: row['conversation_id'] as String,
      senderId: senderId,
      author: senderId == null
          ? MessageAuthor.system
          : senderId == customerId
          ? MessageAuthor.customer
          : senderId == professionalId
          ? MessageAuthor.professional
          : throw const FormatException('El remitente no es válido.'),
      text: row['body'] as String? ?? '',
      timeLabel: 'Ahora',
      type: type,
      scheduleLabel: metadata['schedule_label'] as String?,
      scheduleStatus: scheduleStatusValue == null
          ? null
          : _scheduleStatus(scheduleStatusValue),
      metadata: metadata,
      createdAt: createdAt,
    );
  }

  Map<String, Object?> messageToInsert({
    required String conversationId,
    required String? senderId,
    required String type,
    required String? body,
    Map<String, dynamic>? metadata,
  }) => {
    'conversation_id': conversationId,
    'sender_id': senderId,
    'type': type,
    'body': body,
    'metadata': metadata,
  };

  String actionType(ConversationMessageType type) => switch (type) {
    ConversationMessageType.scheduleProposal => 'scheduleProposal',
    ConversationMessageType.workStarted => 'workStarted',
    ConversationMessageType.jobCompleted => 'jobCompleted',
    _ => throw ArgumentError('El mensaje no es una tarjeta de acción.'),
  };

  ConversationMessageType _actionType(String? value) => switch (value) {
    'scheduleProposal' => ConversationMessageType.scheduleProposal,
    'workStarted' => ConversationMessageType.workStarted,
    'jobCompleted' => ConversationMessageType.jobCompleted,
    _ => throw const FormatException('La tarjeta de acción no es válida.'),
  };

  ScheduleProposalStatus _scheduleStatus(String value) => switch (value) {
    'pending' => ScheduleProposalStatus.pending,
    'confirmed' => ScheduleProposalStatus.confirmed,
    'changeRequested' => ScheduleProposalStatus.changeRequested,
    _ => throw const FormatException('El estado de programación no es válido.'),
  };
}

class ConversationMessageBuffer {
  final Map<String, ConversationMessage> _messages = {};

  List<ConversationMessage> merge(Iterable<ConversationMessage> messages) {
    for (final message in messages) {
      _messages[message.id] = message;
    }
    final result = _messages.values.toList()
      ..sort((left, right) {
        final timeComparison = (left.createdAt ?? DateTime(1970)).compareTo(
          right.createdAt ?? DateTime(1970),
        );
        return timeComparison != 0
            ? timeComparison
            : left.id.compareTo(right.id);
      });
    return List.unmodifiable(result);
  }
}
