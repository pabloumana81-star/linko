import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linko/core/backend/data/mock_backend_repositories.dart';
import 'package:linko/features/home/presentation/conversation_screen.dart';
import 'package:linko/features/requests/data/conversation_supabase_mapper.dart';
import 'package:linko/features/requests/data/mock_request_repository.dart';
import 'package:linko/features/requests/domain/models/conversation_message.dart';
import 'package:linko/features/requests/domain/models/conversation.dart';
import 'package:linko/features/requests/domain/models/request_state.dart';

void main() {
  group('realtime conversation contract', () {
    late MockRequestRepository store;
    late MockConversationsRepository repository;
    late String requestId;
    late String customerId;
    late String professionalId;
    late String conversationId;

    setUp(() async {
      store = MockRequestRepository();
      repository = MockConversationsRepository(store);
      final request = store
          .getProfessionalRequests('professional-carlos')
          .first;
      requestId = request.id;
      customerId = request.customer.id;
      professionalId = request.professional.user.id;
      conversationId = (await repository.getOrCreateConversation(
        serviceRequestId: requestId,
        customerId: customerId,
        professionalId: professionalId,
      )).id;
    });

    tearDown(() => repository.dispose());

    test('gets one conversation and loads its message history', () async {
      final first = await repository.getOrCreateConversation(
        serviceRequestId: requestId,
        customerId: customerId,
        professionalId: professionalId,
      );
      final second = await repository.getOrCreateConversation(
        serviceRequestId: requestId,
        customerId: customerId,
        professionalId: professionalId,
      );

      expect(second.id, first.id);
      expect(await repository.listMessages(first.id), isNotEmpty);
    });

    test('customer sends and professional receives, then replies', () async {
      final events = <List<ConversationMessage>>[];
      final subscription = repository
          .watchMessages(conversationId)
          .listen(events.add);
      await Future<void>.delayed(Duration.zero);

      final customerMessage = await repository.sendTextMessage(
        conversationId: conversationId,
        serviceRequestId: requestId,
        senderId: customerId,
        author: MessageAuthor.customer,
        body: '¿Puedes venir mañana?',
      );
      await Future<void>.delayed(Duration.zero);
      expect(
        events.last.singleWhere((item) => item.id == customerMessage.id).author,
        MessageAuthor.customer,
      );

      final reply = await repository.sendTextMessage(
        conversationId: conversationId,
        serviceRequestId: requestId,
        senderId: professionalId,
        author: MessageAuthor.professional,
        body: 'Sí, a las nueve.',
      );
      await Future<void>.delayed(Duration.zero);
      expect(
        events.last.singleWhere((item) => item.id == reply.id).author,
        MessageAuthor.professional,
      );
      await subscription.cancel();
    });

    test('supports system messages and action cards', () async {
      final system = await repository.sendSystemMessage(
        conversationId: conversationId,
        serviceRequestId: requestId,
        body: 'La solicitud fue actualizada.',
      );
      final action = await repository.sendActionCard(
        conversationId: conversationId,
        serviceRequestId: requestId,
        senderId: professionalId,
        author: MessageAuthor.professional,
        actionType: ConversationMessageType.scheduleProposal,
        body: 'Nueva fecha propuesta.',
        metadata: const {'schedule_label': 'Mañana, 9:00 a. m.'},
      );

      expect(system.type, ConversationMessageType.system);
      expect(system.author, MessageAuthor.system);
      expect(action.type, ConversationMessageType.scheduleProposal);
      expect(action.metadata?['schedule_label'], 'Mañana, 9:00 a. m.');
    });

    test('closes and safely recreates a subscription', () async {
      final firstDone = Completer<void>();
      repository
          .watchMessages(conversationId)
          .listen((_) {}, onDone: firstDone.complete);
      await repository.disposeConversation(conversationId);
      await firstDone.future;

      final reopened = await repository.watchMessages(conversationId).first;
      expect(reopened, isNotEmpty);
    });
  });

  test('deduplicates realtime echoes and preserves chronological order', () {
    final buffer = ConversationMessageBuffer();
    ConversationMessage message(String id, int minute) => ConversationMessage(
      id: id,
      requestId: 'request',
      author: MessageAuthor.customer,
      text: id,
      timeLabel: 'Ahora',
      createdAt: DateTime.utc(2026, 8, 3, 10, minute),
    );

    final later = message('later', 2);
    final earlier = message('earlier', 1);
    final result = buffer.merge([later, earlier, later]);

    expect(result.map((item) => item.id), ['earlier', 'later']);
  });

  test('maps database system and action-card types centrally', () {
    const mapper = ConversationSupabaseMapper();
    final system = mapper.messageFromRow(
      {
        'id': 'system',
        'conversation_id': 'conversation',
        'sender_id': null,
        'type': 'system',
        'body': 'Actualización',
        'metadata': null,
        'created_at': '2026-08-03T10:00:00Z',
      },
      serviceRequestId: 'request',
      customerId: 'customer',
      professionalId: 'professional',
    );
    final action = mapper.messageFromRow(
      {
        'id': 'action',
        'conversation_id': 'conversation',
        'sender_id': 'professional',
        'type': 'actionCard',
        'body': 'Fecha propuesta',
        'metadata': {
          'action_type': 'scheduleProposal',
          'schedule_status': 'pending',
        },
        'created_at': '2026-08-03T10:01:00Z',
      },
      serviceRequestId: 'request',
      customerId: 'customer',
      professionalId: 'professional',
    );

    expect(system.type, ConversationMessageType.system);
    expect(action.type, ConversationMessageType.scheduleProposal);
    expect(action.scheduleStatus, ScheduleProposalStatus.pending);
  });

  testWidgets('failed sending keeps typed text and shows Spanish error', (
    tester,
  ) async {
    final store = MockRequestRepository();
    final request = store.getProfessionalRequests('professional-carlos').first;
    final repository = _FailingSendRepository(store);

    await tester.pumpWidget(
      MaterialApp(
        home: ConversationScreen(
          requestId: request.id,
          counterpartName: request.professional.user.name,
          serviceName: request.serviceName,
          requestStatus: RequestState.pending,
          perspective: ConversationPerspective.customer,
          initialMessages: const [],
          realtime: ConversationRealtimeConfig(
            repository: repository,
            customerId: request.customer.id,
            professionalId: request.professional.user.id,
            senderId: request.customer.id,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    const text = 'No borres este mensaje';
    await tester.enterText(
      find.byKey(const ValueKey('conversation-input')),
      text,
    );
    await tester.tap(find.byKey(const ValueKey('conversation-send')));
    await tester.pumpAndSettle();

    expect(find.text('No pudimos enviar el mensaje.'), findsOneWidget);
    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('conversation-input')),
    );
    expect(field.controller?.text, text);
  });

  testWidgets('backend loading failure renders a controlled Spanish state', (
    tester,
  ) async {
    final store = MockRequestRepository();
    final request = store.getProfessionalRequests('professional-carlos').first;

    await tester.pumpWidget(
      MaterialApp(
        home: ConversationScreen(
          requestId: request.id,
          counterpartName: request.professional.user.name,
          serviceName: request.serviceName,
          requestStatus: RequestState.pending,
          perspective: ConversationPerspective.customer,
          initialMessages: const [],
          realtime: ConversationRealtimeConfig(
            repository: _FailingLoadRepository(store),
            customerId: request.customer.id,
            professionalId: request.professional.user.id,
            senderId: request.customer.id,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No pudimos cargar la conversación.'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });
}

class _FailingSendRepository extends MockConversationsRepository {
  _FailingSendRepository(super.requests);

  @override
  Future<ConversationMessage> sendTextMessage({
    required String conversationId,
    required String serviceRequestId,
    required String senderId,
    required MessageAuthor author,
    required String body,
  }) => Future.error(StateError('Backend no disponible'));
}

class _FailingLoadRepository extends MockConversationsRepository {
  _FailingLoadRepository(super.requests);

  @override
  Future<Conversation> getOrCreateConversation({
    required String serviceRequestId,
    required String customerId,
    required String professionalId,
  }) => Future.error(StateError('Backend no disponible'));
}
