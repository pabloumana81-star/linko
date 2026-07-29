import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linko/app/app.dart';
import 'package:linko/app/app_mode.dart';
import 'package:linko/app/app_mode_provider.dart';
import 'package:linko/app/router.dart';

void main() {
  testWidgets('initial customer selection opens customer Home as root', (
    tester,
  ) async {
    appRouter.go(AppRoutes.userType);
    await tester.pumpWidget(const ProviderScope(child: LinkoApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Necesito un servicio'));
    await tester.pumpAndSettle();

    expect(find.text('¿Qué servicio necesitas hoy?'), findsOneWidget);
    expect(find.text('Buscar'), findsOneWidget);
    expect(find.text('Mis solicitudes'), findsOneWidget);
    expect(find.text('Servicios'), findsNothing);
    expect(appRouter.canPop(), isFalse);
    final container = ProviderScope.containerOf(
      tester.element(find.text('¿Qué servicio necesitas hoy?')),
    );
    expect(container.read(appModeProvider), AppMode.customer);
  });

  testWidgets(
    'initial professional selection opens professional Home as root',
    (tester) async {
      appRouter.go(AppRoutes.userType);
      await tester.pumpWidget(const ProviderScope(child: LinkoApp()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Quiero ofrecer mis servicios'));
      await tester.pumpAndSettle();

      expect(find.text('Hola, Carlos'), findsOneWidget);
      expect(find.text('Solicitudes'), findsOneWidget);
      expect(find.text('Servicios'), findsOneWidget);
      expect(find.text('Mis solicitudes'), findsNothing);
      expect(appRouter.canPop(), isFalse);
      final container = ProviderScope.containerOf(
        tester.element(find.text('Hola, Carlos')),
      );
      expect(container.read(appModeProvider), AppMode.professional);
    },
  );

  testWidgets('profile switches both modes and rebuilds bottom navigation', (
    tester,
  ) async {
    appRouter.go(AppRoutes.guestHome);
    await tester.pumpWidget(const ProviderScope(child: LinkoApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    expect(find.text('Modo de uso'), findsOneWidget);
    expect(find.text('Cliente'), findsOneWidget);
    expect(find.text('Cambiar a profesional'), findsOneWidget);

    await tester.tap(find.text('Cambiar a profesional'));
    await tester.pumpAndSettle();
    expect(find.text('Hola, Carlos'), findsOneWidget);
    expect(find.text('Servicios'), findsOneWidget);
    expect(find.text('Buscar'), findsNothing);
    expect(appRouter.canPop(), isFalse);
    var container = ProviderScope.containerOf(
      tester.element(find.text('Hola, Carlos')),
    );
    expect(container.read(appModeProvider), AppMode.professional);

    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    expect(find.text('Modo de uso'), findsOneWidget);
    expect(find.text('Profesional'), findsOneWidget);
    expect(find.text('Cambiar a cliente'), findsOneWidget);

    await tester.tap(find.text('Cambiar a cliente'));
    await tester.pumpAndSettle();
    expect(find.text('¿Qué servicio necesitas hoy?'), findsOneWidget);
    expect(find.text('Buscar'), findsOneWidget);
    expect(find.text('Mis solicitudes'), findsOneWidget);
    expect(find.text('Servicios'), findsNothing);
    expect(appRouter.canPop(), isFalse);
    container = ProviderScope.containerOf(
      tester.element(find.text('¿Qué servicio necesitas hoy?')),
    );
    expect(container.read(appModeProvider), AppMode.customer);
  });
}
