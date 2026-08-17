import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:linko/app/app.dart';
import 'package:linko/app/app_mode.dart';
import 'package:linko/app/router.dart';
import 'package:linko/core/backend/backend_providers.dart';
import 'package:linko/core/backend/data/mock_backend_repositories.dart';
import 'package:linko/features/auth/domain/models/app_user_profile.dart';
import 'package:linko/features/requests/data/mock_request_repository.dart';
import 'package:linko/features/requests/domain/models/conversation_message.dart';
import 'package:linko/features/requests/domain/models/request_state.dart';
import 'package:linko/features/requests/domain/models/service_rating.dart';
import 'package:linko/features/requests/domain/models/timeline_event.dart';
import 'package:linko/features/requests/presentation/providers/request_providers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('flujo MVP completo mantiene una única solicitud sincronizada', (
    tester,
  ) async {
    final repository = MockRequestRepository();
    final initialIds = repository
        .getCustomerRequests(currentCustomerId)
        .map((request) => request.id)
        .toSet();
    final initialSummary = repository.getProfessionalRatingSummary(
      currentProfessionalId,
    );

    appRouter.go(AppRoutes.guestHome);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          requestRepositoryProvider.overrideWithValue(repository),
          authenticationRepositoryProvider.overrideWithValue(
            MockAuthenticationRepository(
              initialUser: AppUserProfile(
                id: 'authenticated-customer',
                displayName: 'Cliente',
                email: 'cliente@linko.test',
                avatarUrl: null,
                activeMode: AppMode.customer,
                createdAt: DateTime.utc(2026),
              ),
            ),
          ),
        ],
        child: const LinkoApp(),
      ),
    );
    await tester.pumpAndSettle();
    _expectNoEnglishWorkflowText();

    await _tapVisible(tester, find.text('Ver perfil').first);
    await tester.pumpAndSettle();
    expect(find.text('Perfil profesional'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);

    await _tapVisible(tester, find.text('Solicitar servicio'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('request-description')),
      'Necesito revisar y reparar la instalación eléctrica de la sala.',
    );
    await tester.enterText(
      find.byKey(const ValueKey('request-location')),
      'Escazú, San José',
    );
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('request-timing-flexible')),
    );
    await _tapVisible(tester, find.text('Continuar'));
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text('Enviar solicitud'));
    await tester.pumpAndSettle();
    expect(find.text('Solicitud enviada'), findsOneWidget);

    final createdRequest = repository
        .getCustomerRequests(currentCustomerId)
        .singleWhere((request) => !initialIds.contains(request.id));
    final requestId = createdRequest.id;
    expect(createdRequest.professional.user.id, currentProfessionalId);
    expect(createdRequest.state, RequestState.pending);

    await _tapVisible(tester, find.text('Ver mis solicitudes'));
    await tester.pumpAndSettle();
    await _expectRequestCard(
      tester,
      key: 'customer-request-$requestId',
      status: 'Esperando respuesta',
    );

    await _switchToProfessional(tester);
    await _openProfessionalRequests(tester);
    await _expectRequestCard(
      tester,
      key: 'professional-request-$requestId',
      status: 'Nueva',
    );
    await _tapVisible(
      tester,
      find.byKey(ValueKey('professional-request-$requestId')),
    );
    await tester.pumpAndSettle();
    _expectDetailNavigation();
    expect(find.text('Rechazar solicitud'), findsOneWidget);

    await _tapVisible(
      tester,
      find.byKey(const ValueKey('professional-action-sendQuotation')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('quotation-labor')),
        matching: find.byType(TextFormField),
      ),
      '25000',
    );
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('quotation-materials')),
        matching: find.byType(TextFormField),
      ),
      '5000',
    );
    await tester.enterText(
      find.byKey(const ValueKey('quotation-description')),
      'Incluye diagnóstico, reparación y revisión final de seguridad.',
    );
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('quotation-duration-halfDay')),
    );
    await _tapVisible(tester, find.text('Revisar cotización'));
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.byKey(const ValueKey('send-quotation')));
    await tester.pumpAndSettle();
    expect(find.text('Cotización enviada'), findsOneWidget);
    expect(repository.getRequestById(requestId)?.state, RequestState.quoted);
    _expectSingleMessage(
      repository,
      requestId,
      'El profesional envió una cotización.',
    );

    await _tapVisible(tester, find.text('Volver a solicitudes'));
    await tester.pumpAndSettle();
    expect(find.text('Cotizadas'), findsOneWidget);

    await _switchToCustomer(tester);
    await _openCustomerRequests(tester);
    await _expectRequestCard(
      tester,
      key: 'customer-request-$requestId',
      status: 'Cotización recibida',
    );
    await _tapVisible(
      tester,
      find.byKey(ValueKey('customer-request-$requestId')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ver cotización'), findsOneWidget);
    expect(find.text('Calificar servicio'), findsNothing);
    await _tapVisible(tester, find.text('Ver cotización'));
    await tester.pumpAndSettle();
    expect(find.text('Aceptar cotización'), findsOneWidget);
    await tester.tap(find.text('Aceptar cotización'));
    await tester.tap(find.text('Aceptar cotización'));
    await tester.pumpAndSettle();
    expect(repository.getRequestById(requestId)?.state, RequestState.accepted);
    expect(find.text('Cotización aceptada'), findsOneWidget);
    _expectSingleMessage(
      repository,
      requestId,
      'El cliente aceptó la cotización.',
    );
    expect(find.text('Ver cotización'), findsNothing);

    await _backToRequests(tester);
    await _switchToProfessional(tester);
    await _openProfessionalRequests(tester);
    await _selectProfessionalFilter(tester, 'Aceptadas');
    await _tapVisible(
      tester,
      find.byKey(ValueKey('professional-request-$requestId')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Cotización aceptada'), findsOneWidget);
    expect(find.text('Enviar cotización'), findsNothing);
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('professional-action-proposeSchedule')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Electricista · Cotización aceptada'), findsOneWidget);
    await _tapVisible(tester, find.byKey(const ValueKey('propose-schedule')));
    await tester.pumpAndSettle();
    await _tapVisible(
      tester,
      find
          .descendant(
            of: find.byType(DatePickerDialog),
            matching: find.byType(TextButton),
          )
          .last,
    );
    await tester.pumpAndSettle();
    await _tapVisible(
      tester,
      find
          .descendant(
            of: find.byType(TimePickerDialog),
            matching: find.byType(TextButton),
          )
          .last,
    );
    await tester.pumpAndSettle();
    expect(
      repository
          .getMessages(requestId)
          .where(
            (message) =>
                message.type == ConversationMessageType.scheduleProposal,
          ),
      hasLength(1),
    );

    await _backToRequests(tester);
    await _switchToCustomer(tester);
    await _openCustomerRequests(tester);
    await _tapVisible(
      tester,
      find.byKey(ValueKey('customer-request-$requestId')),
    );
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text('Abrir conversación'));
    await tester.pumpAndSettle();
    expect(find.text('Electricista · Cotización aceptada'), findsOneWidget);
    final confirmSchedule = find.text('Confirmar fecha');
    await _tapVisible(tester, confirmSchedule);
    await tester.tap(confirmSchedule);
    await tester.pumpAndSettle();
    expect(repository.getRequestById(requestId)?.state, RequestState.scheduled);
    expect(find.text('Electricista · Trabajo programado'), findsOneWidget);
    _expectSingleMessage(
      repository,
      requestId,
      'El cliente confirmó la fecha del trabajo.',
    );

    await _backToRequests(tester);
    await _tapVisible(
      tester,
      find.byKey(ValueKey('customer-request-$requestId')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Trabajo programado'), findsOneWidget);
    expect(find.text('Ver cotización'), findsNothing);
    await _tapVisible(tester, find.text('Seguimiento'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('timeline-workScheduled-active')),
      findsOneWidget,
    );

    await _backToRequests(tester);
    await _switchToProfessional(tester);
    await _openProfessionalRequests(tester);
    await _selectProfessionalFilter(tester, 'Todas');
    await _tapVisible(
      tester,
      find.byKey(ValueKey('professional-request-$requestId')),
    );
    await tester.pumpAndSettle();
    final startJob = find.byKey(const ValueKey('professional-action-startJob'));
    await tester.tap(startJob);
    await tester.tap(startJob);
    await tester.pumpAndSettle();
    expect(
      repository.getRequestById(requestId)?.state,
      RequestState.inProgress,
    );
    expect(find.text('En progreso'), findsOneWidget);
    expect(startJob, findsNothing);
    _expectSingleMessage(
      repository,
      requestId,
      'El profesional inició el trabajo.',
    );

    final completeJob = find.byKey(
      const ValueKey('professional-action-markJobCompleted'),
    );
    await tester.tap(completeJob);
    await tester.tap(completeJob);
    await tester.pumpAndSettle();
    expect(
      repository.getRequestById(requestId)?.state,
      RequestState.pendingCustomerConfirmation,
    );
    expect(find.text('Pendiente de confirmación'), findsOneWidget);
    expect(completeJob, findsNothing);
    _expectSingleMessage(
      repository,
      requestId,
      'El profesional indicó que el trabajo ha finalizado.',
    );
    expect(
      repository
          .getMessages(requestId)
          .where(
            (message) => message.type == ConversationMessageType.jobCompleted,
          ),
      hasLength(1),
    );

    await _backToRequests(tester);
    await _switchToCustomer(tester);
    await _openCustomerRequests(tester);
    await _tapVisible(
      tester,
      find.byKey(ValueKey('customer-request-$requestId')),
    );
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text('Abrir conversación'));
    await tester.pumpAndSettle();
    expect(
      find.text('Electricista · Pendiente de confirmación'),
      findsOneWidget,
    );
    final confirmJob = find.byKey(const ValueKey('confirm-job'));
    await tester.tap(confirmJob);
    await tester.tap(confirmJob);
    await tester.pumpAndSettle();
    expect(repository.getRequestById(requestId)?.state, RequestState.completed);
    expect(find.text('Electricista · Completado'), findsOneWidget);
    expect(confirmJob, findsNothing);
    _expectSingleMessage(
      repository,
      requestId,
      'El cliente confirmó el trabajo completado.',
    );

    await _backToRequests(tester);
    await _expectRequestCard(
      tester,
      key: 'customer-request-$requestId',
      status: 'Completado',
    );
    await _tapVisible(
      tester,
      find.byKey(ValueKey('customer-request-$requestId')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Detalle de solicitud'), findsOneWidget);
    await _tapVisible(tester, find.text('Resumen'));
    await tester.pumpAndSettle();
    expect(find.text('Completado'), findsOneWidget);
    expect(find.text('Abrir conversación'), findsNothing);
    await _tapVisible(tester, find.text('Calificar servicio'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -420));
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.byKey(const ValueKey('rating-star-5')));
    await tester.enterText(
      find.byKey(const ValueKey('rating-comment')),
      'Excelente servicio, puntual y muy profesional.',
    );
    final submitRating = find.byKey(const ValueKey('submit-rating'));
    await _tapVisible(tester, submitRating);
    await tester.tap(submitRating);
    await tester.pumpAndSettle();
    expect(repository.getRequestById(requestId)?.state, RequestState.reviewed);
    expect(repository.getRating(requestId)?.stars, 5);
    expect(find.text('Servicio calificado'), findsOneWidget);
    expect(find.text('Calificar servicio'), findsNothing);
    _expectSingleMessage(
      repository,
      requestId,
      'El cliente calificó el servicio.',
    );

    final finalSummary = repository.getProfessionalRatingSummary(
      currentProfessionalId,
    );
    expect(
      finalSummary.completedJobsCount,
      initialSummary.completedJobsCount + 1,
    );
    expect(finalSummary.reviewCount, initialSummary.reviewCount + 1);
    expect(
      finalSummary.averageRating,
      greaterThan(initialSummary.averageRating),
    );

    final messagesAfterRating = repository.getMessages(requestId).length;
    repository.submitRating(
      ServiceRating(
        requestId: requestId,
        professionalId: currentProfessionalId,
        stars: 1,
        comment: 'Intento duplicado.',
      ),
    );
    expect(repository.getRating(requestId)?.stars, 5);
    expect(repository.getMessages(requestId), hasLength(messagesAfterRating));
    expect(
      repository
          .getProfessionalRatingSummary(currentProfessionalId)
          .reviewCount,
      finalSummary.reviewCount,
    );
    expect(
      repository
          .getProfessionalRatingSummary(currentProfessionalId)
          .averageRating,
      finalSummary.averageRating,
    );

    for (final activeState in RequestState.values.where(
      (state) => !state.isArchived,
    )) {
      expect(
        () => repository.updateStatus(requestId, activeState),
        throwsStateError,
        reason: 'Una solicitud archivada no puede volver a $activeState.',
      );
    }
    expect(repository.getRequestById(requestId)?.state, RequestState.reviewed);

    await _backToRequests(tester);
    await _switchToProfessional(tester);
    await _openProfessionalRequests(tester);
    await _selectProfessionalFilter(tester, 'Archivadas');
    await _expectRequestCard(
      tester,
      key: 'professional-request-$requestId',
      status: 'Servicio calificado',
    );
    await _tapVisible(
      tester,
      find.byKey(ValueKey('professional-request-$requestId')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Servicio calificado'), findsOneWidget);
    _expectNoArchivedActions();
    expect(find.text('Abrir conversación'), findsNothing);

    appRouter.go('/professional/professional-carlos');
    await tester.pumpAndSettle();
    expect(
      find.textContaining('(${finalSummary.reviewCount} reseñas)'),
      findsOneWidget,
    );
    expect(
      find.text('${finalSummary.completedJobsCount} servicios completados'),
      findsOneWidget,
    );

    appRouter.go(AppRoutes.professionalRequests);
    await tester.pumpAndSettle();
    await _selectProfessionalFilter(tester, 'Archivadas');
    await _expectRequestCard(
      tester,
      key: 'professional-request-$requestId',
      status: 'Servicio calificado',
    );
    await _switchToCustomer(tester);
    await _openCustomerRequests(tester);
    await _tapVisible(tester, find.text('Archivadas'));
    await tester.pumpAndSettle();
    await _tapVisible(
      tester,
      find.byKey(ValueKey('customer-request-$requestId')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Servicio calificado'), findsOneWidget);
    await _tapVisible(tester, find.text('Seguimiento'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('timeline-workCompleted-active')),
      findsOneWidget,
    );
    expect(
      repository
          .getTimeline(requestId)
          .firstWhere((event) => event.stage == TimelineStage.workCompleted)
          .dateLabel,
      'Ahora',
    );
    _expectNoArchivedActions();
    expect(find.text('Abrir conversación'), findsNothing);
    expect(repository.getMessages(requestId), isNotEmpty);

    await _backToRequests(tester);
    await _expectRequestCard(
      tester,
      key: 'customer-request-$requestId',
      status: 'Servicio calificado',
    );
    await _tapVisible(tester, find.text('Activas'));
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey('customer-request-$requestId')), findsNothing);

    await _switchToProfessional(tester);
    await _openProfessionalRequests(tester);
    await _selectProfessionalFilter(tester, 'Todas');
    expect(
      find.byKey(ValueKey('professional-request-$requestId')),
      findsNothing,
    );
    await _selectProfessionalFilter(tester, 'Archivadas');
    await _expectRequestCard(
      tester,
      key: 'professional-request-$requestId',
      status: 'Servicio calificado',
    );

    final customerFinalState = repository
        .getCustomerRequests(currentCustomerId)
        .singleWhere((request) => request.id == requestId)
        .state;
    final professionalFinalState = repository
        .getProfessionalRequests(currentProfessionalId)
        .singleWhere((request) => request.id == requestId)
        .state;
    expect(customerFinalState, RequestState.reviewed);
    expect(professionalFinalState, customerFinalState);

    await tester.pumpWidget(const SizedBox.shrink());
    appRouter.go(AppRoutes.customerRequests);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [requestRepositoryProvider.overrideWithValue(repository)],
        child: const LinkoApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Activas'), findsOneWidget);
    expect(find.byKey(ValueKey('customer-request-$requestId')), findsNothing);
    await _tapVisible(tester, find.text('Archivadas'));
    await tester.pumpAndSettle();
    await _expectRequestCard(
      tester,
      key: 'customer-request-$requestId',
      status: 'Servicio calificado',
    );
    expect(repository.getRequestById(requestId)?.state, RequestState.reviewed);
    _expectNoEnglishWorkflowText();
  });
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
  }
  expect(finder, findsAtLeastNWidgets(1));
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
  await tester.tap(finder.first);
}

Future<void> _expectRequestCard(
  WidgetTester tester, {
  required String key,
  required String status,
}) async {
  final card = find.byKey(ValueKey(key));
  if (card.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      card,
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
  }
  expect(card, findsOneWidget);
  await tester.ensureVisible(card);
  await tester.pumpAndSettle();
  expect(
    find.descendant(of: card, matching: find.text(status)),
    findsOneWidget,
  );
}

Future<void> _openCustomerRequests(WidgetTester tester) async {
  await _tapVisible(tester, find.byType(NavigationDestination).at(2));
  await tester.pumpAndSettle();
  expect(find.text('Mis solicitudes'), findsWidgets);
}

Future<void> _openProfessionalRequests(WidgetTester tester) async {
  await _tapVisible(tester, find.byType(NavigationDestination).at(1));
  await tester.pumpAndSettle();
  expect(find.text('Solicitudes'), findsWidgets);
}

Future<void> _switchToProfessional(WidgetTester tester) async {
  await _tapVisible(tester, find.byType(NavigationDestination).at(3));
  await tester.pumpAndSettle();
  await _tapVisible(
    tester,
    find.byKey(const ValueKey('switch-to-professional')),
  );
  await tester.pumpAndSettle();
  expect(find.text('Hola, Carlos'), findsOneWidget);
}

Future<void> _switchToCustomer(WidgetTester tester) async {
  await _tapVisible(tester, find.byType(NavigationDestination).at(3));
  await tester.pumpAndSettle();
  await _tapVisible(tester, find.byKey(const ValueKey('switch-to-customer')));
  await tester.pumpAndSettle();
  expect(find.text('¿Qué servicio necesitas hoy?'), findsOneWidget);
}

Future<void> _selectProfessionalFilter(
  WidgetTester tester,
  String label,
) async {
  await _tapVisible(tester, find.text(label));
  await tester.pumpAndSettle();
}

Future<void> _backToRequests(WidgetTester tester) async {
  expect(find.byType(BackButton), findsOneWidget);
  await tester.tap(find.byType(BackButton));
  await tester.pumpAndSettle();
  if (find.text('Detalle de solicitud').evaluate().isNotEmpty) {
    expect(find.byType(BackButton), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
  }
}

void _expectDetailNavigation() {
  expect(find.text('Detalle de solicitud'), findsOneWidget);
  expect(find.byType(BackButton), findsOneWidget);
}

void _expectSingleMessage(
  MockRequestRepository repository,
  String requestId,
  String text,
) {
  expect(
    repository.getMessages(requestId).where((message) => message.text == text),
    hasLength(1),
  );
}

void _expectNoEnglishWorkflowText() {
  const forbidden = [
    'In Progress',
    'Job Completed',
    'Confirm Job',
    'Report a Problem',
    'Pending Customer Confirmation',
    'Start Job',
    'Mark Job as Completed',
    'Reviewed',
  ];
  for (final text in forbidden) {
    expect(find.text(text), findsNothing);
  }
}

void _expectNoArchivedActions() {
  const obsoleteLabels = [
    'Enviar cotización',
    'Aceptar cotización',
    'Proponer fecha y hora',
    'Confirmar fecha',
    'Iniciar trabajo',
    'Marcar trabajo como completado',
    'Confirmar trabajo',
    'Calificar servicio',
  ];
  for (final label in obsoleteLabels) {
    expect(find.text(label), findsNothing);
  }

  const obsoleteKeys = [
    'professional-action-sendQuotation',
    'professional-action-proposeSchedule',
    'professional-action-startJob',
    'professional-action-markJobCompleted',
    'confirm-job',
    'submit-rating',
  ];
  for (final key in obsoleteKeys) {
    expect(find.byKey(ValueKey(key)), findsNothing);
  }
}
