enum BackendMode { mock, supabase }

class BackendConfig {
  const BackendConfig({
    required this.mode,
    this.supabaseUrl = '',
    this.supabaseAnonKey = '',
    this.authRedirectUrl = '',
  });

  factory BackendConfig.fromEnvironment() {
    return BackendConfig.fromValues(
      modeValue: const String.fromEnvironment('BACKEND_MODE'),
      supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
      supabaseAnonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
      authRedirectUrl: const String.fromEnvironment('AUTH_REDIRECT_URL'),
    );
  }

  factory BackendConfig.fromValues({
    required String modeValue,
    String supabaseUrl = '',
    String supabaseAnonKey = '',
    String authRedirectUrl = '',
  }) {
    final normalizedMode = modeValue.trim().toLowerCase();
    if (normalizedMode.isEmpty) {
      throw const BackendConfigurationException(
        'BACKEND_MODE es obligatorio. Use "mock" o "supabase".',
      );
    }
    final mode = switch (normalizedMode) {
      'mock' => BackendMode.mock,
      'supabase' => BackendMode.supabase,
      _ => throw BackendConfigurationException(
        'BACKEND_MODE no es válido: "$modeValue". Use "mock" o "supabase".',
      ),
    };
    return BackendConfig(
      mode: mode,
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseAnonKey,
      authRedirectUrl: authRedirectUrl,
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
    if (uri == null || uri.scheme != 'https' || !uri.hasAuthority) {
      throw const BackendConfigurationException(
        'SUPABASE_URL debe ser una URL HTTPS válida.',
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
