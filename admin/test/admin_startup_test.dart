import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linko/core/backend/backend_config.dart';
import 'package:linko/core/backend/backend_initializer.dart';
import 'package:linko/core/diagnostics/diagnostics_service.dart';
import 'package:linko_admin/app/admin_router.dart';
import 'package:linko_admin/main.dart' as admin_main;
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('compiled BACKEND_MODE reaches the shared BackendConfig unchanged', () {
    const input = String.fromEnvironment('BACKEND_MODE');
    final config = BackendConfig.fromEnvironment();

    expect(input, isNotEmpty);
    expect(config.mode.name, input.trim().toLowerCase());
  });

  test(
    'binding initialization and runApp execute in the same guarded zone',
    () async {
      Zone? bindingZone;
      Zone? initializationZone;
      Zone? appZone;

      await admin_main.runAdminInGuardedZone(
        ensureInitialized: () => bindingZone = Zone.current,
        installErrorHandler: (_) {},
        prepareRoot: (_) async {
          initializationZone = Zone.current;
          return const SizedBox.shrink();
        },
        appRunner: (_) => appZone = Zone.current,
      );

      expect(bindingZone, isNotNull);
      expect(initializationZone, same(bindingZone));
      expect(appZone, same(bindingZone));
    },
  );

  testWidgets('Admin starts in mock mode', (tester) async {
    adminRouter.go(AdminRoutes.dashboard);
    final root = await admin_main.prepareAdminRoot(
      DiagnosticsService(),
      config: const BackendConfig(mode: BackendMode.mock),
    );

    await tester.pumpWidget(root);
    await tester.pumpAndSettle();

    expect(find.byType(admin_main.AdminStartupFailureApp), findsNothing);
    expect(find.text('Backend\nMOCK'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('admin-section-dashboard')),
      findsOneWidget,
    );
  });

  test('BACKEND_MODE=mock is parsed explicitly', () {
    final config = BackendConfig.fromValues(modeValue: 'mock');

    expect(config.mode, BackendMode.mock);
  });

  test('BACKEND_MODE=supabase is parsed explicitly', () {
    final config = BackendConfig.fromValues(
      modeValue: 'supabase',
      supabaseUrl: 'https://project.supabase.co',
      supabaseAnonKey: 'anon-key',
    );

    expect(config.mode, BackendMode.supabase);
  });

  test('missing BACKEND_MODE never falls back to mock', () {
    expect(
      () => BackendConfig.fromValues(modeValue: ''),
      throwsA(isA<BackendConfigurationException>()),
    );
  });

  test('invalid BACKEND_MODE never falls back to mock', () {
    expect(
      () => BackendConfig.fromValues(modeValue: 'staging'),
      throwsA(isA<BackendConfigurationException>()),
    );
  });

  test('Admin starts with a configured Supabase environment', () async {
    final client = SupabaseClient('https://project.supabase.co', 'anon-key');
    final initializer = BackendInitializer(initializeSupabase: (_, _) async {});
    final root = await admin_main.prepareAdminRoot(
      DiagnosticsService(),
      config: _supabaseConfig,
      initializer: initializer,
      supabaseClient: client,
    );

    expect(root, isNot(isA<admin_main.AdminStartupFailureApp>()));
    client.dispose();
  });

  testWidgets('invalid Supabase configuration shows a controlled error', (
    tester,
  ) async {
    final root = await admin_main.prepareAdminRoot(
      DiagnosticsService(),
      config: const BackendConfig(
        mode: BackendMode.supabase,
        supabaseUrl: 'dirección-inválida',
        supabaseAnonKey: '',
      ),
    );

    await tester.pumpWidget(root);

    expect(find.byType(admin_main.AdminStartupFailureApp), findsOneWidget);
    expect(
      find.text('No fue posible iniciar el panel administrativo.'),
      findsOneWidget,
    );
    expect(
      find.text('SUPABASE_URL debe ser una URL HTTPS válida.'),
      findsOneWidget,
    );
  });

  testWidgets('missing anon key shows an error without selecting mock', (
    tester,
  ) async {
    final root = await admin_main.prepareAdminRoot(
      DiagnosticsService(),
      config: const BackendConfig(
        mode: BackendMode.supabase,
        supabaseUrl: 'https://project.supabase.co',
      ),
    );

    await tester.pumpWidget(root);

    expect(find.byType(admin_main.AdminStartupFailureApp), findsOneWidget);
    expect(
      find.text('SUPABASE_ANON_KEY es obligatoria en modo Supabase.'),
      findsOneWidget,
    );
    expect(find.text('Backend\nMOCK'), findsNothing);
  });
}

const _supabaseConfig = BackendConfig(
  mode: BackendMode.supabase,
  supabaseUrl: 'https://project.supabase.co',
  supabaseAnonKey: 'anon-key',
);
