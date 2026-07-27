import 'package:flutter/material.dart';

class RequestSuccessContent extends StatelessWidget {
  const RequestSuccessContent({
    required this.professionalName,
    required this.onViewRequests,
    required this.onBackHome,
    super.key,
  });

  final String professionalName;
  final VoidCallback onViewRequests;
  final VoidCallback onBackHome;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: colorScheme.tertiary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_rounded,
              size: 56,
              color: colorScheme.tertiary,
            ),
          ),
          const SizedBox(height: 26),
          Text(
            'Solicitud enviada',
            textAlign: TextAlign.center,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tu solicitud fue enviada correctamente.',
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 8),
          Text(
            '$professionalName recibirá tu solicitud y podrá responder con '
            'una cotización.',
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: onViewRequests,
              child: const Text('Ver mis solicitudes'),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onBackHome,
            child: const Text('Volver al inicio'),
          ),
        ],
      ),
    );
  }
}
