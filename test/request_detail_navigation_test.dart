import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linko/app/app.dart';
import 'package:linko/app/router.dart';

void main() {
  testWidgets('customer detail pops back to the customer request list', (
    tester,
  ) async {
    appRouter.go(AppRoutes.customerRequests);
    await tester.pumpWidget(const ProviderScope(child: LinkoApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Electricista'));
    await tester.pumpAndSettle();
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
