import 'package:flutter/material.dart';
import 'package:linko/core/theme/linko_colors.dart';
import 'package:linko/features/requests/domain/models/request_state.dart';
import 'package:linko/features/requests/domain/services/request_state_machine.dart';

class RequestStatusBadge extends StatelessWidget {
  const RequestStatusBadge({required this.status, super.key})
    : _customerPerspective = false;

  const RequestStatusBadge.customer({required this.status, super.key})
    : _customerPerspective = true;

  final RequestState status;
  final bool _customerPerspective;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = switch (status.definition.tone) {
      RequestStatusTone.primary => colorScheme.primary,
      RequestStatusTone.warning => LinkoColors.warning,
      RequestStatusTone.secondary => colorScheme.secondary,
      RequestStatusTone.success => colorScheme.tertiary,
      RequestStatusTone.error => colorScheme.error,
    };
    final label = _customerPerspective
        ? status.customerLabel
        : status.professionalLabel;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
