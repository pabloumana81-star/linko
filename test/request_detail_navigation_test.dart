import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linko/app/app.dart';
import 'package:linko/app/app_mode.dart';
import 'package:linko/app/app_mode_provider.dart';
import 'package:linko/app/router.dart';
import 'package:linko/core/backend/backend_config.dart';
import 'package:linko/core/backend/backend_providers.dart';
import 'package:linko/core/backend/backend_repository_factory.dart';
import 'package:linko/core/backend/data/mock_backend_repositories.dart';
import 'package:linko/features/home/presentation/professional_request_detail_screen.dart';
import 'package:linko/features/home/presentation/customer_request_detail_screen.dart';
import 'package:linko/features/home/presentation/models/customer_service_request.dart';
import 'package:linko/features/requests/data/mock_request_repository.dart';
import 'package:linko/features/requests/domain/models/service_request.dart';
import 'package:linko/features/requests/domain/models/request_state.dart';
import 'package:linko/features/requests/domain/models/conversation_message.dart';
import 'package:linko/features/requests/presentation/adapters/request_view_adapters.dart';
import 'package:linko/features/requests/presentation/providers/request_providers.dart';

void main() {
  testWidgets('customer detail pops back to the customer request list', (
    tester,
  ) async {
    appRouter.go(AppRoutes.customerRequests);
    await tester.pumpWidget(const ProviderScope(child: LinkoApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Electricista'));
    await tester.pumpAndSettle();
    expect(find.byType(CustomerRequestDetailScreen), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Mis solicitudes'), findsNWidgets(2));
  });

  testWidgets(
    'professional detail pops back to the professional request list',
    (tester) async {
      appRouter.go(AppRoutes.professionalRequests);
      await tester.pumpWidget(const ProviderScope(child: LinkoApp()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ver solicitud').first);
      await tester.pumpAndSettle();
      expect(find.byType(BackButton), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('Solicitudes'), findsWidgets);
      expect(find.text('Nuevas'), findsOneWidget);
    },
  );

  testWidgets('direct customer detail navigation falls back safely', (
    tester,
  ) async {
    appRouter.go('/customer-requests/request-ana-air');
    await tester.pumpWidget(const ProviderScope(child: LinkoApp()));
    await tester.pumpAndSettle();

    expect(appRouter.canPop(), isFalse);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Mis solicitudes'), findsNWidgets(2));
  });

  testWidgets('direct professional detail navigation falls back safely', (
    tester,
  ) async {
    appRouter.go('/professional/requests/request-ana-air');
    await tester.pumpWidget(const ProviderScope(child: LinkoApp()));
    await tester.pumpAndSettle();

    expect(appRouter.canPop(), isFalse);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Solicitudes'), findsWidgets);
    expect(find.text('Nuevas'), findsOneWidget);
  });

  testWidgets('missing request route renders a controlled state', (
    tester,
  ) async {
    appRouter.go('/professional/requests/request-that-does-not-exist');
    await tester.pumpWidget(const ProviderScope(child: LinkoApp()));
    await tester.pumpAndSettle();

    expect(find.text('No se encontró la solicitud.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Supabase detail never reads the mock conversation provider', (
    tester,
  ) async {
    final source = MockRequestRepository();
    final repository = _RefreshableServiceRequestsRepository(source);
    final conversations = _SafeConversationRepository(source);
    repository.enqueueLoad();
    const requestId = 'cbd12fea-5eef-44b3-9cbb-3cb0b9bc7c1d';
    const snapshot = CustomerServiceRequest(
      id: requestId,
      serviceName: 'Electricista',
      categoryIcon: Icons.electrical_services_outlined,
      professionalName: 'Profesional',
      professionalAvatar: '',
      location: 'Escazú, San José',
      status: RequestState.quoted,
      updatedLabel: 'Ahora',
    );

    appRouter.goNamed(
      AppRouteNames.customerRequestDetail,
      pathParameters: const {'requestId': requestId},
      extra: snapshot,
    );
    await _pumpRouterWithRepository(
      tester,
      repository,
      conversations: conversations,
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(CustomerRequestDetailScreen), findsOneWidget);
    expect(find.text('Detalle de solicitud'), findsOneWidget);
    expect(find.textContaining('Escazú, San José'), findsOneWidget);
    expect(conversations.requestedIds, [requestId]);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(CustomerRequestDetailScreen)),
      listen: false,
    );
    container
      ..read(appModeProvider.notifier).select(AppMode.professional)
      ..invalidate(requestConversationMessagesProvider(requestId));
    await tester.pump();
    await tester.pump();
    container.read(appModeProvider.notifier).select(AppMode.customer);
    expect(conversations.requestedIds, [requestId, requestId]);
    expect(find.byType(CustomerRequestDetailScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'customer route renders its card snapshot while lookup and refresh wait',
    (tester) async {
      final source = MockRequestRepository();
      final request = source.getCustomerRequests('customer-ana').first;
      final repository = _RefreshableServiceRequestsRepository(source);
      final initialLoad = repository.enqueueLoad();

      appRouter.goNamed(
        AppRouteNames.customerRequestDetail,
        pathParameters: {'requestId': request.id},
        extra: request.toCustomerRequest(),
      );
      await _pumpRouterWithRepository(tester, repository);
      await tester.pump();

      expect(find.byType(CustomerRequestDetailScreen), findsOneWidget);
      expect(find.text('Detalle de solicitud'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.byType(CustomerRequestDetailScreen), findsOneWidget);

      initialLoad.complete(request);
      await tester.pump();
      await tester.pump();

      final refresh = repository.enqueueLoad();
      final context = tester.element(find.byType(CustomerRequestDetailScreen));
      ProviderScope.containerOf(
        context,
        listen: false,
      ).invalidate(persistedRequestDetailProvider(request.id));
      await tester.pump();

      expect(find.byType(CustomerRequestDetailScreen), findsOneWidget);
      expect(find.text('Detalle de solicitud'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      refresh.complete(request);
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  for (final scenario in [
    (id: 'request-laura-maintenance', showsQuotation: true),
    (id: 'request-ana-air', showsQuotation: false),
  ]) {
    testWidgets(
      'Supabase-mode detail ${scenario.showsQuotation ? 'with' : 'without'} quotation uses production conversation dependency',
      (tester) async {
        final source = MockRequestRepository();
        final request = source.getRequestById(scenario.id)!;
        final repository = _RefreshableServiceRequestsRepository(source);
        final conversations = _SafeConversationRepository(source);
        final load = repository.enqueueLoad();

        appRouter.goNamed(
          AppRouteNames.customerRequestDetail,
          pathParameters: {'requestId': request.id},
          extra: request.toCustomerRequest(),
        );
        await _pumpRouterWithRepository(
          tester,
          repository,
          conversations: conversations,
        );
        load.complete(request);
        await tester.pump();
        await tester.pump();
        await tester.pump();

        expect(find.byType(CustomerRequestDetailScreen), findsOneWidget);
        expect(
          find.text('Ver cotización'),
          scenario.showsQuotation ? findsOneWidget : findsNothing,
        );
        expect(conversations.requestedIds, contains(request.id));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('customer route reconstructs by ID without GoRouterState.extra', (
    tester,
  ) async {
    final source = MockRequestRepository();
    final request = source.getCustomerRequests('customer-ana').first;
    final repository = _RefreshableServiceRequestsRepository(source);
    final load = repository.enqueueLoad();

    appRouter.go('/customer-requests/${request.id}');
    await _pumpRouterWithRepository(tester, repository);
    await tester.pump();

    expect(find.text('Cargando solicitud…'), findsOneWidget);
    expect(find.byType(CustomerRequestDetailScreen), findsNothing);

    load.complete(request);
    await tester.pump();
    await tester.pump();

    expect(find.byType(CustomerRequestDetailScreen), findsOneWidget);
    expect(find.text('Detalle de solicitud'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('customer route renders controlled not-found and error states', (
    tester,
  ) async {
    final source = MockRequestRepository();
    final request = source.getCustomerRequests('customer-ana').first;
    final missingRepository = _RefreshableServiceRequestsRepository(source);
    final missing = missingRepository.enqueueLoad();

    appRouter.go('/customer-requests/${request.id}');
    await _pumpRouterWithRepository(tester, missingRepository);
    missing.complete(null);
    await tester.pump();
    await tester.pump();
    expect(find.text('No se encontró la solicitud.'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);

    final errorRepository = _RefreshableServiceRequestsRepository(source);
    final failed = errorRepository.enqueueLoad();
    appRouter.go('/customer-requests/${request.id}');
    await _pumpRouterWithRepository(tester, errorRepository);
    failed.completeError(StateError('lookup failed'));
    await tester.pump();
    await tester.pump();
    expect(find.text('No pudimos cargar la solicitud.'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.text('Volver'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'professional detail keeps its route snapshot during load and refresh',
    (tester) async {
      final requestRepository = MockRequestRepository();
      final serviceRequest = requestRepository
          .getProfessionalRequests('professional-carlos')
          .first;
      final backend = const BackendRepositoryFactory().create(
        config: const BackendConfig(mode: BackendMode.mock),
      );
      final refreshableRepository = _RefreshableServiceRequestsRepository(
        requestRepository,
      );
      final initialLoad = refreshableRepository.enqueueLoad();
      final repositories = BackendRepositories(
        mode: BackendMode.supabase,
        authentication: backend.authentication,
        professionals: backend.professionals,
        profile: backend.profile,
        serviceRequests: refreshableRepository,
        conversations: backend.conversations,
        quotations: backend.quotations,
        ratings: backend.ratings,
        reports: backend.reports,
        mvpCompatibilityRequests: backend.mvpCompatibilityRequests,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            backendRepositoriesProvider.overrideWithValue(repositories),
            activeServiceRequestsRepositoryProvider.overrideWithValue(
              refreshableRepository,
            ),
          ],
          child: MaterialApp(
            home: ProfessionalRequestDetailScreen(
              request: serviceRequest.toIncomingRequest(),
              onBack: () {},
              onSendQuotation: (_) {},
              onOpenConversation: (_) {},
              onStartJob: (_) {},
              onMarkJobCompleted: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Detalle de solicitud'), findsOneWidget);
      expect(find.text(serviceRequest.description), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      initialLoad.complete(serviceRequest);
      await tester.pump();
      await tester.pump();

      final refresh = refreshableRepository.enqueueLoad();
      final context = tester.element(
        find.byType(ProfessionalRequestDetailScreen),
      );
      ProviderScope.containerOf(
        context,
        listen: false,
      ).invalidate(persistedRequestDetailProvider(serviceRequest.id));
      await tester.pump();

      expect(find.text('Detalle de solicitud'), findsOneWidget);
      expect(find.text(serviceRequest.description), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      refresh.complete(serviceRequest);
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('transient routes do not crash when extra is absent', (
    tester,
  ) async {
    appRouter.go(AppRoutes.confirmRequest);
    await tester.pumpWidget(const ProviderScope(child: LinkoApp()));
    await tester.pumpAndSettle();
    expect(
      find.text('No se encontraron los datos de la solicitud.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    appRouter.go(AppRoutes.requestSuccess);
    await tester.pumpAndSettle();
    expect(find.text('No se encontró la solicitud.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpRouterWithRepository(
  WidgetTester tester,
  _RefreshableServiceRequestsRepository repository, {
  _SafeConversationRepository? conversations,
}) async {
  final backend = const BackendRepositoryFactory().create(
    config: const BackendConfig(mode: BackendMode.mock),
  );
  final repositories = BackendRepositories(
    mode: BackendMode.supabase,
    authentication: backend.authentication,
    professionals: backend.professionals,
    profile: backend.profile,
    serviceRequests: repository,
    conversations:
        conversations ??
        _SafeConversationRepository(backend.mvpCompatibilityRequests),
    quotations: backend.quotations,
    ratings: backend.ratings,
    reports: backend.reports,
    mvpCompatibilityRequests: backend.mvpCompatibilityRequests,
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        backendRepositoriesProvider.overrideWithValue(repositories),
        activeServiceRequestsRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp.router(routerConfig: appRouter),
    ),
  );
}

class _RefreshableServiceRequestsRepository
    extends MockServiceRequestsRepository {
  _RefreshableServiceRequestsRepository(super.requests);

  final _loads = <Completer<ServiceRequest?>>[];

  Completer<ServiceRequest?> enqueueLoad() {
    final load = Completer<ServiceRequest?>();
    _loads.add(load);
    return load;
  }

  @override
  Future<ServiceRequest?> getRequestById(String requestId) {
    if (_loads.isEmpty) {
      throw StateError('No se configuró la carga de la solicitud.');
    }
    return _loads.removeAt(0).future;
  }
}

class _SafeConversationRepository extends MockConversationsRepository {
  _SafeConversationRepository(super.requests);

  final requestedIds = <String>[];

  @override
  Future<List<ConversationMessage>> getMessages(String requestId) async {
    requestedIds.add(requestId);
    return const [];
  }
}
