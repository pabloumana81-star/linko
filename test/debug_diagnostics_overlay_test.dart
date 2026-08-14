import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linko/app/app.dart';
import 'package:linko/app/router.dart';

void main() {
  testWidgets('visible diagnostics overlay is disabled by default', (
    tester,
  ) async {
    appRouter.go(AppRoutes.welcome);
    await tester.pumpWidget(const ProviderScope(child: LinkoApp()));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('debug-diagnostics-overlay')),
      findsNothing,
    );
    expect(find.text('LinkO'), findsOneWidget);
  });
}
