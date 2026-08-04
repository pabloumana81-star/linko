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
  WidgetsFlutterBinding.ensureInitialized();
  final diagnostics = DiagnosticsService();
  GlobalErrorHandler(diagnostics).install();
  await runZonedGuarded(
    () async {
      final config = BackendConfig.fromEnvironment();
      final initialization = await BackendInitializer().initialize(config);
      if (!initialization.isReady) {
        diagnostics.unexpectedError(
          initialization.error!,
          initialization.stackTrace ?? StackTrace.current,
          context: 'admin_backend_initialization',
        );
        runApp(const _AdminStartupFailureApp());
        return;
      }
      runApp(
        ProviderScope(
          overrides: [
            diagnosticsServiceProvider.overrideWithValue(diagnostics),
            backendConfigProvider.overrideWithValue(config),
            backendInitializationProvider.overrideWithValue(initialization),
            if (config.mode == BackendMode.mock)
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
            if (config.mode == BackendMode.supabase)
              supabaseClientProvider.overrideWithValue(
                Supabase.instance.client,
              ),
          ],
          child: const LinkoAdminApp(),
        ),
      );
    },
    (error, stackTrace) {
      diagnostics.unexpectedError(
        error,
        stackTrace,
        context: 'admin_root_async_zone',
      );
    },
  );
}

class _AdminStartupFailureApp extends StatelessWidget {
  const _AdminStartupFailureApp();

  @override
  Widget build(BuildContext context) => const MaterialApp(
    home: Scaffold(
      body: Center(
        child: Text('No fue posible iniciar el panel administrativo.'),
      ),
    ),
  );
}
