import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:linko/app/app.dart';
import 'package:linko/app/router.dart';
import 'package:linko/core/backend/backend_config.dart';
import 'package:linko/core/backend/backend_providers.dart';
import 'package:linko/core/backend/backend_repository_factory.dart';
import 'package:linko/core/backend/data/supabase_backend_repositories.dart';
import 'package:linko/core/backend/repositories/professionals_repository.dart';
import 'package:linko/features/home/presentation/data/placeholder_professionals.dart';
import 'package:linko/features/home/presentation/models/professional_profile_data.dart';
import 'package:linko/features/home/presentation/professional_profile_route.dart';
import 'package:linko/features/requests/domain/models/app_user.dart';
import 'package:linko/features/requests/domain/models/professional_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('Supabase lookup by ID maps the persisted professional', () async {
    late http.Request captured;
    final client = SupabaseClient(
      _supabaseConfig.supabaseUrl,
      _supabaseConfig.supabaseAnonKey,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode([
            {
              'id': _profile.id,
              'display_name': _profile.user.name,
              'profession': _profile.profession,
              'rating': _profile.rating,
              'review_count': _profile.reviewCount,
              'location': _profile.location,
            },
          ]),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
    addTearDown(client.dispose);

    final result = await SupabaseProfessionalsRepository(
      client,
    ).getProfessionalById(_profile.id);

    expect(captured.url.path, '/rest/v1/rpc/list_available_professionals');
    expect(result?.id, _profile.id);
    expect(result?.user.name, 'Perfil Supabase real');
    expect(result?.rating, 4.6);
  });

  test(
    'Supabase lookup never substitutes a placeholder when ID is absent',
    () async {
      final client = SupabaseClient(
        _supabaseConfig.supabaseUrl,
        _supabaseConfig.supabaseAnonKey,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient(
          (request) async => http.Response(
            '[]',
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          ),
        ),
      );
      addTearDown(client.dispose);

      final result = await SupabaseProfessionalsRepository(
        client,
      ).getProfessionalById(placeholderProfessionals.first.id);

      expect(result, isNull);
    },
  );

  testWidgets('direct profile route loads from the repository using only ID', (
    tester,
  ) async {
    final completer = Completer<ProfessionalProfile?>();
    final repository = _ProfessionalsRepository(
      onLookup: (_) => completer.future,
    );
    await _pumpRoute(tester, repository: repository, settle: false);

    expect(
      find.byKey(const ValueKey('professional-profile-loading')),
      findsOneWidget,
    );

    completer.complete(_profile);
    await _pumpFrames(tester);

    expect(repository.requestedIds, [_profile.id]);
    expect(find.text('Perfil Supabase real'), findsOneWidget);
    expect(find.text('4.6 (12 reseñas)'), findsOneWidget);
    expect(find.text('Acerca de'), findsOneWidget);
    expect(
      find.text('Este profesional aún no ha agregado una biografía.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Profesional con experiencia en instalaciones'),
      findsNothing,
    );
  });

  testWidgets(
    'navigation state is used without requiring a repository lookup',
    (tester) async {
      final repository = _ProfessionalsRepository(
        onLookup: (_) => throw StateError('No debe consultar'),
      );
      await _pumpRoute(
        tester,
        repository: repository,
        initial: placeholderProfessionals.first,
        mode: BackendMode.mock,
        professionalId: placeholderProfessionals.first.id,
      );

      expect(find.text('Carlos Rodríguez'), findsOneWidget);
      expect(find.text('Acerca de'), findsOneWidget);
      expect(repository.requestedIds, isEmpty);
    },
  );

  testWidgets('Supabase mode never trusts mock navigation state', (
    tester,
  ) async {
    final repository = _ProfessionalsRepository(
      onLookup: (_) async => _profile,
    );
    await _pumpRoute(
      tester,
      repository: repository,
      initial: placeholderProfessionals.first,
    );

    expect(repository.requestedIds, [_profile.id]);
    expect(find.text('Perfil Supabase real'), findsOneWidget);
    expect(find.text('Carlos Rodríguez'), findsNothing);
  });

  testWidgets('invalid professional ID shows a controlled Spanish state', (
    tester,
  ) async {
    await _pumpRoute(
      tester,
      repository: _ProfessionalsRepository(onLookup: (_) async => null),
      professionalId: '00000000-0000-0000-0000-000000000000',
    );

    expect(
      find.byKey(const ValueKey('professional-profile-not-found')),
      findsOneWidget,
    );
    expect(
      find.text('No encontramos este perfil profesional.'),
      findsOneWidget,
    );
  });

  testWidgets('repository failure shows a controlled Spanish error', (
    tester,
  ) async {
    await _pumpRoute(
      tester,
      repository: _ProfessionalsRepository(
        onLookup: (_) async => throw StateError('red no disponible'),
      ),
    );

    expect(
      find.byKey(const ValueKey('professional-profile-error')),
      findsOneWidget,
    );
    expect(
      find.text('No pudimos cargar el perfil profesional. Intenta nuevamente.'),
      findsOneWidget,
    );
  });

  testWidgets('mock direct lookup remains deterministic', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          backendConfigProvider.overrideWithValue(
            const BackendConfig(mode: BackendMode.mock),
          ),
        ],
        child: MaterialApp(
          home: ProfessionalProfileRoute(
            professionalId: placeholderProfessionals.first.id,
            onRequestService: (_) {},
          ),
        ),
      ),
    );
    await _pumpFrames(tester);

    expect(find.text('Carlos Rodríguez'), findsOneWidget);
    expect(find.text('Acerca de'), findsOneWidget);
  });

  testWidgets('GoRouter reconstructs a direct profile route from its ID', (
    tester,
  ) async {
    appRouter.go('/professional/${placeholderProfessionals.first.id}');
    await tester.pumpWidget(const ProviderScope(child: LinkoApp()));
    await tester.pumpAndSettle();

    expect(find.text('Perfil profesional'), findsOneWidget);
    expect(find.text('Carlos Rodríguez'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('professional-profile-not-found')),
      findsNothing,
    );
  });
}

Future<void> _pumpRoute(
  WidgetTester tester, {
  required ProfessionalsRepository repository,
  BackendMode mode = BackendMode.supabase,
  String professionalId = '11111111-1111-1111-1111-111111111111',
  ProfessionalProfileData? initial,
  bool settle = true,
}) async {
  final base = const BackendRepositoryFactory().create(
    config: const BackendConfig(mode: BackendMode.mock),
  );
  final repositories = BackendRepositories(
    mode: mode,
    authentication: base.authentication,
    professionals: repository,
    profile: base.profile,
    serviceRequests: base.serviceRequests,
    conversations: base.conversations,
    quotations: base.quotations,
    ratings: base.ratings,
    reports: base.reports,
    mvpCompatibilityRequests: base.mvpCompatibilityRequests,
    professionalAvailability: base.professionalAvailability,
    accountStatuses: base.accountStatuses,
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        backendRepositoriesProvider.overrideWithValue(repositories),
        professionalsRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        home: ProfessionalProfileRoute(
          professionalId: professionalId,
          initialProfessional: initial,
          onRequestService: (_) {},
        ),
      ),
    ),
  );
  if (settle) {
    await _pumpFrames(tester);
  } else {
    await tester.pump();
  }
}

Future<void> _pumpFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1));
  await tester.pump(const Duration(milliseconds: 1));
}

const _supabaseConfig = BackendConfig(
  mode: BackendMode.supabase,
  supabaseUrl: 'https://linko-profile-test.supabase.co',
  supabaseAnonKey: 'public-test-key',
  authRedirectUrl: 'io.supabase.linko://login-callback/',
);

const _profile = ProfessionalProfile(
  id: '11111111-1111-1111-1111-111111111111',
  user: AppUser(
    id: '11111111-1111-1111-1111-111111111111',
    name: 'Perfil Supabase real',
  ),
  profession: 'Electricidad',
  rating: 4.6,
  reviewCount: 12,
  location: 'San José',
  isVerified: true,
);

class _ProfessionalsRepository implements ProfessionalsRepository {
  _ProfessionalsRepository({required this.onLookup});

  final Future<ProfessionalProfile?> Function(String id) onLookup;
  final List<String> requestedIds = [];

  @override
  Future<ProfessionalProfile?> getProfessionalById(String professionalId) {
    requestedIds.add(professionalId);
    return onLookup(professionalId);
  }

  @override
  Future<ProfessionalProfile?> getOwnProfessionalProfile() async => null;

  @override
  Future<void> updateOwnProfessionalProfile(
    ProfessionalProfileUpdate update,
  ) async {}

  @override
  Future<List<ProfessionalProfile>> getProfessionals() async => const [];

  @override
  Stream<List<ProfessionalProfile>> watchProfessionals() =>
      const Stream.empty();
}
