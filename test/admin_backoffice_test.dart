import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linko/app/app.dart';
import 'package:linko/app/app_mode.dart';
import 'package:linko/app/router.dart';
import 'package:linko/core/backend/backend_providers.dart';
import 'package:linko/core/backend/data/mock_backend_repositories.dart';
import 'package:linko/features/admin/domain/admin_section.dart';
import 'package:linko/features/auth/domain/models/app_user_profile.dart';

void main() {
  final admin = AppUserProfile(
    id: 'admin-user',
    displayName: 'Administradora LinkO',
    email: 'admin@linko.test',
    avatarUrl: null,
    activeMode: AppMode.customer,
    role: UserRole.admin,
    createdAt: DateTime.utc(2026),
  );
  final regularUser = AppUserProfile(
    id: 'regular-user',
    displayName: 'Usuario LinkO',
    email: 'user@linko.test',
    avatarUrl: null,
    activeMode: AppMode.customer,
    createdAt: DateTime.utc(2026),
  );

  testWidgets('admin access is allowed', (tester) async {
    await _pumpAdminRoute(tester, admin, AppRoutes.adminDashboard);

    expect(
      find.byKey(const ValueKey('admin-section-dashboard')),
      findsOneWidget,
    );
    expect(find.text('Acceso restringido'), findsNothing);
  });

  testWidgets('non-admin users are blocked from admin routes', (tester) async {
    await _pumpAdminRoute(tester, regularUser, AppRoutes.adminDashboard);

    expect(find.text('Acceso restringido'), findsOneWidget);
    expect(find.byKey(const ValueKey('admin-navigation-rail')), findsNothing);
    expect(find.byKey(const ValueKey('admin-section-dashboard')), findsNothing);
  });

  testWidgets('desktop navigation loads every admin section', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpAdminRoute(tester, admin, AppRoutes.adminDashboard);

    expect(find.byKey(const ValueKey('admin-navigation-rail')), findsOneWidget);
    for (final section in AdminSection.values.skip(1)) {
      await tester.tap(find.byIcon(section.icon));
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey('admin-section-${section.name}')),
        findsOneWidget,
      );
      expect(appRouter.state.uri.path, section.path);
    }
  });

  testWidgets('compact layout exposes admin navigation in a drawer', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(600, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpAdminRoute(tester, admin, AppRoutes.adminDashboard);

    expect(find.byKey(const ValueKey('admin-navigation-rail')), findsNothing);
    await tester.tap(find.byType(DrawerButton));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('admin-navigation-drawer')),
      findsOneWidget,
    );
  });
}

Future<void> _pumpAdminRoute(
  WidgetTester tester,
  AppUserProfile user,
  String route,
) async {
  appRouter.go(route);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authenticationRepositoryProvider.overrideWithValue(
          MockAuthenticationRepository(initialUser: user),
        ),
      ],
      child: const LinkoApp(),
    ),
  );
  await tester.pumpAndSettle();
}
