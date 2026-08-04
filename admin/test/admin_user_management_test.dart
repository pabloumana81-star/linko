import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linko_admin/app/admin_app.dart';
import 'package:linko/app/app_mode.dart';
import 'package:linko_admin/app/admin_router.dart';
import 'package:linko/core/backend/backend_config.dart';
import 'package:linko/core/backend/backend_providers.dart';
import 'package:linko/core/backend/data/mock_backend_repositories.dart';
import 'package:linko_admin/features/admin/data/mock_admin_users_repository.dart';
import 'package:linko_admin/features/admin/data/supabase_admin_users_repository.dart';
import 'package:linko_admin/features/admin/domain/admin_user.dart';
import 'package:linko_admin/features/admin/presentation/admin_users_providers.dart';
import 'package:linko/features/auth/domain/models/app_user_profile.dart';
import 'package:linko/features/requests/data/mock_request_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late MockAdminUsersRepository repository;

  setUp(() {
    repository = MockAdminUsersRepository(
      MockRequestRepository(),
      clock: () => DateTime.utc(2026, 8, 3, 12),
    );
  });

  test('search matches name, email, and user ID', () async {
    expect(
      await repository.listUsers(const AdminUserQuery(search: 'Ana Martínez')),
      hasLength(1),
    );
    expect(
      await repository.listUsers(
        const AdminUserQuery(search: 'customer-ana@mock.linko'),
      ),
      hasLength(1),
    );
    expect(
      await repository.listUsers(const AdminUserQuery(search: 'customer-ana')),
      hasLength(1),
    );
  });

  test('filters by status and every account type', () async {
    await repository.suspendUser('customer-ana');

    final suspended = await repository.listUsers(
      const AdminUserQuery(status: AdminAccountStatus.suspended),
    );
    expect(suspended.map((user) => user.id), ['customer-ana']);
    expect(
      await repository.listUsers(
        const AdminUserQuery(status: AdminAccountStatus.active),
      ),
      isNotEmpty,
    );
    for (final type in AdminAccountType.values) {
      final users = await repository.listUsers(
        AdminUserQuery(accountType: type),
      );
      expect(
        users,
        isNotEmpty,
        reason: 'Faltan usuarios de tipo ${type.name}.',
      );
      expect(users.every((user) => user.accountType == type), isTrue);
    }
  });

  test('suspension and reactivation update account state', () async {
    await repository.suspendUser('customer-ana');
    expect(
      (await repository.getUser('customer-ana'))?.user.status,
      AdminAccountStatus.suspended,
    );

    await repository.reactivateUser('customer-ana');
    expect(
      (await repository.getUser('customer-ana'))?.user.status,
      AdminAccountStatus.active,
    );
  });

  test('every successful admin action is recorded in the audit log', () async {
    await repository.suspendUser('customer-ana');
    await repository.reactivateUser('customer-ana');
    await repository.resetOnboarding('customer-ana');

    final detail = await repository.getUser('customer-ana');
    expect(detail?.onboardingCompleted, isFalse);
    expect(detail?.history.map((entry) => entry.action), [
      AdminAuditAction.onboardingReset,
      AdminAuditAction.accountReactivated,
      AdminAuditAction.accountSuspended,
    ]);
    expect(
      detail?.history.every((entry) => entry.adminId == 'admin-user'),
      isTrue,
    );
  });

  testWidgets('user list searches and opens a complete detail screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpAdmin(tester, repository, AdminRoutes.users);

    await tester.enterText(
      find.byKey(const ValueKey('admin-user-search')),
      'customer-ana',
    );
    await tester.pumpAndSettle();
    expect(find.text('Ana Martínez'), findsOneWidget);
    await tester.tap(find.text('Ana Martínez'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('admin-user-detail')), findsOneWidget);
    expect(find.text('Solicitudes activas'), findsOneWidget);
    expect(find.text('Solicitudes completadas'), findsOneWidget);
    expect(find.text('Calificaciones'), findsOneWidget);
    expect(find.text('Reportes'), findsWidgets);
    expect(find.text('Historial de la cuenta'), findsOneWidget);
    expect(find.text('Eliminar usuario'), findsNothing);
  });

  testWidgets('non-admin cannot access user management or detail', (
    tester,
  ) async {
    final regularUser = AppUserProfile(
      id: 'regular-user',
      displayName: 'Usuario regular',
      email: 'regular@linko.test',
      avatarUrl: null,
      activeMode: AppMode.customer,
      createdAt: DateTime.utc(2026),
    );
    adminRouter.go('/users/customer-ana');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authenticationRepositoryProvider.overrideWithValue(
            MockAuthenticationRepository(initialUser: regularUser),
          ),
          adminUsersRepositoryProvider.overrideWithValue(repository),
        ],
        child: const LinkoAdminApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Acceso restringido'), findsOneWidget);
    expect(find.byKey(const ValueKey('admin-user-detail')), findsNothing);
  });

  test('repository selection preserves mock and Supabase modes', () {
    final mockContainer = ProviderContainer();
    addTearDown(mockContainer.dispose);
    expect(
      mockContainer.read(adminUsersRepositoryProvider),
      isA<MockAdminUsersRepository>(),
    );

    final client = SupabaseClient('https://example.supabase.co', 'anon-key');
    final supabaseContainer = ProviderContainer(
      overrides: [
        backendConfigProvider.overrideWithValue(
          const BackendConfig(
            mode: BackendMode.supabase,
            supabaseUrl: 'https://example.supabase.co',
            supabaseAnonKey: 'anon-key',
          ),
        ),
        supabaseClientProvider.overrideWithValue(client),
      ],
    );
    addTearDown(supabaseContainer.dispose);
    addTearDown(client.dispose);
    expect(
      supabaseContainer.read(adminUsersRepositoryProvider),
      isA<SupabaseAdminUsersRepository>(),
    );
  });
}

final _admin = AppUserProfile(
  id: 'admin-user',
  displayName: 'Administración LinkO',
  email: 'admin@linko.test',
  avatarUrl: null,
  activeMode: AppMode.customer,
  role: UserRole.admin,
  createdAt: DateTime.utc(2026),
);

Future<void> _pumpAdmin(
  WidgetTester tester,
  MockAdminUsersRepository repository,
  String route,
) async {
  adminRouter.go(route);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authenticationRepositoryProvider.overrideWithValue(
          MockAuthenticationRepository(initialUser: _admin),
        ),
        adminUsersRepositoryProvider.overrideWithValue(repository),
      ],
      child: const LinkoAdminApp(),
    ),
  );
  await tester.pumpAndSettle();
}
