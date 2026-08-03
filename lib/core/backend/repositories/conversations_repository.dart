import 'package:linko/features/requests/domain/models/conversation.dart';
import 'package:linko/features/requests/domain/models/conversation_message.dart';

enum ConversationConnectionStatus { connecting, connected, disconnected }

abstract interface class ConversationsRepository {
  Future<Conversation> getOrCreateConversation({
    required String serviceRequestId,
    required String customerId,
    required String professionalId,
  });
  Future<List<ConversationMessage>> listMessages(String conversationId);
  Future<ConversationMessage> sendTextMessage({
    required String conversationId,
    required String serviceRequestId,
    required String senderId,
    required MessageAuthor author,
    required String body,
  });
  Future<ConversationMessage> sendSystemMessage({
    required String conversationId,
    required String serviceRequestId,
    required String body,
    Map<String, dynamic>? metadata,
  });
  Future<ConversationMessage> sendActionCard({
    required String conversationId,
    required String serviceRequestId,
    required String senderId,
    required MessageAuthor author,
    required ConversationMessageType actionType,
    required String body,
    required Map<String, dynamic> metadata,
  });
  Stream<List<ConversationMessage>> watchMessages(String conversationId);
  Stream<ConversationConnectionStatus> watchConnection(String conversationId);
  Future<void> disposeConversation(String conversationId);
  Future<void> dispose();

  Future<List<ConversationMessage>> getMessages(String requestId);
  Future<void> sendMessage(ConversationMessage message);
}
