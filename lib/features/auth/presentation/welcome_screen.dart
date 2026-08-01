import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({
    required this.onContinueAsGuest,
    required this.onGoogleSignIn,
    required this.onAppleSignIn,
    required this.onSendEmailLink,
    this.isLoading = false,
    this.message,
    this.errorMessage,
    super.key,
  });

  final VoidCallback onContinueAsGuest;
  final VoidCallback onGoogleSignIn;
  final VoidCallback onAppleSignIn;
  final ValueChanged<String> onSendEmailLink;
  final bool isLoading;
  final String? message;
  final String? errorMessage;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _emailController = TextEditingController();
  String? _emailError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _sendEmailLink() {
    final email = _emailController.text.trim();
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    setState(() {
      _emailError = valid ? null : 'Ingresa un correo electrónico válido.';
    });
    if (valid) {
      widget.onSendEmailLink(email);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.handshake_rounded,
                    size: 72,
                    color: colors.primary,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'LinkO',
                    textAlign: TextAlign.center,
                    style: textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Encuentra profesionales de confianza para cualquier necesidad.',
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _AuthButton(
                    key: const ValueKey('auth-guest'),
                    label: 'Continuar como invitado',
                    icon: Icons.person_outline_rounded,
                    primary: true,
                    onPressed: widget.isLoading
                        ? null
                        : widget.onContinueAsGuest,
                  ),
                  const SizedBox(height: 10),
                  _AuthButton(
                    key: const ValueKey('auth-google'),
                    label: 'Continuar con Google',
                    leading: Text(
                      'G',
                      style: textTheme.titleMedium?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    onPressed: widget.isLoading ? null : widget.onGoogleSignIn,
                  ),
                  const SizedBox(height: 10),
                  _AuthButton(
                    key: const ValueKey('auth-apple'),
                    label: 'Continuar con Apple',
                    icon: Icons.apple,
                    onPressed: widget.isLoading ? null : widget.onAppleSignIn,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    key: const ValueKey('auth-email'),
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    onSubmitted: (_) => _sendEmailLink(),
                    decoration: InputDecoration(
                      labelText: 'Correo electrónico',
                      hintText: 'nombre@correo.com',
                      errorText: _emailError,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    key: const ValueKey('auth-email-submit'),
                    onPressed: widget.isLoading ? null : _sendEmailLink,
                    icon: const Icon(Icons.email_outlined),
                    label: const Text('Recibir enlace de acceso'),
                  ),
                  if (widget.isLoading) ...[
                    const SizedBox(height: 20),
                    const Center(child: CircularProgressIndicator()),
                  ],
                  if (widget.message != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      widget.message!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.tertiary),
                    ),
                  ],
                  if (widget.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      widget.errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.error),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  const _AuthButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.leading,
    this.primary = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? leading;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(width: 24, child: leading ?? Icon(icon, size: 22)),
        const SizedBox(width: 12),
        Text(label),
      ],
    );
    return SizedBox(
      height: 54,
      child: primary
          ? FilledButton(onPressed: onPressed, child: content)
          : OutlinedButton(onPressed: onPressed, child: content),
    );
  }
}
