import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linko/app/app_mode.dart';
import 'package:linko/core/backend/backend_providers.dart';
import 'package:linko/core/backend/repositories/authentication_repository.dart';
import 'package:linko/core/backend/repositories/profile_repository.dart';
import 'package:linko/features/auth/domain/models/app_user_profile.dart';
import 'package:linko/features/auth/presentation/auth_controller.dart';

void main() {
  test(
    'a persisted session is recovered after a new app container starts',
    () async {
      final auth = _ControllableAuthenticationRepository(
        initialUser: _customer,
      );

      final first = _container(auth);
      await first.read(authControllerProvider.notifier).restoreSession();
      expect(first.read(authControllerProvider).user?.id, _customer.id);
      first.dispose();

      final restarted = _container(auth);
      addTearDown(restarted.dispose);
      await restarted.read(authControllerProvider.notifier).restoreSession();
      expect(
        restarted.read(authControllerProvider).status,
        AuthStatus.authenticated,
      );
      expect(restarted.read(authControllerProvider).user?.id, _customer.id);
    },
  );

  test('an expired session clears authenticated state', () async {
    final auth = _ControllableAuthenticationRepository(initialUser: _customer);
    final container = _container(auth);
    addTearDown(container.dispose);
    await container.read(authControllerProvider.notifier).restoreSession();

    auth.expireSession();
    await _flush();

    expect(
      container.read(authControllerProvider).status,
      AuthStatus.unauthenticated,
    );
    expect(container.read(authControllerProvider).user, isNull);
  });

  test(
    'an invalid persisted session produces a controlled unauthenticated state',
    () async {
      final auth = _ControllableAuthenticationRepository(
        restoreError: StateError('refresh token inválido'),
      );
      final container = _container(auth);
      addTearDown(container.dispose);

      await container.read(authControllerProvider.notifier).restoreSession();

      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.error, isNotNull);
    },
  );

  test(
    'logout, login again and account switching replace the active profile',
    () async {
      final auth = _ControllableAuthenticationRepository(
        initialUser: _customer,
      );
      final profiles = _MemoryProfileRepository([_customer, _professional]);
      final container = _container(auth, profiles: profiles);
      addTearDown(container.dispose);
      await container.read(authControllerProvider.notifier).restoreSession();

      await container.read(authControllerProvider.notifier).signOut();
      expect(
        container.read(authControllerProvider).status,
        AuthStatus.unauthenticated,
      );

      auth.authenticateAs(_professional);
      await _flush();
      expect(container.read(authControllerProvider).user?.id, _professional.id);

      profiles.emit(_customer.copyWith(displayName: 'Perfil anterior'));
      await _flush();
      expect(container.read(authControllerProvider).user?.id, _professional.id);
    },
  );

  test('a null auth event does not collapse explicit guest state', () async {
    final auth = _ControllableAuthenticationRepository();
    final container = _container(auth);
    addTearDown(container.dispose);
    container.read(authControllerProvider.notifier).continueAsGuest();

    auth.expireSession();
    await _flush();

    expect(container.read(authControllerProvider).status, AuthStatus.guest);
  });

  test('guest can transition safely into an authenticated account', () async {
    final auth = _ControllableAuthenticationRepository();
    final container = _container(auth);
    addTearDown(container.dispose);
    container.read(authControllerProvider.notifier).continueAsGuest();

    auth.nextOAuthUser = _customer;
    await container.read(authControllerProvider.notifier).signInWithGoogle();

    expect(
      container.read(authControllerProvider).status,
      AuthStatus.authenticated,
    );
    expect(container.read(authControllerProvider).user?.id, _customer.id);
  });

  test('Magic Link callback restores a session and existing profile', () async {
    final auth = _ControllableAuthenticationRepository();
    final existing = _customer.copyWith(displayName: 'Nombre persistido');
    final profiles = _MemoryProfileRepository([existing]);
    final container = _container(auth, profiles: profiles);
    addTearDown(container.dispose);
    await container.read(authControllerProvider.notifier).restoreSession();

    auth.authenticateAs(_customer.copyWith(displayName: 'Metadata temporal'));
    await _flush();

    final state = container.read(authControllerProvider);
    expect(state.status, AuthStatus.authenticated);
    expect(state.user?.displayName, 'Nombre persistido');
  });

  test(
    'invalid Magic Link leaves a controlled unauthenticated state',
    () async {
      final auth = _ControllableAuthenticationRepository(
        restoreError: const AuthenticationLaunchException(
          'El enlace de acceso venció o no es válido.',
        ),
      );
      final container = _container(auth);
      addTearDown(container.dispose);

      await container.read(authControllerProvider.notifier).restoreSession();

      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.error, isA<AuthenticationLaunchException>());
    },
  );

  test(
    'OAuth cancellation leaves a usable Spanish authentication state',
    () async {
      final auth = _ControllableAuthenticationRepository();
      final container = _container(auth);
      addTearDown(container.dispose);

      await container.read(authControllerProvider.notifier).signInWithApple();

      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.message, contains('Completa el acceso'));
    },
  );

  test(
    'new profile keeps onboarding pending until a role is selected',
    () async {
      final pending = _customer.copyWith(onboardingCompleted: false);
      final profiles = _MemoryProfileRepository([pending]);
      final auth = _ControllableAuthenticationRepository(initialUser: pending);
      final container = _container(auth, profiles: profiles);
      addTearDown(container.dispose);
      await container.read(authControllerProvider.notifier).restoreSession();
      expect(
        container.read(authControllerProvider).user?.onboardingCompleted,
        isFalse,
      );

      await container
          .read(authControllerProvider.notifier)
          .updateActiveMode(AppMode.professional);

      expect(
        container.read(authControllerProvider).user?.activeMode,
        AppMode.professional,
      );
      expect(
        container.read(authControllerProvider).user?.onboardingCompleted,
        isTrue,
      );
    },
  );
}

ProviderContainer _container(
  AuthenticationRepository auth, {
  ProfileRepository? profiles,
}) => ProviderContainer(
  overrides: [
    authenticationRepositoryProvider.overrideWithValue(auth),
    if (profiles != null) profileRepositoryProvider.overrideWithValue(profiles),
  ],
);

Future<void> _flush() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

final _customer = AppUserProfile(
  id: 'customer-session',
  displayName: 'Cliente sesión',
  email: 'cliente@linko.test',
  avatarUrl: null,
  activeMode: AppMode.customer,
  createdAt: DateTime.utc(2026, 8, 8),
);

final _professional = AppUserProfile(
  id: 'professional-session',
  displayName: 'Profesional sesión',
  email: 'profesional@linko.test',
  avatarUrl: null,
  activeMode: AppMode.professional,
  createdAt: DateTime.utc(2026, 8, 8),
);

class _ControllableAuthenticationRepository
    implements AuthenticationRepository {
  _ControllableAuthenticationRepository({
    AppUserProfile? initialUser,
    this.restoreError,
  }) : _currentUser = initialUser;

  final Object? restoreError;
  final _changes = StreamController<AppUserProfile?>.broadcast(sync: true);
  AppUserProfile? _currentUser;
  AppUserProfile? nextOAuthUser;

  @override
  Stream<AppUserProfile?> authStateChanges() => _changes.stream;

  @override
  Future<AppUserProfile?> restoreSession() async {
    if (restoreError != null) throw restoreError!;
    return _currentUser;
  }

  void authenticateAs(AppUserProfile user) {
    _currentUser = user;
    _changes.add(user);
  }

  void expireSession() {
    _currentUser = null;
    _changes.add(null);
  }

  @override
  Future<void> sendEmailLink(String email) async {}

  @override
  Future<void> signInWithApple() async => _completeOAuth();

  @override
  Future<void> signInWithGoogle() async => _completeOAuth();

  void _completeOAuth() {
    final user = nextOAuthUser;
    if (user != null) authenticateAs(user);
  }

  @override
  Future<void> signOut() async => expireSession();
}

class _MemoryProfileRepository implements ProfileRepository {
  _MemoryProfileRepository(Iterable<AppUserProfile> seed)
    : _profiles = {for (final profile in seed) profile.id: profile};

  final Map<String, AppUserProfile> _profiles;
  final Map<String, StreamController<AppUserProfile?>> _streams = {};

  @override
  Future<AppUserProfile> getOrCreateProfile(AppUserProfile authUser) async =>
      _profiles.putIfAbsent(authUser.id, () => authUser);

  @override
  Stream<AppUserProfile?> watchProfile(String userId) =>
      (_streams[userId] ??= StreamController.broadcast()).stream;

  void emit(AppUserProfile profile) {
    _profiles[profile.id] = profile;
    _streams[profile.id]?.add(profile);
  }

  @override
  Future<AppUserProfile> updateProfile({
    required String userId,
    String? displayName,
    String? avatarUrl,
    AppMode? activeMode,
    bool? onboardingCompleted,
  }) async {
    final current = _profiles[userId]!;
    final updated = current.copyWith(
      displayName: displayName,
      avatarUrl: avatarUrl,
      activeMode: activeMode,
      onboardingCompleted: onboardingCompleted,
    );
    emit(updated);
    return updated;
  }
}
