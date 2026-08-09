import 'package:linko/core/backend/repositories/authentication_repository.dart';

enum AuthRedirectTarget { web, native }

class AuthRedirectPolicy {
  const AuthRedirectPolicy._();

  static const nativeScheme = 'io.supabase.linko';
  static const nativeHost = 'login-callback';

  static void validate(String value, AuthRedirectTarget target) {
    final uri = Uri.tryParse(value.trim());
    final structurallySafe =
        uri != null &&
        uri.hasScheme &&
        uri.hasAuthority &&
        uri.userInfo.isEmpty &&
        !uri.hasQuery &&
        !uri.hasFragment &&
        (uri.path.isEmpty || uri.path == '/');
    if (!structurallySafe) {
      throw const AuthenticationLaunchException(
        'La URL de retorno de autenticación no es válida.',
      );
    }

    final allowed = switch (target) {
      AuthRedirectTarget.web => uri.scheme == 'https' || uri.scheme == 'http',
      AuthRedirectTarget.native =>
        uri.scheme == nativeScheme && uri.host == nativeHost && !uri.hasPort,
    };
    if (!allowed) {
      throw const AuthenticationLaunchException(
        'La URL de retorno de autenticación no pertenece a LinkO.',
      );
    }
  }
}
