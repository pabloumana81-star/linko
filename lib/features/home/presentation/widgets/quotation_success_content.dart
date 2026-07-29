import 'package:flutter/material.dart';

class QuotationSuccessContent extends StatelessWidget {
  const QuotationSuccessContent({required this.onViewRequests, super.key});

  final VoidCallback onViewRequests;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: colors.tertiary.withValues(alpha: .12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 56,
                  color: colors.tertiary,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Cotización enviada',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Tu cotización fue enviada correctamente.\n\n'
                'El cliente podrá revisarla y responder desde la conversación.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onViewRequests,
                  child: const Text('Volver a solicitudes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
