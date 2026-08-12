import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko/app/app_mode.dart';
import 'package:linko/core/backend/backend_providers.dart';
import 'package:linko/core/diagnostics/diagnostics_service.dart';
import 'package:linko/features/auth/domain/models/app_user_profile.dart';

enum AuthStatus { loading, unauthenticated, guest, authenticated, suspended }

class AuthState {
  const AuthState({required this.status, this.user, this.message, this.error});

  const AuthState.loading() : this(status: AuthStatus.loading);
  const AuthState.unauthenticated({String? message, Object? error})
    : this(status: AuthStatus.unauthenticated, message: message, error: error);
  const AuthState.guest() : this(status: AuthStatus.guest);
  const AuthState.authenticated(AppUserProfile user)
    : this(status: AuthStatus.authenticated, user: user);
  const AuthState.suspended(AppUserProfile user)
    : this(status: AuthStatus.suspended, user: user);

  final AuthStatus status;
  final AppUserProfile? user;
  final String? message;
  final Object? error;

  bool get canAccessMvp =>
      status == AuthStatus.guest || status == AuthStatus.authenticated;
}

class AuthController extends Notifier<AuthState> {
  StreamSubscription<AppUserProfile?>? _subscription;
  StreamSubscription<AppUserProfile?>? _profileSubscription;
  String? _watchedProfileId;
  int _profileLoadRevision = 0;
  int _profileMutationRevision = 0;
  int? _activeModeMutationRevision;
  Future<void>? _restoreOperation;
  bool _initialResolutionClaimed = false;

  @override
  AuthState build() {
    final repository = ref.watch(authenticationRepositoryProvider);
    _subscription = repository.authStateChanges().listen(_loadProfile);
    ref.onDispose(() {
      _subscription?.cancel();
      _profileSubscription?.cancel();
    });
    Future<void>.microtask(() {
      if (!_initialResolutionClaimed) unawaited(restoreSession());
    });
    return const AuthState.loading();
  }

  Future<void> restoreSession() async {
    _initialResolutionClaimed = true;
    if (state.status == AuthStatus.guest) return;
    final current = _restoreOperation;
    if (current != null) return current;
    final operation = _restoreSession();
    _restoreOperation = operation;
    try {
      await operation;
    } finally {
      if (identical(_restoreOperation, operation)) _restoreOperation = null;
    }
  }

  Future<void> _restoreSession() async {
    state = const AuthState.loading();
    try {
      await _loadProfile(
        await ref.read(authenticationRepositoryProvider).restoreSession(),
      );
    } catch (error, stackTrace) {
      if (!ref.mounted) return;
      _report(error, stackTrace, 'auth_restore_session');
      state = AuthState.unauthenticated(error: error);
    }
  }

  void continueAsGuest() {
    _initialResolutionClaimed = true;
    _profileLoadRevision++;
    _activeModeMutationRevision = null;
    _profileMutationRevision++;
    state = const AuthState.guest();
  }

  Future<void> updateActiveMode(AppMode mode) async {
    final user = state.user;
    if (user != null) {
      final mutationRevision = ++_profileMutationRevision;
      _activeModeMutationRevision = mutationRevision;
      state = AuthState.authenticated(
        user.copyWith(activeMode: mode, onboardingCompleted: true),
      );
      try {
        final updated = await ref
            .read(profileRepositoryProvider)
            .updateProfile(
              userId: user.id,
              activeMode: mode,
              onboardingCompleted: true,
            );
        if (ref.mounted &&
            _activeModeMutationRevision == mutationRevision &&
            state.user?.id == user.id) {
          _setProfileState(updated);
        }
      } catch (error, stackTrace) {
        _report(error, stackTrace, 'auth_update_active_mode');
        if (ref.mounted &&
            _activeModeMutationRevision == mutationRevision &&
            state.user?.id == user.id) {
          state = AuthState(
            status: AuthStatus.authenticated,
            user: user,
            error: error,
          );
        }
      } finally {
        if (_activeModeMutationRevision == mutationRevision) {
          _activeModeMutationRevision = null;
        }
      }
    }
  }

  Future<void> updateProfile({String? displayName, String? avatarUrl}) async {
    final user = state.user;
    if (user == null) return;
    try {
      final updated = await ref
          .read(profileRepositoryProvider)
          .updateProfile(
            userId: user.id,
            displayName: displayName,
            avatarUrl: avatarUrl,
          );
      state = AuthState.authenticated(updated);
    } catch (error, stackTrace) {
      _report(error, stackTrace, 'auth_update_profile');
      rethrow;
    }
  }

  Future<void> sendEmailLink(String email) async {
    state = const AuthState.loading();
    try {
      await ref.read(authenticationRepositoryProvider).sendEmailLink(email);
      state = const AuthState.unauthenticated(
        message: 'Revisa tu correo para abrir el enlace de acceso.',
      );
    } catch (error, stackTrace) {
      _report(error, stackTrace, 'auth_send_email_link');
      state = AuthState.unauthenticated(error: error);
    }
  }

  Future<void> signInWithGoogle() =>
      _signIn(ref.read(authenticationRepositoryProvider).signInWithGoogle);

  Future<void> signInWithApple() =>
      _signIn(ref.read(authenticationRepositoryProvider).signInWithApple);

  Future<void> signOut() async {
    _initialResolutionClaimed = true;
    _profileLoadRevision++;
    _activeModeMutationRevision = null;
    _profileMutationRevision++;
    state = const AuthState.loading();
    try {
      await ref.read(authenticationRepositoryProvider).signOut();
      unawaited(_profileSubscription?.cancel());
      _profileSubscription = null;
      _watchedProfileId = null;
      state = const AuthState.unauthenticated();
    } catch (error, stackTrace) {
      _report(error, stackTrace, 'auth_sign_out');
      state = AuthState.unauthenticated(error: error);
    }
  }

  Future<void> _signIn(Future<void> Function() authenticate) async {
    _initialResolutionClaimed = true;
    _profileLoadRevision++;
    state = const AuthState.loading();
    try {
      await authenticate();
      final user = await ref
          .read(authenticationRepositoryProvider)
          .restoreSession();
      if (user != null) {
        await _loadProfile(user);
      } else if (state.status == AuthStatus.loading) {
        state = const AuthState.unauthenticated(
          message: 'Completa el acceso en el proveedor para volver a LinkO.',
        );
      }
    } catch (error, stackTrace) {
      _report(error, stackTrace, 'auth_sign_in');
      state = AuthState.unauthenticated(error: error);
    }
  }

  Future<void> _loadProfile(AppUserProfile? authUser) async {
    if (authUser == null) {
      if (state.status == AuthStatus.guest) return;
      _profileLoadRevision++;
      _activeModeMutationRevision = null;
      _profileMutationRevision++;
      unawaited(_profileSubscription?.cancel());
      _profileSubscription = null;
      _watchedProfileId = null;
      state = const AuthState.unauthenticated();
      return;
    }
    final revision = ++_profileLoadRevision;
    try {
      final profile = await ref
          .read(profileRepositoryProvider)
          .getOrCreateProfile(authUser);
      if (!ref.mounted || revision != _profileLoadRevision) return;
      _setProfileState(profile);
      if (_profileSubscription != null && _watchedProfileId == profile.id) {
        return;
      }
      await _profileSubscription?.cancel();
      if (!ref.mounted || revision != _profileLoadRevision) return;
      _watchedProfileId = profile.id;
      _profileSubscription = ref
          .read(profileRepositoryProvider)
          .watchProfile(profile.id)
          .listen(
            (updated) {
              if (ref.mounted &&
                  updated != null &&
                  _watchedProfileId == updated.id &&
                  _activeModeMutationRevision == null) {
                _setProfileStateFromStream(updated);
              }
            },
            onError: (Object error, StackTrace stackTrace) => ref.mounted
                ? _report(error, stackTrace, 'auth_watch_profile')
                : null,
          );
    } catch (error, stackTrace) {
      if (revision != _profileLoadRevision) return;
      _report(error, stackTrace, 'auth_load_profile');
      state = AuthState.unauthenticated(
        message: 'Tu sesión no pudo recuperarse. Inicia sesión nuevamente.',
        error: error,
      );
    }
  }

  void _setProfileState(AppUserProfile profile) {
    state = profile.accountStatus == AccountStatus.suspended
        ? AuthState.suspended(profile)
        : AuthState.authenticated(profile);
  }

  void _setProfileStateFromStream(AppUserProfile profile) {
    final current = state.user;
    if (current?.id == profile.id &&
        profile.updatedAt.isBefore(current!.updatedAt)) {
      return;
    }
    _setProfileState(profile);
  }

  void _report(Object error, StackTrace stackTrace, String context) {
    if (!ref.mounted) return;
    ref
        .read(diagnosticsServiceProvider)
        .unexpectedError(error, stackTrace, context: context);
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
