import 'package:flutter/material.dart';
import 'package:linko/core/theme/linko_colors.dart';
import 'package:linko/features/home/presentation/models/request_status.dart';

class RequestStatusBadge extends StatelessWidget {
  const RequestStatusBadge({required this.status, super.key});

  final RequestStatus status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = switch (status) {
      RequestStatus.newRequest => colorScheme.primary,
      RequestStatus.underReview => LinkoColors.warning,
      RequestStatus.quoted => colorScheme.secondary,
      RequestStatus.accepted => colorScheme.tertiary,
      RequestStatus.rejected => colorScheme.error,
      RequestStatus.inProgress => colorScheme.secondary,
      RequestStatus.completed => colorScheme.tertiary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
