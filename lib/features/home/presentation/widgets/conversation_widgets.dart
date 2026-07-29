import 'package:flutter/material.dart';
import 'package:linko/core/utils/schedule_date_formatter.dart';
import 'package:linko/features/requests/domain/models/conversation_message.dart';
import 'package:linko/features/requests/domain/models/request_state.dart';
import 'package:linko/features/requests/domain/services/request_state_machine.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    required this.message,
    required this.isCurrentUser,
    super.key,
  });

  final ConversationMessage message;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        decoration: BoxDecoration(
          color: isCurrentUser
              ? colors.primaryContainer
              : colors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isCurrentUser
                    ? colors.onPrimaryContainer
                    : colors.onSurface,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.timeLabel,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class SystemMessage extends StatelessWidget {
  const SystemMessage({required this.message, super.key});

  final ConversationMessage message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: colors.secondaryContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            message.text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class DateDivider extends StatelessWidget {
  const DateDivider({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

class ActionCard extends StatelessWidget {
  const ActionCard({
    required this.message,
    required this.requestStatus,
    required this.isCustomer,
    required this.onConfirm,
    required this.onRequestChange,
    super.key,
  });

  final ConversationMessage message;
  final RequestStatus requestStatus;
  final bool isCustomer;
  final VoidCallback onConfirm;
  final VoidCallback onRequestChange;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final status = message.scheduleStatus ?? ScheduleProposalStatus.pending;
    final canConfirm = RequestStateMachine.allows(
      requestStatus,
      RequestActor.customer,
      RequestAction.confirmSchedule,
    );
    final canRequestChange = RequestStateMachine.allows(
      requestStatus,
      RequestActor.customer,
      RequestAction.requestScheduleChange,
    );
    final schedule = ScheduleDateFormatter.fromStoredLabel(
      message.scheduleLabel!,
    );
    return Container(
      key: ValueKey('schedule-action-${message.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.event_available_outlined, color: colors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  status == ScheduleProposalStatus.confirmed
                      ? 'Trabajo programado'
                      : 'Propuesta de programación',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            schedule.dateLabel,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (schedule.timeLabel.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              schedule.timeLabel,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 8),
          if (status == ScheduleProposalStatus.pending &&
              isCustomer &&
              (canConfirm || canRequestChange)) ...[
            if (canConfirm)
              FilledButton(
                key: ValueKey('confirm-schedule-${message.id}'),
                onPressed: onConfirm,
                child: Text(RequestAction.confirmSchedule.label),
              ),
            if (canRequestChange)
              TextButton(
                onPressed: onRequestChange,
                child: Text(RequestAction.requestScheduleChange.label),
              ),
          ] else
            Row(
              children: [
                if (status == ScheduleProposalStatus.confirmed) ...[
                  Icon(Icons.check_rounded, size: 18, color: colors.tertiary),
                  const SizedBox(width: 5),
                ],
                Text(
                  switch (status) {
                    ScheduleProposalStatus.pending => 'Esperando confirmación',
                    ScheduleProposalStatus.confirmed =>
                      'Confirmado por el cliente',
                    ScheduleProposalStatus.changeRequested =>
                      'Cambio de fecha solicitado',
                  },
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: status == ScheduleProposalStatus.confirmed
                        ? colors.tertiary
                        : colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class WorkStartedActionCard extends StatelessWidget {
  const WorkStartedActionCard({required this.message, super.key});

  final ConversationMessage message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('work-started-action-card'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.primary),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.build_rounded, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trabajo iniciado',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  message.text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class JobCompletedActionCard extends StatelessWidget {
  const JobCompletedActionCard({
    required this.message,
    required this.requestStatus,
    required this.isCustomer,
    required this.onConfirm,
    required this.onReportProblem,
    super.key,
  });

  final ConversationMessage message;
  final RequestStatus requestStatus;
  final bool isCustomer;
  final VoidCallback onConfirm;
  final VoidCallback onReportProblem;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final actions = requestStatus.definition.customerActions;
    final canConfirm = isCustomer && actions.contains(RequestAction.confirmJob);
    final canReport =
        isCustomer && actions.contains(RequestAction.reportProblem);
    return Container(
      key: const ValueKey('job-completed-action-card'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.task_alt_rounded, color: colors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Trabajo completado',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message.text,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.onPrimaryContainer),
          ),
          if (canConfirm || canReport) ...[
            const SizedBox(height: 12),
            if (canConfirm)
              FilledButton(
                key: const ValueKey('confirm-job'),
                onPressed: onConfirm,
                child: Text(RequestAction.confirmJob.label),
              ),
            if (canReport)
              TextButton(
                onPressed: onReportProblem,
                child: Text(RequestAction.reportProblem.label),
              ),
          ],
        ],
      ),
    );
  }
}

class ScheduleComposerCard extends StatelessWidget {
  const ScheduleComposerCard({required this.onPropose, super.key});

  final VoidCallback onPropose;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: OutlinedButton.icon(
        key: const ValueKey('propose-schedule'),
        onPressed: onPropose,
        icon: const Icon(Icons.calendar_month_outlined),
        label: const Text('Proponer fecha y hora'),
      ),
    );
  }
}

class ChatInput extends StatelessWidget {
  const ChatInput({required this.controller, required this.onSend, super.key});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('conversation-input'),
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  decoration: const InputDecoration(
                    hintText: 'Escribe un mensaje',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                key: const ValueKey('conversation-send'),
                tooltip: 'Enviar',
                onPressed: onSend,
                icon: const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
