import 'package:flutter/material.dart';
import 'package:linko/features/home/presentation/models/incoming_service_request.dart';
import 'package:linko/features/home/presentation/models/request_draft.dart';
import 'package:linko/features/home/presentation/widgets/request_status_badge.dart';

class IncomingRequestCard extends StatelessWidget {
  const IncomingRequestCard({
    required this.request,
    required this.onViewRequest,
    super.key,
  });

  final IncomingServiceRequest request;
  final VoidCallback onViewRequest;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onViewRequest,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.customerName,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          request.serviceCategory,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  RequestStatusBadge(status: request.status),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                request.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 14,
                runSpacing: 7,
                children: [
                  _RequestMetadata(
                    icon: Icons.location_on_outlined,
                    label: request.location,
                  ),
                  _RequestMetadata(
                    icon: Icons.schedule_outlined,
                    label: request.timing.label,
                  ),
                  _RequestMetadata(
                    icon: Icons.history_rounded,
                    label: request.relativeDate,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onViewRequest,
                child: const Text('Ver solicitud'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestMetadata extends StatelessWidget {
  const _RequestMetadata({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
        ),
      ],
    );
  }
}
