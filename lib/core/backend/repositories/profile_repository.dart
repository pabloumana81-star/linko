import 'package:linko/app/app_mode.dart';
import 'package:linko/features/auth/domain/models/app_user_profile.dart';

abstract interface class ProfileRepository {
  Stream<AppUserProfile?> watchProfile(String userId);

  Future<AppUserProfile> getOrCreateProfile(AppUserProfile authUser);

  Future<AppUserProfile> updateProfile({
    required String userId,
    String? displayName,
    String? avatarUrl,
    AppMode? activeMode,
    bool? onboardingCompleted,
  });
}
