enum BackendMode { mock, supabase }

class BackendConfig {
  const BackendConfig({
    required this.mode,
    this.supabaseUrl = '',
    this.supabaseAnonKey = '',
    this.authRedirectUrl = '',
  });

  factory BackendConfig.fromEnvironment() {
    const modeValue = String.fromEnvironment(
      'BACKEND_MODE',
      defaultValue: 'mock',
    );
    return BackendConfig(
      mode: modeValue.toLowerCase() == 'supabase'
          ? BackendMode.supabase
          : BackendMode.mock,
      supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
      supabaseAnonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
      authRedirectUrl: const String.fromEnvironment('AUTH_REDIRECT_URL'),
    );
  }

  final BackendMode mode;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String authRedirectUrl;

  void validate() {
    if (mode == BackendMode.mock) {
      return;
    }
    final uri = Uri.tryParse(supabaseUrl);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      throw const BackendConfigurationException(
        'SUPABASE_URL debe ser una URL válida.',
      );
    }
    if (supabaseAnonKey.trim().isEmpty) {
      throw const BackendConfigurationException(
        'SUPABASE_ANON_KEY es obligatoria en modo Supabase.',
      );
    }
  }
}

class BackendConfigurationException implements Exception {
  const BackendConfigurationException(this.message);

  final String message;

  @override
  String toString() => 'BackendConfigurationException: $message';
}
