import 'package:flutter/material.dart';

class ProfessionalDiscoveryState extends StatelessWidget {
  const ProfessionalDiscoveryState.empty({
    required this.onPrimaryAction,
    required this.onHome,
    super.key,
  }) : title = 'No encontramos profesionales disponibles',
       body =
           'Todavía no hay profesionales disponibles para este servicio. '
           'Estamos sumando nuevos profesionales a LinkO.',
       primaryLabel = 'Buscar otro servicio';

  const ProfessionalDiscoveryState.error({
    required this.onPrimaryAction,
    required this.onHome,
    super.key,
  }) : title = 'No pudimos cargar los profesionales',
       body = 'Revisa tu conexión e inténtalo nuevamente.',
       primaryLabel = 'Reintentar';

  final String title;
  final String body;
  final String primaryLabel;
  final VoidCallback onPrimaryAction;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 52,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onPrimaryAction,
                child: Text(primaryLabel),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: onHome,
                child: const Text('Volver al inicio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
