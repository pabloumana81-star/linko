import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linko/app/app.dart';
import 'package:linko/app/app_mode.dart';
import 'package:linko/app/router.dart';
import 'package:linko/core/backend/backend_providers.dart';
import 'package:linko/core/backend/data/mock_backend_repositories.dart';
import 'package:linko/core/backend/repositories/authentication_repository.dart';
import 'package:linko/features/auth/domain/models/app_user_profile.dart';
import 'package:linko/features/home/data/pending_hiring_intent_store.dart';
import 'package:linko/features/home/presentation/data/placeholder_professionals.dart';
import 'package:linko/features/home/presentation/models/pending_hiring_intent.dart';
import 'package:linko/features/home/presentation/providers/pending_hiring_intent_provider.dart';

void main() {
  testWidgets(
    'guest is gated before the form and Google resumes the exact intent',
    (tester) async {
      final store = MemoryPendingHiringIntentStore();
      final auth = MockAuthenticationRepository();
      await _pumpProfessional(tester, auth: auth, store: store);

      expect(find.text('Perfil profesional'), findsOneWidget);
      await tester.tap(find.text('Solicitar servicio'));
      await tester.pumpAndSettle();

      expect(
        find.text('Inicia sesión para solicitar el servicio'),
        findsOneWidget,
      );
      expect(find.text('¿Qué necesitas?'), findsNothing);
      expect(
        store.value,
        isA<PendingHiringIntent>()
            .having(
              (intent) => intent.professionalId,
              'professionalId',
              placeholderProfessionals.first.id,
            )
            .having(
              (intent) => intent.selectedService,
              'selectedService',
              'Instalación solar',
            ),
      );

      await tester.tap(find.byKey(const ValueKey('hiring-auth-google')));
      await tester.pumpAndSettle();

      expect(find.text('¿Qué necesitas?'), findsOneWidget);
      expect(find.text('Confirmar solicitud'), findsNothing);
      expect(
        appRouter.routeInformationProvider.value.uri.path,
        '/request-service/${placeholderProfessionals.first.id}',
      );
      expect(
        appRouter.routeInformationProvider.value.uri.queryParameters['service'],
        'Instalación solar',
      );
      expect(store.value, isNull);
    },
  );

  testWidgets('new customer onboarding resumes the pending request form', (
    tester,
  ) async {
    final store = MemoryPendingHiringIntentStore();
    final pending = _customer.copyWith(onboardingCompleted: false);
    final auth = _ControlledAuthenticationRepository(nextUser: pending);
    await _pumpProfessional(tester, auth: auth, store: store);

    await tester.tap(find.text('Solicitar servicio'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('hiring-auth-google')));
    await tester.pumpAndSettle();

    expect(find.text('¿Cómo deseas usar LinkO?'), findsOneWidget);
    expect(find.text('¿Qué necesitas?'), findsNothing);

    await tester.tap(find.text('Necesito un servicio'));
    await tester.pumpAndSettle();

    expect(find.text('¿Qué necesitas?'), findsOneWidget);
    expect(
      appRouter.routeInformationProvider.value.uri.queryParameters['service'],
      'Instalación solar',
    );
    expect(store.value, isNull);
  });

  testWidgets('OAuth cancellation keeps a controlled auth state and intent', (
    tester,
  ) async {
    final store = MemoryPendingHiringIntentStore();
    final auth = _ControlledAuthenticationRepository();
    await _pumpProfessional(tester, auth: auth, store: store);

    await tester.tap(find.text('Solicitar servicio'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('hiring-auth-google')));
    await tester.pumpAndSettle();

    expect(
      find.text('Inicia sesión para solicitar el servicio'),
      findsOneWidget,
    );
    expect(find.textContaining('Completa el acceso'), findsOneWidget);
    expect(find.text('¿Qué necesitas?'), findsNothing);
    expect(store.value, isNotNull);
  });

  testWidgets('OAuth failure shows Spanish recovery and creates no request', (
    tester,
  ) async {
    final store = MemoryPendingHiringIntentStore();
    final auth = _ControlledAuthenticationRepository(
      signInError: StateError('oauth failed'),
    );
    await _pumpProfessional(tester, auth: auth, store: store);

    await tester.tap(find.text('Solicitar servicio'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('hiring-auth-google')));
    await tester.pumpAndSettle();

    expect(
      find.text('No fue posible iniciar sesión. Intenta nuevamente.'),
      findsOneWidget,
    );
    expect(find.text('¿Qué necesitas?'), findsNothing);
    expect(find.text('Enviar solicitud'), findsNothing);
    expect(store.value, isNotNull);
  });

  testWidgets('Ahora no clears intent and returns to the professional', (
    tester,
  ) async {
    final store = MemoryPendingHiringIntentStore();
    await _pumpProfessional(
      tester,
      auth: _ControlledAuthenticationRepository(),
      store: store,
    );

    await tester.tap(find.text('Solicitar servicio'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('hiring-auth-cancel')));
    await tester.pumpAndSettle();

    expect(find.text('Perfil profesional'), findsOneWidget);
    expect(find.text('Solicitar servicio'), findsOneWidget);
    expect(store.value, isNull);
  });

  testWidgets('authenticated customer opens the request form without a gate', (
    tester,
  ) async {
    final store = MemoryPendingHiringIntentStore();
    await _pumpProfessional(
      tester,
      auth: MockAuthenticationRepository(initialUser: _customer),
      store: store,
    );

    await tester.tap(find.text('Solicitar servicio'));
    await tester.pumpAndSettle();

    expect(find.text('¿Qué necesitas?'), findsOneWidget);
    expect(find.text('Inicia sesión para solicitar el servicio'), findsNothing);
    expect(store.value, isNull);
  });

  test(
    'pending intent is restored by a reconstructed provider container',
    () async {
      final store = MemoryPendingHiringIntentStore();
      final first = ProviderContainer(
        overrides: [pendingHiringIntentStoreProvider.overrideWithValue(store)],
      );
      await first
          .read(pendingHiringIntentProvider.notifier)
          .save(
            const PendingHiringIntent(
              professionalId: '11111111-1111-4111-8111-111111111111',
              selectedService: 'Aire acondicionado',
            ),
          );
      first.dispose();

      final reconstructed = ProviderContainer(
        overrides: [pendingHiringIntentStoreProvider.overrideWithValue(store)],
      );
      addTearDown(reconstructed.dispose);

      final restored = await reconstructed.read(
        pendingHiringIntentProvider.future,
      );
      expect(restored?.professionalId, '11111111-1111-4111-8111-111111111111');
      expect(restored?.selectedService, 'Aire acondicionado');
    },
  );
}

final _customer = AppUserProfile(
  id: 'customer-authenticated',
  displayName: 'Cliente LinkO',
  email: 'cliente@linko.test',
  avatarUrl: null,
  activeMode: AppMode.customer,
  createdAt: DateTime.utc(2026),
);

Future<void> _pumpProfessional(
  WidgetTester tester, {
  required AuthenticationRepository auth,
  required PendingHiringIntentStore store,
}) async {
  final professional = placeholderProfessionals.first;
  appRouter.goNamed(
    AppRouteNames.professionalProfile,
    pathParameters: {'professionalId': professional.id},
    queryParameters: const {'service': 'Instalación solar'},
    extra: professional,
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authenticationRepositoryProvider.overrideWithValue(auth),
        profileRepositoryProvider.overrideWithValue(MockProfileRepository()),
        pendingHiringIntentStoreProvider.overrideWithValue(store),
      ],
      child: const LinkoApp(),
    ),
  );
  await tester.pumpAndSettle();
}

class _ControlledAuthenticationRepository implements AuthenticationRepository {
  _ControlledAuthenticationRepository({this.nextUser, this.signInError});

  final AppUserProfile? nextUser;
  final Object? signInError;
  final _changes = StreamController<AppUserProfile?>.broadcast();
  AppUserProfile? _current;

  @override
  Stream<AppUserProfile?> authStateChanges() => _changes.stream;

  @override
  Future<AppUserProfile?> restoreSession() async => _current;

  @override
  Future<void> signInWithGoogle() async {
    if (signInError != null) throw signInError!;
    _current = nextUser;
    if (_current != null) _changes.add(_current);
  }

  @override
  Future<void> signInWithApple() => signInWithGoogle();

  @override
  Future<void> sendEmailLink(String email) async {}

  @override
  Future<void> signOut() async {
    _current = null;
    _changes.add(null);
  }
}
