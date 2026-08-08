import 'package:linko/features/auth/domain/models/app_user_profile.dart';

class AuthenticationLaunchException implements Exception {
  const AuthenticationLaunchException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class AuthenticationRepository {
  Future<AppUserProfile?> restoreSession();
  Stream<AppUserProfile?> authStateChanges();
  Future<void> sendEmailLink(String email);
  Future<void> signInWithGoogle();
  Future<void> signInWithApple();
  Future<void> signOut();
}
