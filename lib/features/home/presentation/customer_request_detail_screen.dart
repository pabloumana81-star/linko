import 'package:flutter/material.dart';
import 'package:linko/core/utils/schedule_date_formatter.dart';
import 'package:linko/features/home/presentation/models/customer_service_request.dart';
import 'package:linko/features/home/presentation/widgets/request_section_title.dart';
import 'package:linko/features/home/presentation/widgets/request_summary_item.dart';
import 'package:linko/features/home/presentation/widgets/request_timeline.dart';
import 'package:linko/features/requests/domain/models/timeline_event.dart';
import 'package:linko/features/requests/domain/services/request_state_machine.dart';

class CustomerRequestDetailScreen extends StatelessWidget {
  const CustomerRequestDetailScreen({
    required this.request,
    required this.onBack,
    required this.onOpenConversation,
    this.onViewQuotation,
    this.timelineEvents = const [],
    this.scheduledDateLabel,
    this.onSubmitRating,
    super.key,
  });

  final CustomerServiceRequest request;
  final VoidCallback onBack;
  final VoidCallback onOpenConversation;
  final VoidCallback? onViewQuotation;
  final List<TimelineEvent> timelineEvents;
  final String? scheduledDateLabel;
  final void Function(int stars, String? comment)? onSubmitRating;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: onBack),
          title: const Text('Detalle de solicitud'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Resumen'),
              Tab(text: 'Conversación'),
              Tab(text: 'Seguimiento'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _RequestSummary(
              request: request,
              onViewQuotation: onViewQuotation,
              onOpenConversation: onOpenConversation,
              scheduledDateLabel: scheduledDateLabel,
              onSubmitRating: onSubmitRating,
            ),
            _ConversationAccess(
              professionalName: request.professionalName,
              onOpenConversation: onOpenConversation,
              canOpenConversation: request.status.definition.customerActions
                  .contains(RequestAction.openConversation),
            ),
            _TrackingTab(request: request, events: timelineEvents),
          ],
        ),
      ),
    );
  }
}

class _RequestSummary extends StatefulWidget {
  const _RequestSummary({
    required this.request,
    required this.onViewQuotation,
    required this.onOpenConversation,
    required this.scheduledDateLabel,
    required this.onSubmitRating,
  });

  final CustomerServiceRequest request;
  final VoidCallback? onViewQuotation;
  final VoidCallback onOpenConversation;
  final String? scheduledDateLabel;
  final void Function(int stars, String? comment)? onSubmitRating;

  @override
  State<_RequestSummary> createState() => _RequestSummaryState();
}

class _RequestSummaryState extends State<_RequestSummary> {
  bool _showRatingForm = false;

  @override
  void didUpdateWidget(covariant _RequestSummary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.request.status.definition.customerActions.contains(
      RequestAction.rateService,
    )) {
      _showRatingForm = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final schedule = widget.scheduledDateLabel == null
        ? null
        : ScheduleDateFormatter.fromStoredLabel(widget.scheduledDateLabel!);
    final action = _actionForStatus(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
      children: [
        Center(
          child: Icon(
            widget.request.categoryIcon,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 20),
        const RequestSectionTitle(label: 'Resumen de la solicitud'),
        const SizedBox(height: 4),
        RequestSummaryItem(
          icon: Icons.person_outline_rounded,
          label: 'Profesional',
          value: widget.request.professionalName,
        ),
        RequestSummaryItem(
          icon: Icons.home_repair_service_outlined,
          label: 'Servicio solicitado · Ubicación',
          value: '${widget.request.serviceName} · ${widget.request.location}',
        ),
        RequestSummaryItem(
          icon: Icons.info_outline_rounded,
          label: 'Estado actual',
          value: widget.request.status.customerLabel,
        ),
        if (schedule != null)
          RequestSummaryItem(
            icon: Icons.calendar_month_outlined,
            label: 'Fecha programada',
            value: schedule.timeLabel.isEmpty
                ? schedule.dateLabel
                : '${schedule.dateLabel}\n${schedule.timeLabel}',
          ),
        RequestSummaryItem(
          icon: Icons.arrow_forward_rounded,
          label: 'Siguiente paso',
          value: widget.request.status.definition.nextStep,
          showDivider: false,
        ),
        if (action != null) ...[
          const SizedBox(height: 20),
          Center(
            child: FilledButton.icon(
              onPressed: action.onPressed,
              icon: Icon(action.icon),
              label: Text(action.label),
            ),
          ),
        ],
        if (_showRatingForm && widget.onSubmitRating != null) ...[
          const SizedBox(height: 24),
          _ServiceRatingForm(onSubmit: widget.onSubmitRating!),
        ],
      ],
    );
  }

  _SummaryAction? _actionForStatus(BuildContext context) {
    final action = widget.request.status.definition.customerPrimaryAction;
    if (action == null) {
      return null;
    }
    return switch (action) {
      RequestAction.viewQuotation when widget.onViewQuotation != null =>
        _SummaryAction(
          label: action.label,
          icon: Icons.receipt_long_outlined,
          onPressed: widget.onViewQuotation!,
        ),
      RequestAction.viewSchedule => _SummaryAction(
        label: action.label,
        icon: Icons.calendar_month_outlined,
        onPressed: () => DefaultTabController.of(context).animateTo(2),
      ),
      RequestAction.viewProgress => _SummaryAction(
        label: action.label,
        icon: Icons.timeline_rounded,
        onPressed: () => DefaultTabController.of(context).animateTo(2),
      ),
      RequestAction.openConversation => _SummaryAction(
        label: action.label,
        icon: Icons.chat_bubble_outline_rounded,
        onPressed: widget.onOpenConversation,
      ),
      RequestAction.rateService => _SummaryAction(
        label: action.label,
        icon: Icons.star_outline_rounded,
        onPressed: () {
          setState(() {
            _showRatingForm = true;
          });
        },
      ),
      _ => null,
    };
  }
}

class _ServiceRatingForm extends StatefulWidget {
  const _ServiceRatingForm({required this.onSubmit});

  final void Function(int stars, String? comment) onSubmit;

  @override
  State<_ServiceRatingForm> createState() => _ServiceRatingFormState();
}

class _ServiceRatingFormState extends State<_ServiceRatingForm> {
  final _commentController = TextEditingController();
  int _stars = 0;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '¿Cómo fue el servicio?',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var star = 1; star <= 5; star++)
              IconButton(
                key: ValueKey('rating-star-$star'),
                tooltip: '$star estrellas',
                onPressed: () {
                  setState(() {
                    _stars = star;
                  });
                },
                icon: Icon(
                  star <= _stars
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('rating-comment'),
          controller: _commentController,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Comentario (opcional)',
            hintText: 'Cuéntanos cómo fue tu experiencia',
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          key: const ValueKey('submit-rating'),
          onPressed: _stars == 0
              ? null
              : () {
                  final comment = _commentController.text.trim();
                  widget.onSubmit(_stars, comment.isEmpty ? null : comment);
                },
          child: const Text('Enviar calificación'),
        ),
      ],
    );
  }
}

class _SummaryAction {
  const _SummaryAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
}

class _ConversationAccess extends StatelessWidget {
  const _ConversationAccess({
    required this.professionalName,
    required this.onOpenConversation,
    required this.canOpenConversation,
  });

  final String professionalName;
  final VoidCallback onOpenConversation;
  final bool canOpenConversation;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 14),
            Text(
              'Conversación con $professionalName',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (canOpenConversation) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onOpenConversation,
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                label: Text(RequestAction.openConversation.label),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrackingTab extends StatelessWidget {
  const _TrackingTab({required this.request, required this.events});

  final CustomerServiceRequest request;
  final List<TimelineEvent> events;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('request-tracking-list'),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
      children: [
        Text(
          'Seguimiento del trabajo',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 24),
        RequestTimeline(requestStatus: request.status, events: events),
      ],
    );
  }
}
