import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linko/app/app.dart';
import 'package:linko/app/app_mode.dart';
import 'package:linko/app/router.dart';
import 'package:linko/core/backend/backend_providers.dart';
import 'package:linko/core/backend/repositories/authentication_repository.dart';
import 'package:linko/core/backend/repositories/profile_repository.dart';
import 'package:linko/features/auth/domain/models/app_user_profile.dart';

void main() {
  for (final mode in AppMode.values) {
    testWidgets(
      'authenticated ${mode.name} onboarding remains on Home after profile refresh',
      (tester) async {
        final pending = AppUserProfile(
          id: 'google-user',
          displayName: 'Usuario Google',
          email: 'google@linko.test',
          avatarUrl: null,
          activeMode: AppMode.customer,
          onboardingCompleted: false,
          createdAt: DateTime.utc(2026, 8, 12),
        );
        final profiles = _RacingProfileRepository(pending);
        appRouter.go(AppRoutes.userType);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authenticationRepositoryProvider.overrideWithValue(
                _AuthenticatedRepository(pending),
              ),
              profileRepositoryProvider.overrideWithValue(profiles),
            ],
            child: const LinkoApp(),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('¿Cómo deseas usar LinkO?'), findsOneWidget);

        await tester.tap(
          find.text(
            mode == AppMode.customer
                ? 'Necesito un servicio'
                : 'Quiero ofrecer mis servicios',
          ),
        );
        await tester.pump();
        await profiles.updateStarted.future;
        profiles.emit(pending);
        await tester.pump();
        expect(find.text('¿Cómo deseas usar LinkO?'), findsOneWidget);

        profiles.completeUpdate();
        await tester.pumpAndSettle();
        final homeText = mode == AppMode.customer
            ? '¿Qué servicio necesitas hoy?'
            : 'Hola, Carlos';
        expect(find.text(homeText), findsOneWidget);

        profiles.emit(pending);
        await tester.pumpAndSettle();
        expect(find.text(homeText), findsOneWidget);
        expect(find.text('¿Cómo deseas usar LinkO?'), findsNothing);
      },
    );
  }
}

class _AuthenticatedRepository implements AuthenticationRepository {
  _AuthenticatedRepository(this.user);

  final AppUserProfile user;

  @override
  Stream<AppUserProfile?> authStateChanges() => const Stream.empty();

  @override
  Future<AppUserProfile?> restoreSession() async => user;

  @override
  Future<void> sendEmailLink(String email) async {}

  @override
  Future<void> signInWithApple() async {}

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signOut() async {}
}

class _RacingProfileRepository implements ProfileRepository {
  _RacingProfileRepository(this.profile);

  AppUserProfile profile;
  final updateStarted = Completer<void>();
  final _allowUpdate = Completer<void>();
  final _stream = StreamController<AppUserProfile?>.broadcast(sync: true);

  @override
  Future<AppUserProfile> getOrCreateProfile(AppUserProfile authUser) async =>
      profile;

  @override
  Stream<AppUserProfile?> watchProfile(String userId) => _stream.stream;

  void emit(AppUserProfile value) => _stream.add(value);

  void completeUpdate() => _allowUpdate.complete();

  @override
  Future<AppUserProfile> updateProfile({
    required String userId,
    String? displayName,
    String? avatarUrl,
    AppMode? activeMode,
    bool? onboardingCompleted,
  }) async {
    if (!updateStarted.isCompleted) updateStarted.complete();
    await _allowUpdate.future;
    profile = profile.copyWith(
      activeMode: activeMode,
      onboardingCompleted: onboardingCompleted,
      updatedAt: profile.updatedAt.add(const Duration(seconds: 1)),
    );
    return profile;
  }
}
