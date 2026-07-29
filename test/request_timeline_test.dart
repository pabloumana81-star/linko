import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linko/features/home/presentation/widgets/request_timeline.dart';
import 'package:linko/features/requests/domain/models/request_state.dart';

void main() {
  testWidgets(
    'renders all timeline steps with active, completed, and pending states',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RequestTimeline(requestStatus: RequestState.accepted),
            ),
          ),
        ),
      );

      for (final label in [
        'Solicitud enviada',
        'Profesional revisando',
        'Cotización enviada',
        'Cotización aceptada',
        'Trabajo programado',
        'Trabajo en progreso',
        'Trabajo completado',
      ]) {
        expect(find.text(label), findsOneWidget);
      }

      expect(
        find.byKey(const ValueKey('timeline-quotationAccepted-active')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('timeline-quotationSent-completed')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('timeline-workScheduled-pending')),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.check_rounded), findsNWidgets(3));
    },
  );
}
