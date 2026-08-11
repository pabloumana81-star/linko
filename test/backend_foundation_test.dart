import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linko/core/backend/backend_config.dart';
import 'package:linko/core/backend/backend_initializer.dart';
import 'package:linko/core/backend/backend_providers.dart';
import 'package:linko/core/backend/backend_repository_factory.dart';
import 'package:linko/core/backend/data/mock_backend_repositories.dart';
import 'package:linko/core/backend/data/supabase_backend_repositories.dart';
import 'package:linko/features/requests/presentation/providers/request_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'mock mode selects adapters sharing the current MVP repository',
    () async {
      final container = ProviderContainer(
        overrides: [
          backendConfigProvider.overrideWithValue(
            const BackendConfig(mode: BackendMode.mock),
          ),
        ],
      );
      addTearDown(container.dispose);

      final repositories = container.read(backendRepositoriesProvider);
      final legacy = container.read(requestRepositoryProvider);

      expect(repositories.mode, BackendMode.mock);
      expect(
        repositories.serviceRequests,
        isA<MockServiceRequestsRepository>(),
      );
      expect(repositories.conversations, isA<MockConversationsRepository>());
      expect(repositories.mvpCompatibilityRequests, same(legacy));
      expect(
        await repositories.serviceRequests.getCustomerRequests(
          currentCustomerId,
        ),
        hasLength(legacy.getCustomerRequests(currentCustomerId).length),
      );
    },
  );

  test('Supabase mode selects backend repositories without a network call', () {
    const config = BackendConfig(
      mode: BackendMode.supabase,
      supabaseUrl: 'https://linko-test.supabase.co',
      supabaseAnonKey: 'public-test-anon-key',
      authRedirectUrl: 'io.supabase.linko://login-callback/',
    );
    final client = SupabaseClient(config.supabaseUrl, config.supabaseAnonKey);

    final repositories = const BackendRepositoryFactory().create(
      config: config,
      supabaseClient: client,
    );

    expect(repositories.mode, BackendMode.supabase);
    expect(
      repositories.serviceRequests,
      isA<SupabaseServiceRequestsRepository>(),
    );
    expect(
      repositories.authentication,
      isA<SupabaseAuthenticationRepository>(),
    );
    expect(repositories.profile, isA<ProfileRepositorySupabase>());
    expect(repositories.ratings, isA<SupabaseRatingsRepository>());
  });

  test('mock initialization skips Supabase completely', () async {
    var calls = 0;
    final result = await BackendInitializer(
      initializeSupabase: (url, key) async {
        calls++;
      },
    ).initialize(const BackendConfig(mode: BackendMode.mock));

    expect(result.isReady, isTrue);
    expect(result.error, isNull);
    expect(calls, 0);
  });

  test('initialization exposes Supabase failures without throwing', () async {
    final failure = StateError('Backend unavailable');
    final result =
        await BackendInitializer(
          initializeSupabase: (url, key) async => throw failure,
        ).initialize(
          const BackendConfig(
            mode: BackendMode.supabase,
            supabaseUrl: 'https://linko-test.supabase.co',
            supabaseAnonKey: 'public-test-anon-key',
            authRedirectUrl: 'io.supabase.linko://login-callback/',
          ),
        );

    expect(result.isReady, isFalse);
    expect(result.error, same(failure));
  });

  test('missing Supabase credentials fail before SDK initialization', () async {
    var initialized = false;
    final result = await BackendInitializer(
      initializeSupabase: (url, key) async {
        initialized = true;
      },
    ).initialize(const BackendConfig(mode: BackendMode.supabase));

    expect(result.isReady, isFalse);
    expect(result.error, isA<BackendConfigurationException>());
    expect(initialized, isFalse);
  });

  test('missing Supabase URL never falls back to mock', () async {
    final result =
        await BackendInitializer(
          initializeSupabase: (_, _) async =>
              fail('No debe inicializar Supabase'),
        ).initialize(
          const BackendConfig(
            mode: BackendMode.supabase,
            supabaseAnonKey: 'public-test-anon-key',
          ),
        );

    expect(result.isReady, isFalse);
    expect(result.config.mode, BackendMode.supabase);
    expect(result.error, isA<BackendConfigurationException>());
  });

  test('missing Supabase anon key never falls back to mock', () async {
    final result =
        await BackendInitializer(
          initializeSupabase: (_, _) async =>
              fail('No debe inicializar Supabase'),
        ).initialize(
          const BackendConfig(
            mode: BackendMode.supabase,
            supabaseUrl: 'https://linko-test.supabase.co',
          ),
        );

    expect(result.isReady, isFalse);
    expect(result.config.mode, BackendMode.supabase);
    expect(result.error, isA<BackendConfigurationException>());
  });

  test('invalid BACKEND_MODE is rejected instead of selecting mock', () {
    expect(
      () => BackendConfig.fromValues(modeValue: 'invalid'),
      throwsA(isA<BackendConfigurationException>()),
    );
  });

  test('Supabase request providers never substitute a mock actor', () async {
    const config = BackendConfig(
      mode: BackendMode.supabase,
      supabaseUrl: 'https://linko-test.supabase.co',
      supabaseAnonKey: 'public-test-anon-key',
      authRedirectUrl: 'io.supabase.linko://login-callback/',
    );
    final client = SupabaseClient(config.supabaseUrl, config.supabaseAnonKey);
    final container = ProviderContainer(
      overrides: [
        backendConfigProvider.overrideWithValue(config),
        supabaseClientProvider.overrideWithValue(client),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(client.dispose);

    await expectLater(
      container.read(persistedCustomerRequestsProvider.future),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('iniciar sesión'),
        ),
      ),
    );
  });
}
