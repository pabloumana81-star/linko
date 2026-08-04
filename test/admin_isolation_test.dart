import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linko/features/home/presentation/guest_home_screen.dart';

void main() {
  testWidgets('main app home never exposes administrative UI', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: GuestHomeScreen(
            onCategorySelected: (_) {},
            onCreateRequest: () {},
            onSearchRequested: () {},
            onSearchTabSelected: () {},
            onRequestsSelected: () {},
            onProfileSelected: () {},
            onProfessionalSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Admin Panel'), findsNothing);
    expect(find.byKey(const ValueKey('debug-admin-panel')), findsNothing);
    expect(find.textContaining('LinkO Admin'), findsNothing);
  });
}
