import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linko/app/app.dart';
import 'package:linko/app/router.dart';
import 'package:linko/features/home/presentation/data/placeholder_professionals.dart';
import 'package:linko/features/requests/domain/models/request_state.dart';
import 'package:linko/features/requests/presentation/providers/request_providers.dart';

void main() {
  testWidgets('customer rating requires stars and synchronizes every view', (
    tester,
  ) async {
    const requestId = 'request-elena-paint';
    appRouter.go('/customer-requests/$requestId');
    await tester.pumpWidget(const ProviderScope(child: LinkoApp()));
    await tester.pumpAndSettle();

    expect(find.text('Calificar servicio'), findsOneWidget);
    await tester.tap(find.text('Calificar servicio'));
    await tester.pumpAndSettle();

    expect(find.text('¿Cómo fue el servicio?'), findsOneWidget);
    final submitFinder = find.byKey(const ValueKey('submit-rating'));
    expect(tester.widget<FilledButton>(submitFinder).onPressed, isNull);

    final fourthStar = find.byKey(const ValueKey('rating-star-4'));
    await tester.drag(find.byType(ListView).first, const Offset(0, -420));
    await tester.pumpAndSettle();
    await tester.tap(fourthStar);
    await tester.pump();
    final commentField = find.byKey(const ValueKey('rating-comment'));
    await tester.ensureVisible(commentField);
    await tester.enterText(commentField, 'Muy buen servicio.');
    await tester.pump();
    expect(tester.widget<FilledButton>(submitFinder).onPressed, isNotNull);
    await tester.ensureVisible(submitFinder);
    await tester.tap(submitFinder);
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.text('Detalle de solicitud')),
    );
    expect(
      container.read(requestDetailProvider(requestId))?.state,
      RequestState.reviewed,
    );
    expect(container.read(ratingProvider(requestId))?.stars, 4);
    expect(
      container.read(ratingProvider(requestId))?.comment,
      'Muy buen servicio.',
    );
    expect(find.text('Servicio calificado'), findsOneWidget);
    expect(find.text('Calificar servicio'), findsNothing);
    expect(find.text('Enviar calificación'), findsNothing);
    expect(
      container.read(conversationProvider(requestId)).last.text,
      'El cliente calificó el servicio.',
    );

    appRouter.go(AppRoutes.customerRequests);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('Servicio calificado'), findsOneWidget);

    appRouter.go('/professional/requests/$requestId');
    await tester.pumpAndSettle();
    expect(find.text('Servicio calificado'), findsOneWidget);
    expect(find.text('Calificar servicio'), findsNothing);

    appRouter.goNamed(
      AppRouteNames.professionalProfile,
      pathParameters: {'professionalName': 'Daniel Morales'},
      extra: placeholderProfessionals.last,
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('(92 reseñas)'), findsOneWidget);
    expect(find.text('1 servicios completados'), findsOneWidget);
  });

  testWidgets('professional detail never exposes customer rating action', (
    tester,
  ) async {
    appRouter.go('/professional/requests/request-elena-paint');
    await tester.pumpWidget(const ProviderScope(child: LinkoApp()));
    await tester.pumpAndSettle();

    expect(find.text('Completada'), findsOneWidget);
    expect(find.text('Calificar servicio'), findsNothing);
    expect(find.text('Enviar calificación'), findsNothing);
  });
}
