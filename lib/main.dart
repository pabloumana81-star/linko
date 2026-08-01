import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko/app/app.dart';
import 'package:linko/core/backend/backend_config.dart';
import 'package:linko/core/backend/backend_failure_app.dart';
import 'package:linko/core/backend/backend_initializer.dart';
import 'package:linko/core/backend/backend_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = BackendConfig.fromEnvironment();
  final initialization = await BackendInitializer().initialize(config);
  if (!initialization.isReady) {
    runApp(const BackendFailureApp());
    return;
  }
  runApp(
    ProviderScope(
      overrides: [
        backendConfigProvider.overrideWithValue(config),
        backendInitializationProvider.overrideWithValue(initialization),
        if (config.mode == BackendMode.supabase)
          supabaseClientProvider.overrideWithValue(Supabase.instance.client),
      ],
      child: const LinkoApp(),
    ),
  );
}
