import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({required this.onContinue, super.key});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.handshake_rounded,
                      size: 52,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'LinkO',
                    style: textTheme.displaySmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Encuentra profesionales de confianza para cualquier necesidad.',
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  _WelcomeButton(
                    label: 'Continuar como invitado',
                    icon: Icons.person_outline_rounded,
                    isPrimary: true,
                    onPressed: onContinue,
                  ),
                  const SizedBox(height: 12),
                  _WelcomeButton(
                    label: 'Continuar con Google',
                    leading: Text(
                      'G',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: onContinue,
                  ),
                  const SizedBox(height: 12),
                  _WelcomeButton(
                    label: 'Continuar con Apple',
                    icon: Icons.apple,
                    onPressed: onContinue,
                  ),
                  const SizedBox(height: 12),
                  _WelcomeButton(
                    label: 'Continuar con correo',
                    icon: Icons.email_outlined,
                    onPressed: onContinue,
                  ),
                  const SizedBox(height: 28),
                  TextButton(
                    onPressed: onContinue,
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                      textStyle: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('Soy profesional'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeButton extends StatelessWidget {
  const _WelcomeButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.leading,
    this.isPrimary = false,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Widget? leading;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(width: 24, child: leading ?? Icon(icon, size: 22)),
        const SizedBox(width: 12),
        Expanded(
          child: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
        ),
        const SizedBox(width: 36),
      ],
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    );
    final textStyle = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600);

    if (isPrimary) {
      return SizedBox(
        width: double.infinity,
        height: 58,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            shape: shape,
            textStyle: textStyle,
          ),
          child: content,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 58,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: colorScheme.outline),
          shape: shape,
          textStyle: textStyle,
        ),
        child: content,
      ),
    );
  }
}
