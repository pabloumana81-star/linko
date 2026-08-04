import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko/app/app_mode.dart';
import 'package:linko/core/backend/backend_providers.dart';
import 'package:linko/core/diagnostics/diagnostics_service.dart';
import 'package:linko/features/auth/domain/models/app_user_profile.dart';

enum AuthStatus { loading, unauthenticated, guest, authenticated }

class AuthState {
  const AuthState({required this.status, this.user, this.message, this.error});

  const AuthState.loading() : this(status: AuthStatus.loading);
  const AuthState.unauthenticated({String? message, Object? error})
    : this(status: AuthStatus.unauthenticated, message: message, error: error);
  const AuthState.guest() : this(status: AuthStatus.guest);
  const AuthState.authenticated(AppUserProfile user)
    : this(status: AuthStatus.authenticated, user: user);

  final AuthStatus status;
  final AppUserProfile? user;
  final String? message;
  final Object? error;

  bool get canAccessMvp =>
      status == AuthStatus.guest || status == AuthStatus.authenticated;
}

class AuthController extends Notifier<AuthState> {
  StreamSubscription<AppUserProfile?>? _subscription;

  @override
  AuthState build() {
    final repository = ref.watch(authenticationRepositoryProvider);
    _subscription = repository.authStateChanges().listen(_loadProfile);
    ref.onDispose(() => _subscription?.cancel());
    Future<void>.microtask(restoreSession);
    return const AuthState.loading();
  }

  Future<void> restoreSession() async {
    state = const AuthState.loading();
    try {
      await _loadProfile(
        await ref.read(authenticationRepositoryProvider).restoreSession(),
      );
    } catch (error, stackTrace) {
      _report(error, stackTrace, 'auth_restore_session');
      state = AuthState.unauthenticated(error: error);
    }
  }

  void continueAsGuest() {
    state = const AuthState.guest();
  }

  Future<void> updateActiveMode(AppMode mode) async {
    final user = state.user;
    if (user != null) {
      state = AuthState.authenticated(user.copyWith(activeMode: mode));
      try {
        final updated = await ref
            .read(profileRepositoryProvider)
            .updateProfile(userId: user.id, activeMode: mode);
        state = AuthState.authenticated(updated);
      } catch (error, stackTrace) {
        _report(error, stackTrace, 'auth_update_active_mode');
        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
          error: error,
        );
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
    state = const AuthState.loading();
    try {
      await ref.read(authenticationRepositoryProvider).signOut();
      state = const AuthState.unauthenticated();
    } catch (error, stackTrace) {
      _report(error, stackTrace, 'auth_sign_out');
      state = AuthState.unauthenticated(error: error);
    }
  }

  Future<void> _signIn(Future<AppUserProfile?> Function() authenticate) async {
    state = const AuthState.loading();
    try {
      final user = await authenticate();
      if (user != null) {
        await _loadProfile(user);
      } else {
        state = const AuthState.unauthenticated();
      }
    } catch (error, stackTrace) {
      _report(error, stackTrace, 'auth_sign_in');
      state = AuthState.unauthenticated(error: error);
    }
  }

  Future<void> _loadProfile(AppUserProfile? authUser) async {
    if (authUser == null) {
      state = const AuthState.unauthenticated();
      return;
    }
    try {
      final profile = await ref
          .read(profileRepositoryProvider)
          .getOrCreateProfile(authUser);
      state = AuthState.authenticated(profile);
    } catch (error, stackTrace) {
      _report(error, stackTrace, 'auth_load_profile');
      state = AuthState.unauthenticated(error: error);
    }
  }

  void _report(Object error, StackTrace stackTrace, String context) {
    ref
        .read(diagnosticsServiceProvider)
        .unexpectedError(error, stackTrace, context: context);
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
