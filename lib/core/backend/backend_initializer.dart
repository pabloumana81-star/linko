import 'package:linko/core/backend/backend_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef SupabaseInitialize = Future<void> Function(String url, String anonKey);

class BackendInitializationResult {
  const BackendInitializationResult._({required this.config, this.error});

  factory BackendInitializationResult.ready(BackendConfig config) =>
      BackendInitializationResult._(config: config);

  factory BackendInitializationResult.failure(
    BackendConfig config,
    Object error,
  ) => BackendInitializationResult._(config: config, error: error);

  final BackendConfig config;
  final Object? error;

  bool get isReady => error == null;
}

class BackendInitializer {
  BackendInitializer({SupabaseInitialize? initializeSupabase})
    : _initializeSupabase = initializeSupabase ?? _initialize;

  final SupabaseInitialize _initializeSupabase;

  Future<BackendInitializationResult> initialize(BackendConfig config) async {
    try {
      config.validate();
      if (config.mode == BackendMode.supabase) {
        await _initializeSupabase(config.supabaseUrl, config.supabaseAnonKey);
      }
      return BackendInitializationResult.ready(config);
    } catch (error) {
      return BackendInitializationResult.failure(config, error);
    }
  }

  static Future<void> _initialize(String url, String anonKey) async {
    await Supabase.initialize(url: url, publishableKey: anonKey);
  }
}
