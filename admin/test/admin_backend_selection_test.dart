import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:linko/core/backend/backend_config.dart';
import 'package:linko/core/backend/backend_providers.dart';
import 'package:linko/core/backend/data/mock_backend_repositories.dart';
import 'package:linko/app/app_mode.dart';
import 'package:linko/features/auth/domain/models/app_user_profile.dart';
import 'package:linko_admin/app/admin_router.dart';
import 'package:linko_admin/app/admin_app.dart';
import 'package:linko_admin/features/admin/data/mock_admin_dashboard_repository.dart';
import 'package:linko_admin/features/admin/data/mock_admin_professionals_repository.dart';
import 'package:linko_admin/features/admin/data/mock_admin_reports_repository.dart';
import 'package:linko_admin/features/admin/data/mock_admin_requests_repository.dart';
import 'package:linko_admin/features/admin/data/mock_admin_users_repository.dart';
import 'package:linko/features/admin/data/supabase_admin_dashboard_repository.dart';
import 'package:linko/features/admin/data/supabase_admin_professionals_repository.dart';
import 'package:linko_admin/features/admin/data/supabase_admin_reports_repository.dart';
import 'package:linko/features/admin/data/supabase_admin_requests_repository.dart';
import 'package:linko/features/admin/data/supabase_admin_users_repository.dart';
import 'package:linko_admin/features/admin/presentation/admin_dashboard_providers.dart';
import 'package:linko_admin/features/admin/presentation/admin_professionals_providers.dart';
import 'package:linko_admin/features/admin/presentation/admin_reports_providers.dart';
import 'package:linko_admin/features/admin/presentation/admin_requests_providers.dart';
import 'package:linko_admin/features/admin/presentation/admin_users_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('mock mode selects mock repositories for every admin data module', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(adminDashboardRepositoryProvider),
      isA<MockAdminDashboardRepository>(),
    );
    expect(
      container.read(adminUsersRepositoryProvider),
      isA<MockAdminUsersRepository>(),
    );
    expect(
      container.read(adminProfessionalsRepositoryProvider),
      isA<MockAdminProfessionalsRepository>(),
    );
    expect(
      container.read(adminRequestsRepositoryProvider),
      isA<MockAdminRequestsRepository>(),
    );
    expect(
      container.read(adminReportsRepositoryProvider),
      isA<MockAdminReportsRepository>(),
    );
  });

  test('Supabase mode selects no mock repository in any admin module', () {
    final client = SupabaseClient('https://example.supabase.co', 'anon-key');
    final container = ProviderContainer(
      overrides: [
        backendConfigProvider.overrideWithValue(_supabaseConfig),
        supabaseClientProvider.overrideWithValue(client),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(client.dispose);

    expect(
      container.read(adminDashboardRepositoryProvider),
      isA<SupabaseAdminDashboardRepository>(),
    );
    expect(
      container.read(adminUsersRepositoryProvider),
      isA<SupabaseAdminUsersRepository>(),
    );
    expect(
      container.read(adminProfessionalsRepositoryProvider),
      isA<SupabaseAdminProfessionalsRepository>(),
    );
    expect(
      container.read(adminRequestsRepositoryProvider),
      isA<SupabaseAdminRequestsRepository>(),
    );
    expect(
      container.read(adminReportsRepositoryProvider),
      isA<SupabaseAdminReportsRepository>(),
    );
  });

  testWidgets('debug badge displays the selected backend', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Contenido')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(child: LinkoAdminApp(router: router)),
    );
    expect(find.text('Backend\nMOCK'), findsOneWidget);

    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [backendConfigProvider.overrideWithValue(_supabaseConfig)],
        child: LinkoAdminApp(router: router),
      ),
    );
    expect(find.text('Backend\nSUPABASE'), findsOneWidget);
  });

  testWidgets('debug diagnostics reports effective repositories and session', (
    tester,
  ) async {
    adminRouter.go(AdminRoutes.dashboard);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authenticationRepositoryProvider.overrideWithValue(
            MockAuthenticationRepository(initialUser: _admin),
          ),
        ],
        child: const LinkoAdminApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('admin-backend-indicator')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('admin-diagnostics-page')),
      findsOneWidget,
    );
    expect(find.text('Modo de backend'), findsOneWidget);
    expect(find.text('URL de Supabase'), findsOneWidget);
    expect(find.text('MockAdminDashboardRepository'), findsOneWidget);
    expect(find.text('Realtime conectado'), findsOneWidget);
    expect(find.text('Usuario autenticado'), findsOneWidget);
    expect(find.text('Rol actual'), findsOneWidget);
    expect(find.text('Base de datos accesible'), findsOneWidget);
    expect(find.text('Administrador'), findsOneWidget);
  });
}

const _supabaseConfig = BackendConfig(
  mode: BackendMode.supabase,
  supabaseUrl: 'https://example.supabase.co',
  supabaseAnonKey: 'anon-key',
);

final _admin = AppUserProfile(
  id: 'admin-user',
  displayName: 'Administración LinkO',
  email: 'admin@linko.test',
  avatarUrl: null,
  activeMode: AppMode.customer,
  role: UserRole.admin,
  createdAt: DateTime.utc(2026),
);
