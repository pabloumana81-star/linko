import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linko/app/app.dart';
import 'package:linko/app/router.dart';

void main() {
  testWidgets('navigates from splash to welcome after two seconds', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: LinkoApp()));

    expect(find.byIcon(Icons.handshake_rounded), findsOneWidget);
    expect(find.text('LINKO'), findsOneWidget);
    expect(
      find.text(
        'Conectamos profesionales de confianza con quienes los necesitan.',
      ),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Encuentra profesionales de confianza para cualquier necesidad.',
      ),
      findsOneWidget,
    );
    expect(find.text('Continuar como invitado'), findsOneWidget);
    expect(find.text('Continuar con Google'), findsOneWidget);
    expect(find.text('Continuar con Apple'), findsOneWidget);
    expect(find.text('Continuar con correo'), findsOneWidget);
    expect(find.text('Soy profesional'), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);

    await tester.tap(find.text('Continuar como invitado'));
    await tester.pumpAndSettle();

    expect(find.byType(BackButton), findsOneWidget);
    expect(find.text('¿Cómo deseas usar Linko?'), findsOneWidget);
    expect(find.text('Necesito un servicio'), findsOneWidget);
    expect(find.text('Quiero ofrecer mis servicios'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Continuar como invitado'), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);

    await tester.tap(find.text('Continuar como invitado'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Necesito un servicio'));
    await tester.pumpAndSettle();

    expect(find.byType(BackButton), findsNothing);
    expect(find.text('¿Qué servicio necesitas hoy?'), findsOneWidget);
    expect(
      find.text('Encuentra profesionales de confianza cerca de ti.'),
      findsOneWidget,
    );
    expect(find.text('Buscar un servicio...'), findsOneWidget);
    expect(find.text('Categorías'), findsOneWidget);
    expect(find.text('Electricista'), findsNWidgets(2));
    expect(find.text('Plomería'), findsNWidgets(2));
    expect(find.text('Aire acondicionado'), findsOneWidget);
    expect(find.text('Más servicios'), findsOneWidget);
    expect(find.text('Profesionales destacados'), findsOneWidget);
    expect(find.text('Carlos Rodríguez'), findsOneWidget);
    expect(find.text('Profesional verificado'), findsNWidgets(3));
    expect(find.text('Ver perfil'), findsNWidgets(3));
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Buscar'), findsOneWidget);
    expect(find.text('Solicitudes'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);

    await tester.ensureVisible(find.text('Ver perfil').first);
    await tester.tap(find.text('Ver perfil').first);
    await tester.pumpAndSettle();

    expect(find.byType(BackButton), findsOneWidget);
    expect(find.text('Perfil profesional'), findsOneWidget);
    expect(find.text('Carlos Rodríguez'), findsOneWidget);
    expect(find.text('Electricista'), findsOneWidget);
    expect(find.text('4.9 (128 reseñas)'), findsOneWidget);
    expect(find.text('San José'), findsOneWidget);
    expect(find.text('Profesional verificado'), findsOneWidget);
    expect(find.text('8 años de experiencia'), findsOneWidget);
    expect(find.text('145 servicios completados'), findsOneWidget);
    expect(find.text('Responde en menos de 1 hora'), findsOneWidget);
    expect(find.text('Acerca de'), findsOneWidget);
    expect(find.text('Servicios'), findsOneWidget);
    expect(find.text('Trabajos realizados'), findsOneWidget);
    expect(find.text('Reseñas'), findsOneWidget);
    expect(find.text('Solicitar servicio'), findsOneWidget);
    expect(find.textContaining('Desde'), findsNothing);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(TextField));
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    expect(find.byType(BackButton), findsOneWidget);
    expect(find.text('¿Qué servicio necesitas?'), findsOneWidget);
    expect(find.text('Búsquedas frecuentes'), findsOneWidget);
    expect(find.text('Categorías'), findsOneWidget);
    expect(find.text('Resultados'), findsOneWidget);
    expect(find.text('Sofía Jiménez'), findsOneWidget);
    expect(find.text('Ver perfil'), findsNWidgets(5));

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();

    expect(find.byType(BackButton), findsNothing);
    expect(find.text('Búsquedas frecuentes'), findsOneWidget);

    await tester.ensureVisible(find.text('Sofía Jiménez'));
    await tester.tap(find.text('Sofía Jiménez'));
    await tester.pumpAndSettle();

    expect(find.byType(BackButton), findsOneWidget);
    expect(find.text('Perfil profesional'), findsOneWidget);
    expect(find.text('Sofía Jiménez'), findsOneWidget);
    expect(find.text('Jardinería'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inicio'));
    await tester.pumpAndSettle();

    expect(find.text('¿Qué servicio necesitas hoy?'), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);

    await tester.tap(find.text('Plomería').first);
    await tester.pumpAndSettle();

    expect(find.byType(BackButton), findsOneWidget);
    expect(find.text('Resultados'), findsOneWidget);
    expect(find.text('Buscar un servicio...'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Plomería'), findsOneWidget);
    expect(find.text('Plomería'), findsWidgets);
    expect(find.text('Electricista'), findsNothing);
    expect(find.text('Cerca de mí'), findsOneWidget);
    expect(find.text('Mejor calificados'), findsOneWidget);
    expect(find.text('Verificados'), findsOneWidget);
    expect(find.text('4.9 (128 reseñas)'), findsOneWidget);
    expect(find.text('Verificado'), findsWidgets);
    expect(find.textContaining('Desde'), findsNothing);

    await tester.tap(find.text('Ver perfil').first);
    await tester.pumpAndSettle();

    expect(find.byType(BackButton), findsOneWidget);
    expect(find.text('Perfil profesional'), findsOneWidget);
    expect(find.text('Carlos Rodríguez'), findsOneWidget);
    expect(find.text('Plomería'), findsOneWidget);

    appRouter.go(AppRoutes.guestHome);
    await tester.pumpAndSettle();
    appRouter.push(AppRoutes.createRequest);
    await tester.pumpAndSettle();

    expect(find.byType(BackButton), findsOneWidget);
    expect(find.text('Crear solicitud'), findsNWidgets(2));

    appRouter.go(AppRoutes.userType);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quiero ofrecer mis servicios'));
    await tester.pumpAndSettle();

    expect(find.byType(BackButton), findsOneWidget);
    expect(find.text('Panel del profesional'), findsOneWidget);
  });
}
