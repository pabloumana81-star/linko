import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko/app/app.dart';
import 'package:linko/core/backend/backend_config.dart';
import 'package:linko/core/backend/backend_failure_app.dart';
import 'package:linko/core/backend/backend_initializer.dart';
import 'package:linko/core/backend/backend_providers.dart';
import 'package:linko/core/diagnostics/diagnostics_service.dart';
import 'package:linko/core/diagnostics/global_error_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final diagnostics = DiagnosticsService();
  GlobalErrorHandler(diagnostics).install();
  await runZonedGuarded(
    () async {
      late final BackendConfig config;
      try {
        config = BackendConfig.fromEnvironment();
      } catch (error, stackTrace) {
        diagnostics.unexpectedError(
          error,
          stackTrace,
          context: 'backend_configuration',
        );
        runApp(BackendFailureApp(error: error));
        return;
      }
      final initialization = await BackendInitializer().initialize(config);
      if (!initialization.isReady) {
        diagnostics.backendStartup(
          backendMode: config.mode.name,
          hasSupabaseUrl: config.supabaseUrl.trim().isNotEmpty,
          hasSupabaseAnonKey: config.supabaseAnonKey.trim().isNotEmpty,
          repositoryImplementation: 'none',
        );
        diagnostics.unexpectedError(
          initialization.error!,
          initialization.stackTrace ?? StackTrace.current,
          context: 'backend_initialization',
        );
        runApp(BackendFailureApp(error: initialization.error));
        return;
      }
      diagnostics.backendStartup(
        backendMode: config.mode.name,
        hasSupabaseUrl: config.supabaseUrl.trim().isNotEmpty,
        hasSupabaseAnonKey: config.supabaseAnonKey.trim().isNotEmpty,
        repositoryImplementation: config.mode == BackendMode.supabase
            ? 'Supabase'
            : 'Mock',
      );
      runApp(
        ProviderScope(
          overrides: [
            diagnosticsServiceProvider.overrideWithValue(diagnostics),
            backendConfigProvider.overrideWithValue(config),
            backendInitializationProvider.overrideWithValue(initialization),
            if (config.mode == BackendMode.supabase)
              supabaseClientProvider.overrideWithValue(
                Supabase.instance.client,
              ),
          ],
          child: const LinkoApp(),
        ),
      );
    },
    (error, stackTrace) {
      diagnostics.unexpectedError(
        error,
        stackTrace,
        context: 'root_async_zone',
      );
    },
  );
}
