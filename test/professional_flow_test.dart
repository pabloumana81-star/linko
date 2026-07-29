import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linko/app/app.dart';
import 'package:linko/app/router.dart';
import 'package:linko/core/utils/currency_formatter.dart';
import 'package:linko/features/home/presentation/models/quotation_draft.dart';
import 'package:linko/features/home/presentation/quotation_review_screen.dart';
import 'package:linko/features/requests/data/mock_request_repository.dart';
import 'package:linko/features/requests/presentation/adapters/request_view_adapters.dart';

void main() {
  test('colón formatter and calculated total use numeric values', () {
    expect(CurrencyFormatter.formatColones(25000), '₡ 25 000');
    expect(CurrencyFormatter.formatColones(150500), '₡ 150 500');
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
    expect(find.text('₡ 0'), findsNWidgets(3));

    await tester.tap(find.text('Revisar cotización'));
    await tester.pump();
    expect(
      find.text('Ingresa un monto válido en mano de obra o materiales.'),
      findsOneWidget,
    );
    expect(find.text('Describe el trabajo incluido.'), findsOneWidget);
    expect(find.text('Selecciona una duración estimada.'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Mano de obra'),
      '25000',
    );
    await tester.pump();
    expect(find.text('₡ 25 000'), findsNWidgets(2));

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Materiales'),
      '10000',
    );
    await tester.pump();
    expect(find.text('₡ 35 000'), findsOneWidget);

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
    expect(find.text('₡ 35 000'), findsOneWidget);
    expect(find.text('Medio día'), findsOneWidget);
    expect(find.text('Ubicación: Escazú, San José'), findsOneWidget);
    expect(find.text('Disponibilidad: Lo antes posible'), findsOneWidget);

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
      find.text(
        'Tu cotización fue enviada correctamente.\n\n'
        'El cliente podrá revisarla y responder desde la conversación.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Volver a solicitudes'));
    await tester.pumpAndSettle();
    final quotedFilter = find.widgetWithText(FilterChip, 'Cotizadas');
    expect(tester.widget<FilterChip>(quotedFilter).selected, isTrue);
    expect(find.text('Cotización enviada correctamente.'), findsOneWidget);
    expect(find.text('Ana Martínez'), findsOneWidget);
    expect(find.text('Cotizada'), findsWidgets);

    await tester.tap(find.text('Ver solicitud').first);
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
      expect(
        find.text('Ingresa un monto válido en mano de obra o materiales.'),
        findsOneWidget,
      );
      expect(find.text('Selecciona una fecha propuesta.'), findsOneWidget);
      expect(find.textContaining('Materiales'), findsWidgets);
    },
  );

  testWidgets('review blocks sending when the calculated total is zero', (
    tester,
  ) async {
    var sent = false;
    final request = MockRequestRepository()
        .getProfessionalRequests('professional-carlos')
        .first
        .toIncomingRequest();
    final draft = QuotationDraft(
      requestId: request.id,
      customerName: request.customerName,
      serviceCategory: request.serviceCategory,
      workDescription: 'Diagnóstico completo del equipo solicitado.',
      laborAmount: 0,
      estimatedDuration: QuotationDuration.oneDay,
      startTiming: QuotationStartTiming.asSoonAsPossible,
      validityDays: 7,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: QuotationReviewScreen(
          request: request,
          draft: draft,
          onEdit: () {},
          onSend: () => sent = true,
        ),
      ),
    );

    final sendButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Enviar cotización'),
    );
    expect(sendButton.onPressed, isNull);
    expect(
      find.text('Ingresa un monto válido antes de enviar.'),
      findsOneWidget,
    );
    expect(sent, isFalse);
  });
}
