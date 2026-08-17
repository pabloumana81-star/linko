import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linko/app/app.dart';
import 'package:linko/app/app_mode.dart';
import 'package:linko/app/router.dart';
import 'package:linko/core/backend/backend_providers.dart';
import 'package:linko/core/backend/data/mock_backend_repositories.dart';
import 'package:linko/features/auth/domain/models/app_user_profile.dart';
import 'package:linko/features/home/presentation/providers/professional_discovery_provider.dart';
import 'package:linko/features/home/presentation/widgets/request_card.dart';
import 'package:linko/features/requests/presentation/providers/request_providers.dart';

void main() {
  testWidgets(
    'complete customer hiring route stays rendered through invalidations',
    (tester) async {
      appRouter.go(AppRoutes.guestHome);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
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
      final container = ProviderScope.containerOf(
        tester.element(find.text('¿Qué servicio necesitas hoy?')),
        listen: false,
      );

      container.invalidate(professionalDiscoveryProvider);
      await tester.tap(find.text('Electricista').first);
      await tester.pumpAndSettle();
      expect(find.text('Resultados'), findsOneWidget);

      container.invalidate(professionalDiscoveryProvider);
      await tester.pump();
      expect(find.text('Resultados'), findsOneWidget);
      await tester.tap(find.text('Ver perfil').first);
      await tester.pumpAndSettle();
      expect(find.text('Perfil profesional'), findsOneWidget);

      final professionalId =
          appRouter.routeInformationProvider.value.uri.pathSegments.last;
      container.invalidate(professionalProfileByIdProvider(professionalId));
      await tester.pump();
      expect(find.text('Solicitar servicio'), findsOneWidget);

      await tester.tap(find.text('Solicitar servicio'));
      await tester.pumpAndSettle();
      expect(find.text('¿Qué necesitas?'), findsOneWidget);

      container.invalidate(professionalProfileByIdProvider(professionalId));
      await tester.pump();
      expect(find.text('¿Qué necesitas?'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('request-description')),
        'Necesito revisar una instalación eléctrica residencial.',
      );
      await tester.enterText(
        find.byKey(const ValueKey('request-location')),
        'San José, Escazú',
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('request-timing-flexible')),
      );
      await tester.tap(find.byKey(const ValueKey('request-timing-flexible')));
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(find.text('Confirmar solicitud'), findsOneWidget);

      container
        ..invalidate(professionalDiscoveryProvider)
        ..invalidate(customerRequestsProvider);
      await tester.pump();
      expect(find.text('Confirmar solicitud'), findsOneWidget);
      await tester.tap(find.text('Enviar solicitud'));
      await tester.pumpAndSettle();
      expect(find.text('Solicitud enviada'), findsOneWidget);

      container.invalidate(customerRequestsProvider);
      await tester.tap(find.text('Ver mis solicitudes'));
      await tester.pumpAndSettle();
      expect(find.text('Mis solicitudes'), findsNWidgets(2));

      final request = container.read(customerRequestsProvider).first;
      container.invalidate(requestDetailProvider(request.id));
      final requestCard = find.byType(RequestCard).first;
      await tester.ensureVisible(requestCard);
      await tester.tap(requestCard);
      await tester.pumpAndSettle();
      expect(find.text('Detalle de solicitud'), findsOneWidget);
      expect(find.text('Resumen'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
