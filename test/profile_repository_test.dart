import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linko/app/app_mode.dart';
import 'package:linko/core/backend/backend_providers.dart';
import 'package:linko/core/backend/data/mock_backend_repositories.dart';
import 'package:linko/core/backend/repositories/profile_repository.dart';
import 'package:linko/features/auth/domain/models/app_user_profile.dart';
import 'package:linko/features/auth/presentation/auth_controller.dart';

void main() {
  final authUser = AppUserProfile(
    id: 'profile-user',
    displayName: 'Perfil desde Auth',
    email: 'perfil@linko.test',
    avatarUrl: null,
    activeMode: AppMode.customer,
    createdAt: DateTime.utc(2026, 8, 1),
  );

  test('mock profile is created once and persists editable values', () async {
    final repository = MockProfileRepository();

    final created = await repository.getOrCreateProfile(authUser);
    final updated = await repository.updateProfile(
      userId: authUser.id,
      displayName: 'Ana Rodríguez',
      avatarUrl: 'https://example.test/avatar.png',
      activeMode: AppMode.professional,
    );
    final loadedAgain = await repository.getOrCreateProfile(authUser);

    expect(created, same(authUser));
    expect(updated.displayName, 'Ana Rodríguez');
    expect(updated.avatarUrl, 'https://example.test/avatar.png');
    expect(updated.activeMode, AppMode.professional);
    expect(loadedAgain, same(updated));
  });

  test(
    'login loads an existing persisted profile instead of auth metadata',
    () async {
      final persisted = authUser.copyWith(
        displayName: 'Nombre persistido',
        activeMode: AppMode.professional,
      );
      final profiles = _SeededProfileRepository(persisted);
      final container = ProviderContainer(
        overrides: [
          authenticationRepositoryProvider.overrideWithValue(
            MockAuthenticationRepository(initialUser: authUser),
          ),
          profileRepositoryProvider.overrideWithValue(profiles),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authControllerProvider.notifier).restoreSession();

      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.user?.displayName, 'Nombre persistido');
      expect(state.user?.activeMode, AppMode.professional);
    },
  );

  test(
    'active mode changes are persisted through the profile provider',
    () async {
      final profiles = _SeededProfileRepository(authUser);
      final container = ProviderContainer(
        overrides: [
          authenticationRepositoryProvider.overrideWithValue(
            MockAuthenticationRepository(initialUser: authUser),
          ),
          profileRepositoryProvider.overrideWithValue(profiles),
        ],
      );
      addTearDown(container.dispose);
      await container.read(authControllerProvider.notifier).restoreSession();

      await container
          .read(authControllerProvider.notifier)
          .updateActiveMode(AppMode.professional);

      expect(profiles.profile.activeMode, AppMode.professional);
      expect(
        container.read(authControllerProvider).user?.activeMode,
        AppMode.professional,
      );
    },
  );

  test('guest mode does not create or update a persisted profile', () {
    final profiles = _SeededProfileRepository(authUser);
    final container = ProviderContainer(
      overrides: [profileRepositoryProvider.overrideWithValue(profiles)],
    );
    addTearDown(container.dispose);

    container.read(authControllerProvider.notifier).continueAsGuest();

    expect(container.read(authControllerProvider).status, AuthStatus.guest);
    expect(profiles.getOrCreateCalls, 0);
    expect(profiles.updateCalls, 0);
  });
}

class _SeededProfileRepository implements ProfileRepository {
  _SeededProfileRepository(this.profile);

  AppUserProfile profile;
  int getOrCreateCalls = 0;
  int updateCalls = 0;

  @override
  Future<AppUserProfile> getOrCreateProfile(AppUserProfile authUser) async {
    getOrCreateCalls++;
    return profile;
  }

  @override
  Future<AppUserProfile> updateProfile({
    required String userId,
    String? displayName,
    String? avatarUrl,
    AppMode? activeMode,
  }) async {
    updateCalls++;
    profile = profile.copyWith(
      displayName: displayName,
      avatarUrl: avatarUrl,
      activeMode: activeMode,
    );
    return profile;
  }
}
