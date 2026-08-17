import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linko/app/app.dart';
import 'package:linko/app/router.dart';
import 'package:linko/features/home/presentation/models/customer_service_request.dart';

void main() {
  testWidgets('shows mock requests and every allowed visual status', (
    tester,
  ) async {
    appRouter.go(AppRoutes.customerRequests);
    await tester.pumpWidget(const ProviderScope(child: LinkoApp()));
    await tester.pumpAndSettle();

    expect(find.text('Mis solicitudes'), findsNWidgets(2));
    expect(find.textContaining('Electricista'), findsWidgets);
    expect(find.text('Carlos Rodríguez'), findsOneWidget);
    expect(find.textContaining('Actualizada'), findsWidgets);
    expect(find.text('Ver solicitud'), findsNothing);
    expect(find.textContaining('Ubicación'), findsNothing);
    expect(find.textContaining('Disponibilidad'), findsNothing);
    expect(find.textContaining('Necesito revisar'), findsNothing);

    for (final label in [
      'Esperando respuesta',
      'En conversación',
      'Cotización recibida',
      'En progreso',
      'Completado',
    ]) {
      await tester.scrollUntilVisible(
        find.text(label),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('tapping the full card opens the selected request detail', (
    tester,
  ) async {
    appRouter.go(AppRoutes.customerRequests);
    await tester.pumpWidget(const ProviderScope(child: LinkoApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Electricista'));
    await tester.pumpAndSettle();

    expect(find.text('Detalle de solicitud'), findsOneWidget);
    expect(find.textContaining('Electricista'), findsOneWidget);
    expect(find.text('En construcción'), findsNothing);
    expect(find.text('Resumen de la solicitud'), findsOneWidget);
    expect(find.text('Profesional'), findsOneWidget);
    expect(find.text('Servicio solicitado · Ubicación'), findsOneWidget);
    expect(find.textContaining('Curridabat, San José'), findsOneWidget);
    expect(find.text('Estado actual'), findsOneWidget);
    expect(find.text('Siguiente paso'), findsOneWidget);
    expect(find.text('Resumen'), findsOneWidget);
    expect(find.text('Conversación'), findsOneWidget);
    expect(find.text('Seguimiento'), findsOneWidget);

    await tester.tap(find.text('Seguimiento'));
    await tester.pumpAndSettle();
    expect(find.text('Seguimiento del trabajo'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('timeline-professionalReviewing-active')),
      findsOneWidget,
    );

    await tester.tap(find.text('Conversación'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abrir conversación'));
    await tester.pumpAndSettle();

    expect(find.text('Conversación'), findsOneWidget);
    expect(find.text('Andrés Vargas'), findsOneWidget);
    expect(find.text('Electricista · En conversación'), findsOneWidget);
  });

  testWidgets('empty state search button opens the existing search flow', (
    tester,
  ) async {
    appRouter.go(
      AppRoutes.customerRequests,
      extra: const <CustomerServiceRequest>[],
    );
    await tester.pumpWidget(const ProviderScope(child: LinkoApp()));
    await tester.pumpAndSettle();

    expect(
      find.text('Todavía no has solicitado ningún servicio.'),
      findsOneWidget,
    );
    expect(find.text('Buscar profesionales'), findsOneWidget);

    await tester.tap(find.text('Buscar profesionales'));
    await tester.pumpAndSettle();

    expect(find.text('¿Qué servicio necesitas?'), findsOneWidget);
    expect(find.text('Servicios populares'), findsOneWidget);
  });
}
