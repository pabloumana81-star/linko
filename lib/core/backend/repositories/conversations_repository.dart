import 'package:linko/features/requests/domain/models/conversation_message.dart';

abstract interface class ConversationsRepository {
  Future<List<ConversationMessage>> getMessages(String requestId);
  Future<void> sendMessage(ConversationMessage message);
}
