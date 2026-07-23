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
      find.text('Connecting trusted professionals with people who need them.'),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Continue as Guest'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);
    expect(find.text('Continue with Email'), findsOneWidget);
    expect(find.text("I'm a Professional"), findsOneWidget);

    await tester.tap(find.text('Continue as Guest'));
    await tester.pumpAndSettle();

    expect(find.text('Who are you?'), findsOneWidget);
    expect(find.text('I need a professional'), findsOneWidget);
    expect(find.text("I'm a professional"), findsOneWidget);

    await tester.tap(find.text('I need a professional'));
    await tester.pumpAndSettle();

    expect(find.text('What service do you need?'), findsOneWidget);
    expect(find.text('Plumber'), findsOneWidget);
    expect(find.text('Appliance Repair'), findsOneWidget);
    expect(find.text('Request Service'), findsOneWidget);

    await tester.tap(find.text('Plumber'));
    await tester.pumpAndSettle();

    expect(find.text('Plumber'), findsNWidgets(2));
    expect(find.text('This feature will be implemented next.'), findsOneWidget);

    appRouter.go(AppRoutes.guestHome);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Request Service'));
    await tester.pumpAndSettle();

    expect(find.text('Create Request'), findsNWidgets(2));

    appRouter.go(AppRoutes.userType);
    await tester.pumpAndSettle();
    await tester.tap(find.text("I'm a professional"));
    await tester.pumpAndSettle();

    expect(find.text('Professional Home'), findsOneWidget);
  });
}
