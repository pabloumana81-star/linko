import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linko/app/app_mode.dart';
import 'package:linko/core/backend/backend_providers.dart';
import 'package:linko/core/backend/data/mock_backend_repositories.dart';
import 'package:linko/features/auth/domain/models/app_user_profile.dart';
import 'package:linko_admin/app/admin_app.dart';
import 'package:linko_admin/app/admin_router.dart';
import 'package:linko_admin/features/admin/presentation/admin_professionals_providers.dart';

void main() {
  testWidgets('admin browser authorization, navigation and shared change', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final router = createAdminRouter();
    addTearDown(router.dispose);
    final admin = AppUserProfile(
      id: 'admin-browser',
      displayName: 'Admin Browser',
      email: 'admin-browser@linko.test',
      avatarUrl: null,
      activeMode: AppMode.customer,
      role: UserRole.admin,
      createdAt: DateTime.utc(2026),
    );
    final container = ProviderContainer(
      overrides: [
        authenticationRepositoryProvider.overrideWithValue(
          MockAuthenticationRepository(initialUser: admin),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: LinkoAdminApp(router: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('admin-section-dashboard')),
      findsOneWidget,
    );

    final rail = find.byKey(const ValueKey('admin-navigation-rail'));
    await tester.tap(
      find.descendant(of: rail, matching: find.byIcon(Icons.people_outline)),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('admin-section-users')), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: rail,
        matching: find.byIcon(Icons.engineering_outlined),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('admin-section-professionals')),
      findsOneWidget,
    );

    final mainRepository = container.read(professionalsRepositoryProvider);
    await container
        .read(adminProfessionalActionsProvider)
        .suspend('professional-carlos');
    expect(
      (await mainRepository.getProfessionals()).any(
        (professional) => professional.user.id == 'professional-carlos',
      ),
      isFalse,
    );
  });

  testWidgets('non-admin is blocked in the browser app', (tester) async {
    final router = createAdminRouter();
    addTearDown(router.dispose);
    final user = AppUserProfile(
      id: 'browser-user',
      displayName: 'Usuario Browser',
      email: 'browser-user@linko.test',
      avatarUrl: null,
      activeMode: AppMode.customer,
      createdAt: DateTime.utc(2026),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authenticationRepositoryProvider.overrideWithValue(
            MockAuthenticationRepository(initialUser: user),
          ),
        ],
        child: LinkoAdminApp(router: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Acceso restringido'), findsOneWidget);
  });
}
