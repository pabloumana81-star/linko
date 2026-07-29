import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linko/app/app.dart';
import 'package:linko/app/router.dart';
import 'package:linko/features/home/presentation/providers/professional_requests_provider.dart'
    show professionalRequestFlowProvider;
import 'package:linko/features/requests/domain/models/quotation.dart';
import 'package:linko/features/requests/domain/models/request_state.dart';
import 'package:linko/features/requests/presentation/providers/request_providers.dart';

void main() {
  const requestId = 'request-laura-maintenance';

  testWidgets('customer views and accepts a quotation', (tester) async {
    appRouter.go('/customer-requests/$requestId');
    await tester.pumpWidget(const ProviderScope(child: LinkoApp()));
    await tester.pumpAndSettle();

    expect(find.text('Ver cotización'), findsOneWidget);
    await tester.tap(find.text('Ver cotización'));
    await tester.pumpAndSettle();

    expect(find.text('Ver cotización'), findsOneWidget);
    expect(find.text('María Fernández'), findsOneWidget);
    expect(find.text('Limpieza'), findsOneWidget);
    expect(find.text('Qué incluye'), findsOneWidget);
    expect(find.text('Tiempo estimado'), findsOneWidget);
    expect(find.text('Fecha disponible'), findsOneWidget);
    expect(find.text('Garantía'), findsOneWidget);
    expect(find.text('₡ 65 000'), findsOneWidget);

    await tester.tap(find.text('Aceptar cotización'));
    await tester.pumpAndSettle();

    expect(find.text('Detalle de solicitud'), findsOneWidget);
    expect(find.text('Cotización aceptada'), findsOneWidget);
    expect(find.text('Ver cotización'), findsNothing);
    expect(find.text('Abrir conversación'), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.text('Detalle de solicitud')),
    );
    expect(
      container.read(requestDetailProvider(requestId))?.state,
      RequestState.accepted,
    );
  });

  testWidgets(
    'requesting changes inserts system message and opens conversation',
    (tester) async {
      appRouter.go('/customer-requests/$requestId');
      await tester.pumpWidget(const ProviderScope(child: LinkoApp()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ver cotización'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Solicitar cambios'));
      await tester.pumpAndSettle();

      expect(find.text('Conversación'), findsOneWidget);
      expect(
        find.text('El cliente solicitó cambios en la cotización.'),
        findsOneWidget,
      );
      final container = ProviderScope.containerOf(
        tester.element(find.text('Conversación').first),
      );
      expect(
        container.read(conversationProvider(requestId)).last.text,
        'El cliente solicitó cambios en la cotización.',
      );
    },
  );

  testWidgets(
    'accepted quotation is immediately visible to the assigned professional',
    (tester) async {
      await tester.pumpWidget(const ProviderScope(child: LinkoApp()));
      final container = ProviderScope.containerOf(
        tester.element(find.byType(LinkoApp)),
      );
      const carlosRequestId = 'request-ana-air';
      container
          .read(requestRepositoryProvider)
          .sendQuotation(
            const Quotation(
              requestId: carlosRequestId,
              laborAmount: 25000,
              materialsAmount: 5000,
              workDescription: 'Revisión y reparación completa del equipo.',
              estimatedDuration: 'Medio día',
              startTiming: 'Por coordinar con el cliente',
              validityDays: 7,
            ),
          );
      container
        ..invalidate(requestDetailProvider(carlosRequestId))
        ..invalidate(customerRequestsProvider)
        ..invalidate(professionalRequestsProvider)
        ..invalidate(professionalRequestFlowProvider);

      appRouter.go('/customer-requests/$carlosRequestId');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ver cotización'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aceptar cotización'));
      await tester.pumpAndSettle();

      expect(find.text('Cotización aceptada'), findsOneWidget);
      expect(
        container.read(requestDetailProvider(carlosRequestId))?.state,
        RequestState.accepted,
      );
      expect(
        container.read(conversationProvider(carlosRequestId)).last.text,
        'El cliente aceptó la cotización.',
      );

      appRouter.go(AppRoutes.professionalRequests);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aceptadas'));
      await tester.pumpAndSettle();

      expect(find.text('Ana Martínez'), findsOneWidget);
      expect(find.text('Cotización aceptada'), findsOneWidget);
      await tester.tap(find.text('Ver solicitud'));
      await tester.pumpAndSettle();

      expect(find.text('Cotización aceptada'), findsOneWidget);
      expect(find.text('Proponer fecha y hora'), findsOneWidget);
      await tester.tap(find.text('Proponer fecha y hora'));
      await tester.pumpAndSettle();

      expect(find.text('El cliente aceptó la cotización.'), findsOneWidget);
      expect(find.text('Proponer fecha y hora'), findsOneWidget);
    },
  );
}
