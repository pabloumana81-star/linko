import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linko/app/app.dart';
import 'package:linko/app/app_mode.dart';
import 'package:linko/app/router.dart';
import 'package:linko/core/backend/backend_providers.dart';
import 'package:linko/core/backend/data/mock_backend_repositories.dart';
import 'package:linko/features/auth/domain/models/app_user_profile.dart';
import 'package:linko/features/auth/presentation/auth_controller.dart';

void main() {
  final restoredUser = AppUserProfile(
    id: 'authenticated-user',
    displayName: 'Ana LinkO',
    email: 'ana@linko.test',
    avatarUrl: null,
    activeMode: AppMode.customer,
    createdAt: DateTime.utc(2026),
  );

  test('guest access is represented centrally', () async {
    final container = ProviderContainer(
      overrides: [
        authenticationRepositoryProvider.overrideWithValue(
          MockAuthenticationRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(authControllerProvider.notifier).continueAsGuest();

    expect(container.read(authControllerProvider).status, AuthStatus.guest);
    expect(container.read(authControllerProvider).canAccessMvp, isTrue);
  });

  test(
    'Google architecture produces authenticated state in mock mode',
    () async {
      final container = ProviderContainer(
        overrides: [
          authenticationRepositoryProvider.overrideWithValue(
            MockAuthenticationRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authControllerProvider.notifier).signInWithGoogle();

      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.user?.email, 'google@mock.linko');
    },
  );

  test('restores an existing authenticated session', () async {
    final container = ProviderContainer(
      overrides: [
        authenticationRepositoryProvider.overrideWithValue(
          MockAuthenticationRepository(initialUser: restoredUser),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authControllerProvider.notifier).restoreSession();

    final state = container.read(authControllerProvider);
    expect(state.status, AuthStatus.authenticated);
    expect(state.user, same(restoredUser));
  });

  test('sign out clears an authenticated session', () async {
    final repository = MockAuthenticationRepository(initialUser: restoredUser);
    final container = ProviderContainer(
      overrides: [
        authenticationRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authControllerProvider.notifier).restoreSession();

    await container.read(authControllerProvider.notifier).signOut();

    expect(
      container.read(authControllerProvider).status,
      AuthStatus.unauthenticated,
    );
    expect(await repository.restoreSession(), isNull);
  });

  testWidgets('startup restores session and enters the active customer mode', (
    tester,
  ) async {
    appRouter.go(AppRoutes.splash);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authenticationRepositoryProvider.overrideWithValue(
            MockAuthenticationRepository(initialUser: restoredUser),
          ),
        ],
        child: const LinkoApp(),
      ),
    );

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('¿Qué servicio necesitas hoy?'), findsOneWidget);
    expect(find.text('Continuar como invitado'), findsNothing);
  });

  testWidgets('sign out returns to the authentication screen', (tester) async {
    appRouter.go(AppRoutes.customerModeProfile);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authenticationRepositoryProvider.overrideWithValue(
            MockAuthenticationRepository(initialUser: restoredUser),
          ),
        ],
        child: const LinkoApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Continuar como invitado'), findsOneWidget);
    expect(find.text('Recibir enlace de acceso'), findsOneWidget);
  });

  testWidgets('an expired session redirects a protected screen to access', (
    tester,
  ) async {
    final repository = MockAuthenticationRepository(initialUser: restoredUser);
    appRouter.go(AppRoutes.customerRequests);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authenticationRepositoryProvider.overrideWithValue(repository),
        ],
        child: const LinkoApp(),
      ),
    );
    await tester.pumpAndSettle();

    await repository.signOut();
    await tester.pumpAndSettle();

    expect(find.text('Continuar como invitado'), findsOneWidget);
  });

  testWidgets('a new authenticated account enters role onboarding', (
    tester,
  ) async {
    final pending = restoredUser.copyWith(onboardingCompleted: false);
    appRouter.go(AppRoutes.splash);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authenticationRepositoryProvider.overrideWithValue(
            MockAuthenticationRepository(initialUser: pending),
          ),
        ],
        child: const LinkoApp(),
      ),
    );

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('¿Cómo deseas usar LinkO?'), findsOneWidget);
  });
}
