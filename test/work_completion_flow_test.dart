import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linko/app/app.dart';
import 'package:linko/app/router.dart';
import 'package:linko/features/home/presentation/providers/professional_requests_provider.dart'
    show professionalRequestFlowProvider;
import 'package:linko/features/requests/domain/models/conversation_message.dart';
import 'package:linko/features/requests/domain/models/quotation.dart';
import 'package:linko/features/requests/domain/models/request_state.dart';
import 'package:linko/features/requests/domain/models/timeline_event.dart';
import 'package:linko/features/requests/domain/repositories/request_repository.dart';
import 'package:linko/features/requests/presentation/providers/request_providers.dart';

void main() {
  testWidgets('full professional and customer work completion flow', (
    tester,
  ) async {
    const requestId = 'request-ana-air';
    appRouter.go(AppRoutes.professionalHome);
    await tester.pumpWidget(const ProviderScope(child: LinkoApp()));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(LinkoApp)),
    );
    final repository = container.read(requestRepositoryProvider);
    _advanceToInProgress(repository, requestId);
    _invalidateRequest(container, requestId);

    appRouter.go('/professional/requests/$requestId');
    await tester.pumpAndSettle();

    expect(find.text('Marcar trabajo como completado'), findsOneWidget);
    await tester.tap(find.text('Marcar trabajo como completado'));
    await tester.pumpAndSettle();

    expect(
      repository.getRequestById(requestId)?.state,
      RequestState.pendingCustomerConfirmation,
    );
    expect(find.text('Marcar trabajo como completado'), findsNothing);
    expect(find.text('Pendiente de confirmación'), findsOneWidget);
    expect(
      repository
          .getMessages(requestId)
          .where(
            (message) => message.type == ConversationMessageType.jobCompleted,
          ),
      hasLength(1),
    );
    expect(
      repository
          .getTimeline(requestId)
          .singleWhere((event) => event.stage == TimelineStage.workCompleted)
          .dateLabel,
      'Ahora',
    );

    appRouter.go(AppRoutes.professionalRequests);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Todas'));
    await tester.pumpAndSettle();
    expect(find.text('Ana Martínez'), findsOneWidget);
    expect(find.text('Pendiente de confirmación'), findsOneWidget);

    appRouter.go('/customer-requests/$requestId');
    await tester.pumpAndSettle();
    expect(find.text('Pendiente de confirmación'), findsOneWidget);
    await tester.tap(find.text('Abrir conversación'));
    await tester.pumpAndSettle();

    expect(
      find.text('Aire acondicionado · Pendiente de confirmación'),
      findsOneWidget,
    );
    expect(find.text('Trabajo completado'), findsOneWidget);
    expect(
      find.text('El profesional indicó que el trabajo ha finalizado.'),
      findsOneWidget,
    );
    expect(find.text('Confirmar trabajo'), findsOneWidget);
    expect(find.text('Reportar un problema'), findsOneWidget);

    await tester.tap(find.text('Confirmar trabajo'));
    await tester.pumpAndSettle();

    expect(repository.getRequestById(requestId)?.state, RequestState.completed);
    expect(find.text('Aire acondicionado · Completado'), findsOneWidget);
    expect(find.text('Confirmar trabajo'), findsNothing);
    expect(find.text('Reportar un problema'), findsNothing);
    expect(
      repository
          .getMessages(requestId)
          .where((message) => message.id == '$requestId-job-confirmed'),
      hasLength(1),
    );

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Seguimiento'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('timeline-workCompleted-active')),
      findsOneWidget,
    );

    appRouter.go(AppRoutes.customerRequests);
    await tester.pumpAndSettle();
    expect(find.text('Completado'), findsWidgets);

    appRouter.go('/professional/requests/$requestId');
    await tester.pumpAndSettle();
    expect(find.text('Completada'), findsOneWidget);
    expect(find.text('Marcar trabajo como completado'), findsNothing);
    expect(find.text('Proponer fecha y hora'), findsNothing);
    expect(find.text('Iniciar trabajo'), findsNothing);
    expect(find.byType(BackButton), findsOneWidget);
  });

  testWidgets('reported completion problem is shared with the professional', (
    tester,
  ) async {
    const requestId = 'request-ana-air';
    appRouter.go(AppRoutes.guestHome);
    await tester.pumpWidget(const ProviderScope(child: LinkoApp()));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(LinkoApp)),
    );
    final repository = container.read(requestRepositoryProvider);
    _advanceToInProgress(repository, requestId);
    repository.markJobCompleted(requestId);
    _invalidateRequest(container, requestId);

    appRouter.go('/customer-requests/$requestId/conversation');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reportar un problema'));
    await tester.pumpAndSettle();

    expect(
      repository.getRequestById(requestId)?.state,
      RequestState.pendingCustomerConfirmation,
    );
    expect(
      repository.getMessages(requestId).last.text,
      'El cliente reportó un problema con el trabajo realizado.',
    );
    expect(find.text('Confirmar trabajo'), findsOneWidget);

    appRouter.go('/professional/requests/$requestId/conversation');
    await tester.pumpAndSettle();

    expect(
      find.text('El cliente reportó un problema con el trabajo realizado.'),
      findsOneWidget,
    );
    expect(
      find.text('Aire acondicionado · Pendiente de confirmación'),
      findsOneWidget,
    );
    expect(find.byType(BackButton), findsOneWidget);
  });
}

void _invalidateRequest(ProviderContainer container, String requestId) {
  container
    ..invalidate(requestDetailProvider(requestId))
    ..invalidate(customerRequestsProvider)
    ..invalidate(professionalRequestsProvider)
    ..invalidate(conversationProvider(requestId))
    ..invalidate(timelineProvider(requestId))
    ..invalidate(professionalRequestFlowProvider);
}

void _advanceToInProgress(RequestRepository repository, String requestId) {
  repository.sendQuotation(
    Quotation(
      requestId: requestId,
      laborAmount: 30000,
      materialsAmount: 5000,
      workDescription: 'Revisión y reparación completa del equipo.',
      estimatedDuration: 'Medio día',
      startTiming: 'Por coordinar con el cliente',
      validityDays: 7,
    ),
  );
  repository.acceptQuotation(requestId);
  repository.updateStatus(requestId, RequestState.scheduled);
  repository.startJob(requestId);
}
