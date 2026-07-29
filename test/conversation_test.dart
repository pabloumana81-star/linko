import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linko/features/home/presentation/conversation_screen.dart';
import 'package:linko/features/requests/domain/models/conversation_message.dart';
import 'package:linko/features/requests/domain/models/request_state.dart';

void main() {
  Widget buildConversation() {
    return const MaterialApp(
      home: ConversationScreen(
        requestId: 'request-test',
        counterpartName: 'Ana Martínez',
        serviceName: 'Aire acondicionado',
        requestStatus: RequestState.quoted,
        perspective: ConversationPerspective.professional,
        initialMessages: [
          ConversationMessage(
            id: 'system-1',
            requestId: 'request-test',
            author: MessageAuthor.system,
            text: 'El profesional envió una cotización.',
            timeLabel: '9:20 a. m.',
          ),
          ConversationMessage(
            id: 'customer-1',
            requestId: 'request-test',
            author: MessageAuthor.customer,
            text: 'Gracias por la cotización.',
            timeLabel: '9:24 a. m.',
          ),
          ConversationMessage(
            id: 'professional-1',
            requestId: 'request-test',
            author: MessageAuthor.professional,
            text: 'Incluye la revisión y los materiales.',
            timeLabel: '9:26 a. m.',
          ),
          ConversationMessage(
            id: 'customer-2',
            requestId: 'request-test',
            author: MessageAuthor.customer,
            text: '¿Podemos coordinar para el viernes?',
            timeLabel: '9:31 a. m.',
          ),
          ConversationMessage(
            id: 'professional-2',
            requestId: 'request-test',
            author: MessageAuthor.professional,
            text: 'Sí, tengo disponibilidad.',
            timeLabel: '9:35 a. m.',
          ),
          ConversationMessage(
            id: 'system-2',
            requestId: 'request-test',
            author: MessageAuthor.system,
            text: 'Se modificó la cotización.',
            timeLabel: '9:40 a. m.',
          ),
        ],
      ),
    );
  }

  testWidgets('renders participant data, messages, and system messages', (
    tester,
  ) async {
    await tester.pumpWidget(buildConversation());
    await tester.pumpAndSettle();

    expect(find.text('Conversación'), findsOneWidget);
    expect(find.text('Ana Martínez'), findsOneWidget);
    expect(find.text('Aire acondicionado · Cotizada'), findsOneWidget);
    expect(find.text('En línea'), findsOneWidget);
    expect(find.textContaining('Última actividad'), findsNothing);
    expect(find.text('Se modificó la cotización.'), findsOneWidget);
    await tester.drag(
      find.byKey(const ValueKey('conversation-message-list')),
      const Offset(0, 500),
    );
    await tester.pumpAndSettle();
    expect(find.text('El profesional envió una cotización.'), findsOneWidget);
    expect(find.text('Hoy'), findsOneWidget);
  });

  testWidgets('sends a local text message and keeps it at the bottom', (
    tester,
  ) async {
    await tester.pumpWidget(buildConversation());
    await tester.pumpAndSettle();

    const message = 'Puedo llegar a las nueve.';
    await tester.enterText(
      find.byKey(const ValueKey('conversation-input')),
      message,
    );
    await tester.tap(find.byKey(const ValueKey('conversation-send')));
    await tester.pumpAndSettle();

    expect(find.text(message), findsOneWidget);
    expect(find.text('Ahora'), findsOneWidget);
    expect(
      tester
          .getBottomRight(
            find.byKey(const ValueKey('conversation-last-message')),
          )
          .dy,
      lessThanOrEqualTo(
        tester.getTopLeft(find.byKey(const ValueKey('conversation-input'))).dy,
      ),
    );
  });

  testWidgets('opens initially positioned at the final mock message', (
    tester,
  ) async {
    await tester.pumpWidget(buildConversation());
    await tester.pumpAndSettle();

    final list = tester.widget<ListView>(
      find.byKey(const ValueKey('conversation-message-list')),
    );
    expect(list.controller?.offset, greaterThan(0));
    expect(
      tester
          .getBottomRight(
            find.byKey(const ValueKey('conversation-last-message')),
          )
          .dy,
      lessThanOrEqualTo(
        tester.getTopLeft(find.byKey(const ValueKey('conversation-input'))).dy,
      ),
    );
  });

  testWidgets('customer confirms a schedule from an action card', (
    tester,
  ) async {
    var confirmedMessageId = '';
    await tester.pumpWidget(
      MaterialApp(
        home: ConversationScreen(
          requestId: 'request-schedule',
          counterpartName: 'Carlos Rodríguez',
          serviceName: 'Electricista',
          requestStatus: RequestState.accepted,
          perspective: ConversationPerspective.customer,
          initialMessages: const [
            ConversationMessage(
              id: 'schedule-proposal',
              requestId: 'request-schedule',
              author: MessageAuthor.professional,
              text: 'El profesional propuso una fecha para el trabajo.',
              timeLabel: 'Ahora',
              type: ConversationMessageType.scheduleProposal,
              scheduleLabel: '30/7/2026 a las 9:00 a. m.',
              scheduleStatus: ScheduleProposalStatus.pending,
            ),
          ],
          onConfirmSchedule: (messageId) {
            confirmedMessageId = messageId;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Propuesta de programación'), findsOneWidget);
    expect(find.text('Jueves 30 de julio'), findsOneWidget);
    expect(find.text('9:00 a. m.'), findsOneWidget);
    await tester.tap(find.text('Confirmar fecha'));
    await tester.pumpAndSettle();

    expect(confirmedMessageId, 'schedule-proposal');
    expect(find.text('Trabajo programado'), findsOneWidget);
    expect(find.text('Electricista · Trabajo programado'), findsOneWidget);
    expect(find.text('Confirmado por el cliente'), findsOneWidget);
    expect(find.text('Confirmar fecha'), findsNothing);
    expect(find.text('Solicitar cambio'), findsNothing);
    expect(
      find.text('El cliente confirmó la fecha del trabajo.'),
      findsOneWidget,
    );
  });

  testWidgets('customer can confirm a completed job from its action card', (
    tester,
  ) async {
    var confirmed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: ConversationScreen(
          requestId: 'request-completed',
          counterpartName: 'Carlos Rodríguez',
          serviceName: 'Electricista',
          requestStatus: RequestState.pendingCustomerConfirmation,
          perspective: ConversationPerspective.customer,
          initialMessages: const [
            ConversationMessage(
              id: 'job-completed',
              requestId: 'request-completed',
              author: MessageAuthor.system,
              text: 'El profesional indicó que el trabajo ha finalizado.',
              timeLabel: 'Ahora',
              type: ConversationMessageType.jobCompleted,
            ),
          ],
          onConfirmJob: () {
            confirmed = true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trabajo completado'), findsOneWidget);
    expect(
      find.text('El profesional indicó que el trabajo ha finalizado.'),
      findsOneWidget,
    );
    expect(find.text('Confirmar trabajo'), findsOneWidget);
    expect(find.text('Reportar un problema'), findsOneWidget);

    await tester.tap(find.text('Confirmar trabajo'));
    await tester.pumpAndSettle();

    expect(confirmed, isTrue);
    expect(find.text('Confirmar trabajo'), findsNothing);
    expect(find.text('Reportar un problema'), findsNothing);
  });

  testWidgets('reporting a problem keeps the completion card available', (
    tester,
  ) async {
    var reported = false;
    await tester.pumpWidget(
      MaterialApp(
        home: ConversationScreen(
          requestId: 'request-problem',
          counterpartName: 'Carlos Rodríguez',
          serviceName: 'Electricista',
          requestStatus: RequestState.pendingCustomerConfirmation,
          perspective: ConversationPerspective.customer,
          initialMessages: const [
            ConversationMessage(
              id: 'job-completed',
              requestId: 'request-problem',
              author: MessageAuthor.system,
              text: 'El profesional indicó que el trabajo ha finalizado.',
              timeLabel: 'Ahora',
              type: ConversationMessageType.jobCompleted,
            ),
          ],
          onReportProblem: () {
            reported = true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reportar un problema'));
    await tester.pumpAndSettle();

    expect(reported, isTrue);
    expect(
      find.text('El cliente reportó un problema con el trabajo realizado.'),
      findsOneWidget,
    );
    expect(find.text('Confirmar trabajo'), findsOneWidget);
    expect(find.text('Reportar un problema'), findsOneWidget);
    expect(find.text('Job Completed'), findsNothing);
    expect(find.text('Confirm Job'), findsNothing);
    expect(find.text('Report a Problem'), findsNothing);
    expect(find.text('Pending Customer Confirmation'), findsNothing);
  });
}
