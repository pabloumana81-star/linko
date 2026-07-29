import 'package:flutter/material.dart';
import 'package:linko/core/utils/schedule_date_formatter.dart';
import 'package:linko/features/home/presentation/widgets/conversation_widgets.dart';
import 'package:linko/features/requests/domain/models/conversation_message.dart';
import 'package:linko/features/requests/domain/models/request_state.dart';
import 'package:linko/features/requests/domain/services/request_state_machine.dart';

enum ConversationPerspective { customer, professional }

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({
    required this.requestId,
    required this.counterpartName,
    required this.serviceName,
    required this.requestStatus,
    required this.perspective,
    required this.initialMessages,
    this.onSendMessage,
    this.onProposeSchedule,
    this.onConfirmSchedule,
    this.onRequestScheduleChange,
    this.onConfirmJob,
    this.onReportProblem,
    this.onBack,
    super.key,
  });

  final String requestId;
  final String counterpartName;
  final String serviceName;
  final RequestStatus requestStatus;
  final ConversationPerspective perspective;
  final List<ConversationMessage> initialMessages;
  final ValueChanged<String>? onSendMessage;
  final ValueChanged<String>? onProposeSchedule;
  final ValueChanged<String>? onConfirmSchedule;
  final ValueChanged<String>? onRequestScheduleChange;
  final VoidCallback? onConfirmJob;
  final VoidCallback? onReportProblem;
  final VoidCallback? onBack;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  late final List<ConversationMessage> _messages;
  late RequestStatus _requestStatus;

  @override
  void initState() {
    super.initState();
    _messages = List.of(
      widget.initialMessages.where(
        (message) => message.requestId == widget.requestId,
      ),
    );
    _requestStatus = widget.requestStatus;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void didUpdateWidget(covariant ConversationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.requestStatus != widget.requestStatus) {
      _requestStatus = widget.requestStatus;
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animated = false}) {
    if (!_scrollController.hasClients) {
      return;
    }
    final target = _scrollController.position.maxScrollExtent;
    if (animated) {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(target);
    }
  }

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      return;
    }
    widget.onSendMessage?.call(text);
    setState(() {
      _messages.add(
        ConversationMessage(
          id: '${widget.requestId}-local-${_messages.length}',
          requestId: widget.requestId,
          author: widget.perspective == ConversationPerspective.customer
              ? MessageAuthor.customer
              : MessageAuthor.professional,
          text: text,
          timeLabel: 'Ahora',
        ),
      );
      _inputController.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollToBottom(animated: true),
    );
  }

  Future<void> _proposeSchedule() async {
    final now = DateUtils.dateOnly(DateTime.now());
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      locale: const Locale('es', 'CR'),
    );
    if (date == null || !mounted) {
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null || !mounted) {
      return;
    }
    final scheduledAt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    final presentation = ScheduleDateFormatter.format(scheduledAt);
    final label = '${presentation.dateLabel}\n${presentation.timeLabel}';
    widget.onProposeSchedule?.call(label);
    setState(() {
      _messages.add(
        ConversationMessage(
          id: '${widget.requestId}-local-schedule-${_messages.length}',
          requestId: widget.requestId,
          author: MessageAuthor.professional,
          text: 'El profesional propuso una fecha para el trabajo.',
          timeLabel: 'Ahora',
          type: ConversationMessageType.scheduleProposal,
          scheduleLabel: label,
          scheduleStatus: ScheduleProposalStatus.pending,
        ),
      );
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollToBottom(animated: true),
    );
  }

  void _updateSchedule(
    ConversationMessage message,
    ScheduleProposalStatus status,
  ) {
    if (message.scheduleStatus != ScheduleProposalStatus.pending ||
        (status == ScheduleProposalStatus.confirmed &&
            _requestStatus != RequestState.accepted)) {
      return;
    }
    if (status == ScheduleProposalStatus.confirmed) {
      widget.onConfirmSchedule?.call(message.id);
    } else {
      widget.onRequestScheduleChange?.call(message.id);
    }
    setState(() {
      final index = _messages.indexWhere((item) => item.id == message.id);
      _messages[index] = message.copyWith(scheduleStatus: status);
      if (status == ScheduleProposalStatus.confirmed) {
        _requestStatus = RequestState.scheduled;
      }
      _messages.add(
        ConversationMessage(
          id: '${widget.requestId}-local-schedule-status-${_messages.length}',
          requestId: widget.requestId,
          author: MessageAuthor.system,
          text: status == ScheduleProposalStatus.confirmed
              ? 'El cliente confirmó la fecha del trabajo.'
              : 'El cliente solicitó cambiar la fecha del trabajo.',
          timeLabel: 'Ahora',
          type: ConversationMessageType.system,
        ),
      );
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollToBottom(animated: true),
    );
  }

  void _confirmJob() {
    if (_requestStatus != RequestState.pendingCustomerConfirmation) {
      return;
    }
    widget.onConfirmJob?.call();
    setState(() {
      _requestStatus = RequestState.completed;
      _messages.add(
        ConversationMessage(
          id: '${widget.requestId}-local-job-confirmed',
          requestId: widget.requestId,
          author: MessageAuthor.system,
          text: 'El cliente confirmó el trabajo completado.',
          timeLabel: 'Ahora',
          type: ConversationMessageType.system,
        ),
      );
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollToBottom(animated: true),
    );
  }

  void _reportProblem() {
    widget.onReportProblem?.call();
    setState(() {
      _messages.add(
        ConversationMessage(
          id: '${widget.requestId}-local-completed-work-problem',
          requestId: widget.requestId,
          author: MessageAuthor.system,
          text: 'El cliente reportó un problema con el trabajo realizado.',
          timeLabel: 'Ahora',
          type: ConversationMessageType.system,
        ),
      );
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollToBottom(animated: true),
    );
  }

  bool _isCurrentUser(ConversationMessage message) {
    return switch (widget.perspective) {
      ConversationPerspective.customer =>
        message.author == MessageAuthor.customer,
      ConversationPerspective.professional =>
        message.author == MessageAuthor.professional,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: widget.onBack == null
            ? null
            : BackButton(onPressed: widget.onBack),
        title: const Text('Conversación'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: colors.surface,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: colors.primaryContainer,
                      foregroundColor: colors.onPrimaryContainer,
                      child: Text(_initials(widget.counterpartName)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.counterpartName,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${widget.serviceName} · '
                            '${widget.perspective == ConversationPerspective.customer ? _requestStatus.customerLabel : _requestStatus.professionalLabel}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: colors.tertiary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'En línea',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(color: colors.tertiary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListView.builder(
                  key: const ValueKey('conversation-message-list'),
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: _messages.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return const DateDivider(label: 'Hoy');
                    }
                    final message = _messages[index - 1];
                    final child =
                        message.type == ConversationMessageType.jobCompleted
                        ? JobCompletedActionCard(
                            message: message,
                            requestStatus: _requestStatus,
                            isCustomer:
                                widget.perspective ==
                                ConversationPerspective.customer,
                            onConfirm: _confirmJob,
                            onReportProblem: _reportProblem,
                          )
                        : message.type == ConversationMessageType.workStarted
                        ? WorkStartedActionCard(message: message)
                        : message.type ==
                              ConversationMessageType.scheduleProposal
                        ? ActionCard(
                            message: message,
                            requestStatus: _requestStatus,
                            isCustomer:
                                widget.perspective ==
                                ConversationPerspective.customer,
                            onConfirm: () => _updateSchedule(
                              message,
                              ScheduleProposalStatus.confirmed,
                            ),
                            onRequestChange: () => _updateSchedule(
                              message,
                              ScheduleProposalStatus.changeRequested,
                            ),
                          )
                        : message.author == MessageAuthor.system
                        ? SystemMessage(message: message)
                        : MessageBubble(
                            message: message,
                            isCurrentUser: _isCurrentUser(message),
                          );
                    return KeyedSubtree(
                      key: index == _messages.length
                          ? const ValueKey('conversation-last-message')
                          : ValueKey(message.id),
                      child: child,
                    );
                  },
                ),
              ),
            ),
          ),
          if (widget.perspective == ConversationPerspective.professional &&
              RequestStateMachine.allows(
                _requestStatus,
                RequestActor.professional,
                RequestAction.proposeSchedule,
              ))
            ScheduleComposerCard(onPropose: _proposeSchedule),
          ChatInput(controller: _inputController, onSend: _sendMessage),
        ],
      ),
    );
  }

  String _initials(String name) {
    return name
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((part) => part[0])
        .join();
  }
}
