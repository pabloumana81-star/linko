import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linko/app/app.dart';
import 'package:linko/app/router.dart';
import 'package:linko/core/utils/currency_formatter.dart';

void main() {
  test('colón formatter and calculated total use numeric values', () {
    expect(CurrencyFormatter.formatColones(25000), '₡25 000');
    expect(CurrencyFormatter.formatColones(125000), '₡125 000');
  });

  testWidgets('professional prepares, edits, and sends a quotation', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: LinkoApp()));
    appRouter.go(AppRoutes.professionalHome);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Solicitudes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver solicitud').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar cotización'));
    await tester.pumpAndSettle();

    expect(find.text('Ana Martínez'), findsOneWidget);
    expect(find.text('Costo del servicio'), findsOneWidget);
    expect(find.text('₡0'), findsNWidgets(3));

    await tester.tap(find.text('Revisar cotización'));
    await tester.pump();
    expect(find.text('Ingresa el costo de mano de obra.'), findsOneWidget);
    expect(find.text('Describe el trabajo incluido.'), findsOneWidget);
    expect(find.text('Selecciona una duración estimada.'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Mano de obra'),
      '25000',
    );
    await tester.pump();
    expect(find.text('₡25 000'), findsNWidgets(2));

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Materiales'),
      '10000',
    );
    await tester.pump();
    expect(find.text('₡35 000'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Descripción del trabajo'),
      'Muy corta',
    );
    await tester.tap(find.text('Revisar cotización'));
    await tester.pump();
    expect(
      find.text('La descripción debe tener al menos 20 caracteres.'),
      findsOneWidget,
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Descripción del trabajo'),
      'Incluye diagnóstico, limpieza y reparación completa del equipo.',
    );
    final duration = find.text('Medio día');
    await tester.drag(find.byType(ListView), const Offset(0, -450));
    await tester.pumpAndSettle();
    await tester.tap(duration);
    await tester.pump();

    final reviewButton = find.text('Revisar cotización');
    await tester.ensureVisible(reviewButton);
    await tester.tap(reviewButton);
    await tester.pumpAndSettle();

    expect(find.text('Revisar cotización'), findsOneWidget);
    expect(find.text('₡35 000'), findsOneWidget);
    expect(find.text('Medio día'), findsOneWidget);

    await tester.tap(find.text('Editar cotización'));
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(
        TextFormField,
        'Incluye diagnóstico, limpieza y reparación completa del equipo.',
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextFormField>(
            find.widgetWithText(TextFormField, 'Mano de obra'),
          )
          .controller
          ?.text,
      '25000',
    );

    await tester.ensureVisible(reviewButton);
    await tester.tap(reviewButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar cotización'));
    await tester.pumpAndSettle();

    expect(find.text('Cotización enviada'), findsOneWidget);
    expect(
      find.text('Ana Martínez podrá revisarla y responder desde LinkO.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Ver solicitudes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cotizadas'));
    await tester.pumpAndSettle();
    expect(find.text('Ana Martínez'), findsOneWidget);
    expect(find.text('Cotizada'), findsOneWidget);

    await tester.tap(find.text('Ver solicitud'));
    await tester.pumpAndSettle();
    expect(find.text('Ver cotización'), findsOneWidget);
    await tester.tap(find.text('Ver cotización'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar cotización'));
    await tester.pump();
    expect(
      find.text('Esta solicitud ya tiene una cotización.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'materials are optional and proposed date is conditionally required',
    (tester) async {
      appRouter.go('/professional/requests/request-diego-electric/quotation');
      await tester.pumpWidget(const ProviderScope(child: LinkoApp()));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mano de obra'),
        '0',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Descripción del trabajo'),
        'Revisión y reparación de todos los tomacorrientes indicados.',
      );
      await tester.drag(find.byType(ListView), const Offset(0, -450));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1 día'));
      await tester.drag(find.byType(ListView), const Offset(0, -350));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Proponer una fecha'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Revisar cotización'));
      await tester.tap(find.text('Revisar cotización'));
      await tester.pump();
      expect(find.text('El monto debe ser mayor que cero.'), findsOneWidget);
      expect(find.text('Selecciona una fecha propuesta.'), findsOneWidget);
      expect(find.textContaining('Materiales'), findsWidgets);
    },
  );
}
