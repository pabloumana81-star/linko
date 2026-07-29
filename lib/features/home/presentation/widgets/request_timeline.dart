import 'package:flutter/material.dart';
import 'package:linko/features/home/presentation/models/request_progress_stage.dart';
import 'package:linko/features/requests/domain/models/request_state.dart';
import 'package:linko/features/requests/domain/models/timeline_event.dart';
import 'package:linko/features/requests/domain/services/request_state_machine.dart';

class RequestTimeline extends StatelessWidget {
  const RequestTimeline({
    required this.requestStatus,
    this.events = const [],
    super.key,
  });

  final RequestStatus requestStatus;
  final List<TimelineEvent> events;

  static const _descriptions = {
    RequestProgressStage.requestSent:
        'La solicitud fue enviada al profesional.',
    RequestProgressStage.professionalReviewing:
        'El profesional está revisando los detalles.',
    RequestProgressStage.quotationSent:
        'El profesional compartió una cotización.',
    RequestProgressStage.quotationAccepted:
        'La cotización fue aceptada por el cliente.',
    RequestProgressStage.workScheduled:
        'El trabajo tiene una fecha coordinada.',
    RequestProgressStage.workInProgress:
        'El profesional está realizando el trabajo.',
    RequestProgressStage.workCompleted:
        'El trabajo fue marcado como completado.',
  };

  static const _dates = {
    RequestProgressStage.requestSent: '24 jul, 9:10 a. m.',
    RequestProgressStage.professionalReviewing: '24 jul, 10:05 a. m.',
    RequestProgressStage.quotationSent: '24 jul, 2:30 p. m.',
    RequestProgressStage.quotationAccepted: '25 jul, 8:45 a. m.',
    RequestProgressStage.workScheduled: '26 jul, 11:00 a. m.',
    RequestProgressStage.workInProgress: 'Pendiente',
    RequestProgressStage.workCompleted: 'Pendiente',
  };

  @override
  Widget build(BuildContext context) {
    final activeIndex =
        requestStatus.definition.timelineStage?.index ??
        TimelineStage.requestSent.index;
    return Column(
      children: [
        for (var index = 0; index < RequestProgressStage.values.length; index++)
          TimelineStep(
            stage: RequestProgressStage.values[index],
            dateLabel:
                _eventFor(index)?.dateLabel ??
                _dates[RequestProgressStage.values[index]]!,
            description:
                _eventFor(index)?.description ??
                _descriptions[RequestProgressStage.values[index]]!,
            state: index < activeIndex
                ? TimelineStepState.completed
                : index == activeIndex
                ? TimelineStepState.active
                : TimelineStepState.pending,
            isLast: index == RequestProgressStage.values.length - 1,
          ),
      ],
    );
  }

  TimelineEvent? _eventFor(int stageIndex) {
    for (final event in events) {
      if (event.stage.index == stageIndex) {
        return event;
      }
    }
    return null;
  }
}

class TimelineStep extends StatelessWidget {
  const TimelineStep({
    required this.stage,
    required this.dateLabel,
    required this.description,
    required this.state,
    required this.isLast,
    super.key,
  });

  final RequestProgressStage stage;
  final String dateLabel;
  final String description;
  final TimelineStepState state;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final pending = state == TimelineStepState.pending;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 36,
            child: Column(
              children: [
                TimelineStatusIcon(
                  key: ValueKey('timeline-${stage.name}-${state.name}'),
                  state: state,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: state == TimelineStepState.completed
                          ? colors.primary
                          : colors.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stage.label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: pending
                          ? colors.onSurfaceVariant
                          : colors.onSurface,
                      fontWeight: state == TimelineStepState.active
                          ? FontWeight.w700
                          : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    dateLabel,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: pending ? colors.outline : colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TimelineStatusIcon extends StatelessWidget {
  const TimelineStatusIcon({required this.state, super.key});

  final TimelineStepState state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isPending = state == TimelineStepState.pending;
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isPending ? colors.surface : colors.primary,
        border: isPending ? Border.all(color: colors.outline) : null,
      ),
      child: switch (state) {
        TimelineStepState.completed => Icon(
          Icons.check_rounded,
          size: 19,
          color: colors.onPrimary,
        ),
        TimelineStepState.active => Center(
          child: Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.onPrimary,
            ),
          ),
        ),
        TimelineStepState.pending => null,
      },
    );
  }
}
