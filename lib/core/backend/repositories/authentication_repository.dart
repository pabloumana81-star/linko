import 'package:linko/features/auth/domain/models/app_user_profile.dart';

abstract interface class AuthenticationRepository {
  Future<AppUserProfile?> restoreSession();
  Stream<AppUserProfile?> authStateChanges();
  Future<void> sendEmailLink(String email);
  Future<AppUserProfile?> signInWithGoogle();
  Future<AppUserProfile?> signInWithApple();
  Future<void> signOut();
}
