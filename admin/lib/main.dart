import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko/core/backend/backend_config.dart';
import 'package:linko/core/backend/backend_initializer.dart';
import 'package:linko/core/backend/backend_providers.dart';
import 'package:linko/core/backend/data/mock_backend_repositories.dart';
import 'package:linko/core/diagnostics/diagnostics_service.dart';
import 'package:linko/core/diagnostics/global_error_handler.dart';
import 'package:linko/app/app_mode.dart';
import 'package:linko/features/auth/domain/models/app_user_profile.dart';
import 'package:linko_admin/app/admin_app.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  await runAdminInGuardedZone();
}

Future<void> runAdminInGuardedZone({
  void Function()? ensureInitialized,
  void Function(Widget)? appRunner,
  void Function(DiagnosticsService)? installErrorHandler,
  Future<Widget> Function(DiagnosticsService)? prepareRoot,
  DiagnosticsService? diagnostics,
}) async {
  final service = diagnostics ?? DiagnosticsService();
  final guarded = runZonedGuarded<Future<void>>(
    () async {
      (ensureInitialized ?? WidgetsFlutterBinding.ensureInitialized)();
      (installErrorHandler ??
          (diagnostics) => GlobalErrorHandler(diagnostics).install())(service);
      final root = await (prepareRoot ?? prepareAdminRoot)(service);
      (appRunner ?? runApp)(root);
    },
    (error, stackTrace) {
      service.unexpectedError(
        error,
        stackTrace,
        context: 'admin_root_async_zone',
      );
    },
  );
  await guarded;
}

Future<Widget> prepareAdminRoot(
  DiagnosticsService diagnostics, {
  BackendConfig? config,
  BackendInitializer? initializer,
  SupabaseClient? supabaseClient,
}) async {
  late final BackendConfig effectiveConfig;
  try {
    effectiveConfig = config ?? BackendConfig.fromEnvironment();
  } catch (error, stackTrace) {
    diagnostics.unexpectedError(
      error,
      stackTrace,
      context: 'admin_backend_configuration',
    );
    return AdminStartupFailureApp(error: error);
  }
  final initialization = await (initializer ?? BackendInitializer()).initialize(
    effectiveConfig,
  );
  if (!initialization.isReady) {
    diagnostics.backendStartup(
      backendMode: effectiveConfig.mode.name,
      hasSupabaseUrl: effectiveConfig.supabaseUrl.trim().isNotEmpty,
      hasSupabaseAnonKey: effectiveConfig.supabaseAnonKey.trim().isNotEmpty,
      repositoryImplementation: 'none',
    );
    diagnostics.unexpectedError(
      initialization.error!,
      initialization.stackTrace ?? StackTrace.current,
      context: 'admin_backend_initialization',
    );
    return AdminStartupFailureApp(error: initialization.error);
  }
  final client = effectiveConfig.mode == BackendMode.supabase
      ? supabaseClient ?? Supabase.instance.client
      : null;
  diagnostics.backendStartup(
    backendMode: effectiveConfig.mode.name,
    hasSupabaseUrl: effectiveConfig.supabaseUrl.trim().isNotEmpty,
    hasSupabaseAnonKey: effectiveConfig.supabaseAnonKey.trim().isNotEmpty,
    repositoryImplementation: effectiveConfig.mode == BackendMode.supabase
        ? 'SupabaseAdmin'
        : 'MockAdmin',
  );
  return ProviderScope(
    overrides: [
      diagnosticsServiceProvider.overrideWithValue(diagnostics),
      backendConfigProvider.overrideWithValue(effectiveConfig),
      backendInitializationProvider.overrideWithValue(initialization),
      if (effectiveConfig.mode == BackendMode.mock)
        authenticationRepositoryProvider.overrideWithValue(
          MockAuthenticationRepository(
            initialUser: AppUserProfile(
              id: 'admin-local',
              displayName: 'Administración local',
              email: 'admin@local.linko',
              avatarUrl: null,
              activeMode: AppMode.customer,
              role: UserRole.admin,
              createdAt: DateTime.utc(2026),
            ),
          ),
        ),
      if (client != null) supabaseClientProvider.overrideWithValue(client),
    ],
    child: const LinkoAdminApp(),
  );
}

class AdminStartupFailureApp extends StatelessWidget {
  const AdminStartupFailureApp({super.key, this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No fue posible iniciar el panel administrativo.'),
              if (error case BackendConfigurationException(:final message))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(message, textAlign: TextAlign.center),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
