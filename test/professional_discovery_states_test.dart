import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linko/app/app.dart';
import 'package:linko/app/router.dart';
import 'package:linko/features/home/presentation/data/placeholder_professionals.dart';
import 'package:linko/features/home/presentation/models/professional_profile_data.dart';
import 'package:linko/features/home/presentation/providers/professional_discovery_provider.dart';
import 'package:linko/features/home/presentation/professionals_results_screen.dart';

void main() {
  testWidgets('results keep loading distinct from empty and error', (
    tester,
  ) async {
    await _pumpResults(tester, const AsyncLoading());

    expect(find.text('Buscando profesionales…'), findsOneWidget);
    expect(find.text(_emptyTitle), findsNothing);
    expect(find.text(_errorTitle), findsNothing);
  });

  testWidgets('zero matching results show actionable empty state', (
    tester,
  ) async {
    await _pumpResults(tester, const AsyncData([]));

    expect(find.text(_emptyTitle), findsOneWidget);
    expect(find.text(_emptyBody), findsOneWidget);
    expect(find.text('Buscar otro servicio'), findsOneWidget);
    expect(find.text('Volver al inicio'), findsOneWidget);
    expect(find.text(_errorTitle), findsNothing);
  });

  testWidgets('successful results keep the existing professional card', (
    tester,
  ) async {
    final professional = placeholderProfessionals.first;
    await _pumpResults(tester, AsyncData([professional]));

    expect(find.text(professional.name), findsOneWidget);
    expect(find.text(professional.location), findsOneWidget);
    expect(find.text('Ver perfil'), findsOneWidget);
    expect(find.text(_emptyTitle), findsNothing);
    expect(find.text(_errorTitle), findsNothing);
  });

  testWidgets('repository error shows retry and retry reloads discovery', (
    tester,
  ) async {
    var loads = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          professionalDiscoveryProvider.overrideWith((ref) {
            loads++;
            return loads == 1
                ? AsyncError<List<ProfessionalProfileData>>(
                    StateError('network'),
                    StackTrace.current,
                  )
                : AsyncData([placeholderProfessionals.first]);
          }),
        ],
        child: MaterialApp(
          home: ProfessionalsResultsScreen(
            selectedService: 'Electricista',
            onProfessionalSelected: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(_errorTitle), findsOneWidget);
    expect(
      find.text('Revisa tu conexión e inténtalo nuevamente.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Reintentar'));
    await tester.pump();

    expect(loads, 2);
    expect(find.text(placeholderProfessionals.first.name), findsOneWidget);
    expect(find.text(_errorTitle), findsNothing);
  });

  testWidgets('Buscar otro servicio navigates to the search screen', (
    tester,
  ) async {
    appRouter.go('/results/Electricista');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          professionalDiscoveryProvider.overrideWithValue(const AsyncData([])),
        ],
        child: const LinkoApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Buscar otro servicio'));
    await tester.pumpAndSettle();

    expect(find.text('Servicios populares'), findsOneWidget);
    expect(find.text('Categorías'), findsOneWidget);
  });

  testWidgets('Volver al inicio navigates to customer home', (tester) async {
    appRouter.go('/results/Electricista');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          professionalDiscoveryProvider.overrideWithValue(const AsyncData([])),
        ],
        child: const LinkoApp(),
      ),
    );
    await tester.pumpAndSettle();

    final homeAction = find.text('Volver al inicio');
    await tester.ensureVisible(homeAction);
    await tester.tap(homeAction);
    await tester.pumpAndSettle();

    expect(find.text('¿Qué servicio necesitas hoy?'), findsOneWidget);
    expect(find.text('Servicios populares'), findsNothing);
  });
}

const _emptyTitle = 'No encontramos profesionales disponibles';
const _emptyBody =
    'Todavía no hay profesionales disponibles para este servicio. '
    'Estamos sumando nuevos profesionales a LinkO.';
const _errorTitle = 'No pudimos cargar los profesionales';

Future<void> _pumpResults(
  WidgetTester tester,
  AsyncValue<List<ProfessionalProfileData>> state,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [professionalDiscoveryProvider.overrideWithValue(state)],
      child: MaterialApp(
        home: ProfessionalsResultsScreen(
          selectedService: 'Electricista',
          onProfessionalSelected: (_) {},
        ),
      ),
    ),
  );
  await tester.pump();
}
