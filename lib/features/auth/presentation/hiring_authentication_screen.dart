import 'package:flutter/material.dart';

class HiringAuthenticationScreen extends StatelessWidget {
  const HiringAuthenticationScreen({
    required this.onGoogleSignIn,
    required this.onCancel,
    required this.isLoading,
    this.message,
    this.errorMessage,
    super.key,
  });

  final VoidCallback onGoogleSignIn;
  final VoidCallback onCancel;
  final bool isLoading;
  final String? message;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitar servicio')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.lock_person_outlined,
                  size: 56,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  'Inicia sesión para solicitar el servicio',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Necesitamos identificarte antes de enviar una solicitud '
                  'al profesional.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Text(message!, textAlign: TextAlign.center),
                ],
                if (errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  key: const ValueKey('hiring-auth-google'),
                  onPressed: isLoading ? null : onGoogleSignIn,
                  child: const Text('Continuar con Google'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  key: const ValueKey('hiring-auth-cancel'),
                  onPressed: isLoading ? null : onCancel,
                  child: const Text('Ahora no'),
                ),
                if (isLoading) ...[
                  const SizedBox(height: 20),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
