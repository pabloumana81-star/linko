import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linko/app/app.dart';
import 'package:linko/app/router.dart';
import 'package:linko/features/auth/presentation/welcome_screen.dart';

void main() {
  testWidgets('startup remains accessible across representative web widths', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    for (final size in const [
      Size(320, 568),
      Size(390, 844),
      Size(768, 900),
      Size(1440, 900),
    ]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MaterialApp(
          home: WelcomeScreen(
            onContinueAsGuest: () {},
            onGoogleSignIn: () {},
            onAppleSignIn: () {},
            onSendEmailLink: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'Ancho ${size.width}');
      expect(find.bySemanticsLabel('Continuar como invitado'), findsOneWidget);
      expect(find.bySemanticsLabel('Continuar con Google'), findsOneWidget);
      expect(find.bySemanticsLabel('Continuar con Apple'), findsOneWidget);
      expect(find.bySemanticsLabel('Correo electrónico'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus, isNotNull);
    }
    semantics.dispose();
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });

  testWidgets(
    'customer browser smoke supports text scaling and profile route',
    (tester) async {
      await _configureCompactScaledView(tester);
      appRouter.go(AppRoutes.splash);
      await tester.pumpWidget(const ProviderScope(child: LinkoApp()));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const ValueKey('auth-guest')));
      await tester.tap(find.byKey(const ValueKey('auth-guest')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Necesito un servicio'));
      await tester.tap(find.text('Necesito un servicio'));
      await tester.pumpAndSettle();
      expect(find.text('¿Qué servicio necesitas hoy?'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.text('Ver perfil').first);
      await tester.tap(find.text('Ver perfil').first);
      await tester.pumpAndSettle();
      expect(find.text('Perfil profesional'), findsOneWidget);
      expect(find.text('Solicitar servicio'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'professional browser smoke reaches profile and Storage controls',
    (tester) async {
      await _configureCompactScaledView(tester, textScaleFactor: 1.6);
      appRouter.go(AppRoutes.splash);
      await tester.pumpWidget(const ProviderScope(child: LinkoApp()));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const ValueKey('auth-guest')));
      await tester.tap(find.byKey(const ValueKey('auth-guest')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Quiero ofrecer mis servicios'));
      await tester.tap(find.text('Quiero ofrecer mis servicios'));
      await tester.pumpAndSettle();
      expect(find.text('Solicitudes recientes'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Perfil'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('add-portfolio-image')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('add-verification-document')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _configureCompactScaledView(
  WidgetTester tester, {
  double textScaleFactor = 2,
}) async {
  await tester.binding.setSurfaceSize(const Size(320, 700));
  tester.platformDispatcher.textScaleFactorTestValue = textScaleFactor;
  addTearDown(() async {
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    await tester.binding.setSurfaceSize(null);
  });
}
