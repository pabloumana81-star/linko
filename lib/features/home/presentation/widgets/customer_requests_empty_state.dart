import 'package:flutter/material.dart';

class CustomerRequestsEmptyState extends StatelessWidget {
  const CustomerRequestsEmptyState({
    required this.onSearchProfessionals,
    super.key,
  });

  final VoidCallback onSearchProfessionals;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 52,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Todavía no has solicitado ningún servicio.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onSearchProfessionals,
              child: const Text('Buscar profesionales'),
            ),
          ],
        ),
      ),
    );
  }
}
