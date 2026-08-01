import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linko/app/app.dart';
import 'package:linko/app/router.dart';
import 'package:linko/core/theme/linko_theme.dart';
import 'package:linko/features/home/presentation/confirm_request_screen.dart';
import 'package:linko/features/home/presentation/data/placeholder_professionals.dart';
import 'package:linko/features/home/presentation/models/request_draft.dart';

void main() {
  testWidgets('navigates from splash to welcome after two seconds', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: LinkoApp()));

    expect(find.byIcon(Icons.handshake_rounded), findsOneWidget);
    expect(find.text('LinkO'), findsOneWidget);
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
    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Recibir enlace de acceso'), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);

    await tester.tap(find.text('Continuar como invitado'));
    await tester.pumpAndSettle();

    expect(find.byType(BackButton), findsOneWidget);
    expect(find.text('¿Cómo deseas usar LinkO?'), findsOneWidget);
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
    expect(find.text('Mis solicitudes'), findsOneWidget);
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
    expect(find.text('0 servicios completados'), findsOneWidget);
    expect(find.text('Responde en menos de 1 hora'), findsOneWidget);
    expect(find.text('Acerca de'), findsOneWidget);
    expect(find.text('Servicios'), findsOneWidget);
    expect(find.text('Trabajos realizados'), findsOneWidget);
    expect(find.text('Reseñas'), findsOneWidget);
    expect(find.text('Solicitar servicio'), findsOneWidget);
    expect(find.textContaining('Desde'), findsNothing);

    await tester.tap(find.text('Solicitar servicio'));
    await tester.pumpAndSettle();

    expect(find.text('Solicitar servicio'), findsOneWidget);
    expect(find.text('¿Qué necesitas?'), findsOneWidget);
    expect(
      find.text('Describe el trabajo que necesitas realizar.'),
      findsOneWidget,
    );
    expect(find.text('¿Dónde se realizará?'), findsOneWidget);
    expect(find.text('¿Cuándo lo necesitas?'), findsOneWidget);
    expect(find.text('Agrega fotos'), findsOneWidget);

    await tester.tap(find.text('Continuar'));
    await tester.pump();

    expect(
      find.text('Describe el trabajo que necesitas realizar.'),
      findsNWidgets(2),
    );
    expect(find.text('Ingresa la ubicación del servicio.'), findsOneWidget);
    expect(
      find.text('Selecciona cuándo necesitas el servicio.'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Necesito revisar una instalación eléctrica residencial.',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'San José, Escazú',
    );
    await tester.ensureVisible(find.text('Soy flexible'));
    await tester.tap(find.text('Soy flexible'));
    await tester.ensureVisible(find.text('Agregar fotos'));
    await tester.tap(find.text('Agregar fotos'));
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(find.text('Confirmar solicitud'), findsOneWidget);
    expect(find.text('Carlos Rodríguez'), findsOneWidget);
    expect(find.text('Electricista'), findsOneWidget);
    expect(find.text('Profesional verificado'), findsOneWidget);
    expect(
      find.text('Necesito revisar una instalación eléctrica residencial.'),
      findsOneWidget,
    );
    expect(find.text('San José, Escazú'), findsOneWidget);
    expect(find.text('Soy flexible'), findsOneWidget);
    expect(find.text('Fotos adjuntas'), findsOneWidget);
    expect(find.text('1 foto adjunta'), findsOneWidget);
    expect(
      find.text(
        'El profesional revisará tu solicitud y podrá enviarte una cotización.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(
      find.text('Necesito revisar una instalación eléctrica residencial.'),
      findsOneWidget,
    );
    expect(find.text('San José, Escazú'), findsOneWidget);
    expect(find.text('Soy flexible'), findsOneWidget);

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar solicitud'));
    await tester.pumpAndSettle();

    expect(find.text('Solicitud enviada'), findsOneWidget);
    expect(
      find.text('Tu solicitud fue enviada correctamente.'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Carlos Rodríguez recibirá tu solicitud y podrá responder con una '
        'cotización.',
      ),
      findsOneWidget,
    );
    expect(find.text('Ver mis solicitudes'), findsOneWidget);
    expect(find.text('Volver al inicio'), findsOneWidget);

    await tester.tap(find.text('Ver mis solicitudes'));
    await tester.pumpAndSettle();

    expect(find.text('Mis solicitudes'), findsNWidgets(2));
    expect(find.byType(BackButton), findsNothing);
    await tester.tap(find.text('Inicio'));
    await tester.pumpAndSettle();

    expect(find.text('¿Qué servicio necesitas hoy?'), findsOneWidget);
    await tester.ensureVisible(find.byType(TextField));
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    expect(find.byType(BackButton), findsOneWidget);
    expect(find.text('¿Qué servicio necesitas?'), findsOneWidget);
    expect(find.text('Servicios populares'), findsOneWidget);
    expect(find.text('Categorías'), findsOneWidget);
    expect(find.text('Resultados'), findsOneWidget);
    expect(find.text('Sofía Jiménez'), findsOneWidget);
    expect(find.text('Ver perfil'), findsNWidgets(5));

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();

    expect(find.byType(BackButton), findsNothing);
    expect(find.text('Servicios populares'), findsOneWidget);

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

    expect(find.byType(BackButton), findsNothing);
    expect(find.text('Hola, Carlos'), findsOneWidget);
  });

  testWidgets('confirmation shows photo and date summaries correctly', (
    tester,
  ) async {
    final professional = placeholderProfessionals.first;

    await tester.pumpWidget(
      MaterialApp(
        theme: LinkoTheme.light,
        home: ConfirmRequestScreen(
          draft: RequestDraft(
            professional: professional,
            description: 'Revisión de instalación eléctrica.',
            location: 'San José',
            timing: RequestTiming.flexible,
            attachedPhotoCount: 0,
          ),
          onSubmit: () {},
        ),
      ),
    );

    expect(find.text('Carlos Rodríguez'), findsOneWidget);
    expect(find.text('Profesional verificado'), findsOneWidget);
    expect(find.text('No se agregaron fotos'), findsOneWidget);
    expect(find.text('Fecha'), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        theme: LinkoTheme.light,
        home: ConfirmRequestScreen(
          draft: RequestDraft(
            professional: professional,
            description: 'Revisión de instalación eléctrica.',
            location: 'San José',
            timing: RequestTiming.specificDate,
            selectedDate: DateTime(2026, 8, 15),
            attachedPhotoCount: 2,
          ),
          onSubmit: () {},
        ),
      ),
    );

    expect(find.text('Fecha'), findsOneWidget);
    expect(find.text('15 de agosto de 2026'), findsOneWidget);
    expect(find.text('2 fotos adjuntas'), findsOneWidget);
  });
}
