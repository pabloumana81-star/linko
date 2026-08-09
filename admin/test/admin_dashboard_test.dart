import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linko_admin/app/admin_app.dart';
import 'package:linko/app/app_mode.dart';
import 'package:linko_admin/app/admin_router.dart';
import 'package:linko/core/backend/backend_config.dart';
import 'package:linko/core/backend/backend_providers.dart';
import 'package:linko/core/backend/data/mock_backend_repositories.dart';
import 'package:linko_admin/features/admin/data/mock_admin_dashboard_repository.dart';
import 'package:linko/features/admin/data/supabase_admin_dashboard_repository.dart';
import 'package:linko/features/admin/domain/admin_dashboard.dart';
import 'package:linko/features/admin/domain/admin_dashboard_repository.dart';
import 'package:linko_admin/features/admin/presentation/admin_dashboard_providers.dart';
import 'package:linko/features/auth/domain/models/app_user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('dashboard metrics render repository values', (tester) async {
    await _pumpDashboard(tester, _DashboardRepository.success(_snapshot(12)));

    _expectMetric(tester, 'Total de usuarios', '12');
    _expectMetric(tester, 'Total de profesionales', '3');
    _expectMetric(tester, 'Solicitudes activas', '5');
    _expectMetric(tester, 'Trabajos completados', '4');
    _expectMetric(tester, 'Solicitudes canceladas', '2');
    _expectMetric(tester, 'Calificación promedio', '4.6');
    expect(find.text('Solicitud creada recientemente'), findsOneWidget);
  });

  testWidgets('date filters request and render the selected range', (
    tester,
  ) async {
    final repository = _DashboardRepository.byRange();
    await _pumpDashboard(tester, repository);
    _expectMetric(tester, 'Total de usuarios', '7');

    await tester.tap(find.text('Hoy'));
    await tester.pumpAndSettle();
    _expectMetric(tester, 'Total de usuarios', '1');

    await tester.tap(find.text('Últimos 30 días'));
    await tester.pumpAndSettle();
    _expectMetric(tester, 'Total de usuarios', '30');
    expect(repository.ranges, [
      AdminDashboardRange.last7Days,
      AdminDashboardRange.today,
      AdminDashboardRange.last30Days,
    ]);
  });

  testWidgets('dashboard displays a loading state', (tester) async {
    final pending = Completer<AdminDashboardSnapshot>();
    await _pumpDashboard(
      tester,
      _DashboardRepository((_) => pending.future),
      settle: false,
    );

    expect(
      find.byKey(const ValueKey('admin-dashboard-loading')),
      findsOneWidget,
    );
  });

  testWidgets('dashboard displays an empty state', (tester) async {
    await _pumpDashboard(
      tester,
      _DashboardRepository.success(
        const AdminDashboardSnapshot(
          metrics: AdminDashboardMetrics(
            totalUsers: 0,
            totalProfessionals: 0,
            activeRequests: 0,
            completedJobs: 0,
            cancelledRequests: 0,
            averageRating: 0,
          ),
          activities: [],
        ),
      ),
    );

    expect(find.text('No hay datos para este período.'), findsOneWidget);
  });

  testWidgets('dashboard displays a controlled error state', (tester) async {
    await _pumpDashboard(
      tester,
      _DashboardRepository((_) => Future.error(StateError('fallo'))),
    );

    expect(find.text('No pudimos cargar el dashboard.'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  test('repository selection preserves mock and Supabase modes', () {
    final mockContainer = ProviderContainer();
    addTearDown(mockContainer.dispose);
    expect(
      mockContainer.read(adminDashboardRepositoryProvider),
      isA<MockAdminDashboardRepository>(),
    );

    final client = SupabaseClient('https://example.supabase.co', 'anon-key');
    final supabaseContainer = ProviderContainer(
      overrides: [
        backendConfigProvider.overrideWithValue(
          const BackendConfig(
            mode: BackendMode.supabase,
            supabaseUrl: 'https://example.supabase.co',
            supabaseAnonKey: 'anon-key',
            authRedirectUrl: 'io.supabase.linko://login-callback/',
          ),
        ),
        supabaseClientProvider.overrideWithValue(client),
      ],
    );
    addTearDown(supabaseContainer.dispose);
    addTearDown(client.dispose);
    expect(
      supabaseContainer.read(adminDashboardRepositoryProvider),
      isA<SupabaseAdminDashboardRepository>(),
    );
  });
}

final _admin = AppUserProfile(
  id: 'dashboard-admin',
  displayName: 'Admin LinkO',
  email: 'admin@linko.test',
  avatarUrl: null,
  activeMode: AppMode.customer,
  role: UserRole.admin,
  createdAt: DateTime.utc(2026),
);

Future<void> _pumpDashboard(
  WidgetTester tester,
  AdminDashboardRepository repository, {
  bool settle = true,
}) async {
  adminRouter.go(AdminRoutes.dashboard);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authenticationRepositoryProvider.overrideWithValue(
          MockAuthenticationRepository(initialUser: _admin),
        ),
        adminDashboardRepositoryProvider.overrideWithValue(repository),
      ],
      child: const LinkoAdminApp(),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump();
  }
}

void _expectMetric(WidgetTester tester, String label, String value) {
  final finder = find.byKey(ValueKey('admin-metric-$label'));
  expect(finder, findsOneWidget);
  expect(tester.widget<Text>(finder).data, value);
}

AdminDashboardSnapshot _snapshot(int users) => AdminDashboardSnapshot(
  metrics: AdminDashboardMetrics(
    totalUsers: users,
    totalProfessionals: 3,
    activeRequests: 5,
    completedJobs: 4,
    cancelledRequests: 2,
    averageRating: 4.6,
  ),
  activities: [
    AdminActivity(
      id: 'activity-1',
      type: AdminActivityType.requestCreated,
      title: 'Solicitud creada recientemente',
      timestamp: DateTime.utc(2026, 8, 3),
    ),
  ],
);

class _DashboardRepository implements AdminDashboardRepository {
  _DashboardRepository(this._loader);

  factory _DashboardRepository.success(AdminDashboardSnapshot snapshot) =>
      _DashboardRepository((_) async => snapshot);

  factory _DashboardRepository.byRange() => _DashboardRepository(
    (range) async => _snapshot(switch (range) {
      AdminDashboardRange.today => 1,
      AdminDashboardRange.last7Days => 7,
      AdminDashboardRange.last30Days => 30,
    }),
  );

  final Future<AdminDashboardSnapshot> Function(AdminDashboardRange) _loader;
  final ranges = <AdminDashboardRange>[];

  @override
  Future<AdminDashboardSnapshot> loadDashboard(AdminDashboardRange range) {
    ranges.add(range);
    return _loader(range);
  }
}
