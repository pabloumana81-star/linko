import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linko/app/app.dart';

void main() {
  testWidgets('displays the Linko splash screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LinkoApp()));

    expect(find.byIcon(Icons.handshake_rounded), findsOneWidget);
    expect(find.text('LINKO'), findsOneWidget);
    expect(
      find.text('Connecting trusted professionals with people who need them.'),
      findsOneWidget,
    );
  });
}
