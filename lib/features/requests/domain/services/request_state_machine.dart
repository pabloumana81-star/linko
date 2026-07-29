import 'package:linko/features/requests/domain/models/request_state.dart';
import 'package:linko/features/requests/domain/models/timeline_event.dart';

enum RequestActor { customer, professional }

enum RequestAction {
  viewQuotation,
  acceptQuotation,
  requestQuotationChanges,
  sendQuotation,
  rejectRequest,
  openConversation,
  proposeSchedule,
  confirmSchedule,
  requestScheduleChange,
  viewSchedule,
  startJob,
  markJobCompleted,
  confirmJob,
  reportProblem,
  rateService,
  viewProgress,
  viewSummary,
}

extension RequestActionLabel on RequestAction {
  String get label => switch (this) {
    RequestAction.viewQuotation => 'Ver cotización',
    RequestAction.acceptQuotation => 'Aceptar cotización',
    RequestAction.requestQuotationChanges => 'Solicitar cambios',
    RequestAction.sendQuotation => 'Enviar cotización',
    RequestAction.rejectRequest => 'Rechazar solicitud',
    RequestAction.openConversation => 'Abrir conversación',
    RequestAction.proposeSchedule => 'Proponer fecha y hora',
    RequestAction.confirmSchedule => 'Confirmar fecha',
    RequestAction.requestScheduleChange => 'Solicitar cambio',
    RequestAction.viewSchedule => 'Ver programación',
    RequestAction.startJob => 'Iniciar trabajo',
    RequestAction.markJobCompleted => 'Marcar trabajo como completado',
    RequestAction.confirmJob => 'Confirmar trabajo',
    RequestAction.reportProblem => 'Reportar un problema',
    RequestAction.rateService => 'Calificar servicio',
    RequestAction.viewProgress => 'Ver progreso',
    RequestAction.viewSummary => 'Ver resumen',
  };
}

enum RequestStatusTone { primary, warning, secondary, success, error }

class RequestStateDefinition {
  const RequestStateDefinition({
    required this.customerLabel,
    required this.professionalLabel,
    required this.conversationLabel,
    required this.nextStep,
    required this.timelineStage,
    required this.tone,
    required this.customerActions,
    required this.professionalActions,
    required this.customerPrimaryAction,
    required this.professionalPrimaryAction,
    required this.allowedTransitions,
  });

  final String customerLabel;
  final String professionalLabel;
  final String conversationLabel;
  final String nextStep;
  final TimelineStage? timelineStage;
  final RequestStatusTone tone;
  final Set<RequestAction> customerActions;
  final Set<RequestAction> professionalActions;
  final RequestAction? customerPrimaryAction;
  final RequestAction? professionalPrimaryAction;
  final Set<RequestStatus> allowedTransitions;

  Set<RequestAction> actionsFor(RequestActor actor) =>
      actor == RequestActor.customer ? customerActions : professionalActions;

  RequestAction? primaryActionFor(RequestActor actor) =>
      actor == RequestActor.customer
      ? customerPrimaryAction
      : professionalPrimaryAction;
}

abstract final class RequestStateMachine {
  static RequestStateDefinition definition(RequestStatus status) =>
      _definitions[status]!;

  static bool canTransition(RequestStatus from, RequestStatus to) =>
      definition(from).allowedTransitions.contains(to);

  static void ensureTransition(RequestStatus from, RequestStatus to) {
    if (!canTransition(from, to)) {
      throw StateError(
        'Transición de solicitud inválida: ${from.name} -> ${to.name}',
      );
    }
  }

  static bool allows(
    RequestStatus status,
    RequestActor actor,
    RequestAction action,
  ) => definition(status).actionsFor(actor).contains(action);

  static const _definitions = <RequestStatus, RequestStateDefinition>{
    RequestState.pending: RequestStateDefinition(
      customerLabel: 'Esperando respuesta',
      professionalLabel: 'Nueva',
      conversationLabel: 'Pendiente',
      nextStep: 'Esperar la respuesta del profesional.',
      timelineStage: TimelineStage.requestSent,
      tone: RequestStatusTone.primary,
      customerActions: {},
      professionalActions: {
        RequestAction.sendQuotation,
        RequestAction.rejectRequest,
      },
      customerPrimaryAction: null,
      professionalPrimaryAction: RequestAction.sendQuotation,
      allowedTransitions: {
        RequestState.underReview,
        RequestState.quoted,
        RequestState.cancelled,
      },
    ),
    RequestState.underReview: RequestStateDefinition(
      customerLabel: 'En conversación',
      professionalLabel: 'En revisión',
      conversationLabel: 'En revisión',
      nextStep: 'El profesional está revisando la solicitud.',
      timelineStage: TimelineStage.professionalReviewing,
      tone: RequestStatusTone.warning,
      customerActions: {RequestAction.openConversation},
      professionalActions: {
        RequestAction.sendQuotation,
        RequestAction.rejectRequest,
      },
      customerPrimaryAction: RequestAction.openConversation,
      professionalPrimaryAction: RequestAction.sendQuotation,
      allowedTransitions: {RequestState.quoted, RequestState.cancelled},
    ),
    RequestState.quoted: RequestStateDefinition(
      customerLabel: 'Cotización recibida',
      professionalLabel: 'Cotizada',
      conversationLabel: 'Cotización recibida',
      nextStep: 'Revisar la cotización recibida.',
      timelineStage: TimelineStage.quotationSent,
      tone: RequestStatusTone.secondary,
      customerActions: {
        RequestAction.viewQuotation,
        RequestAction.acceptQuotation,
        RequestAction.requestQuotationChanges,
      },
      professionalActions: {
        RequestAction.viewQuotation,
        RequestAction.openConversation,
      },
      customerPrimaryAction: RequestAction.viewQuotation,
      professionalPrimaryAction: RequestAction.viewQuotation,
      allowedTransitions: {RequestState.accepted, RequestState.cancelled},
    ),
    RequestState.accepted: RequestStateDefinition(
      customerLabel: 'Cotización aceptada',
      professionalLabel: 'Cotización aceptada',
      conversationLabel: 'Cotización aceptada',
      nextStep: 'Coordinar la fecha del trabajo.',
      timelineStage: TimelineStage.quotationAccepted,
      tone: RequestStatusTone.success,
      customerActions: {
        RequestAction.openConversation,
        RequestAction.confirmSchedule,
        RequestAction.requestScheduleChange,
      },
      professionalActions: {
        RequestAction.openConversation,
        RequestAction.proposeSchedule,
      },
      customerPrimaryAction: RequestAction.openConversation,
      professionalPrimaryAction: RequestAction.proposeSchedule,
      allowedTransitions: {RequestState.scheduled, RequestState.cancelled},
    ),
    RequestState.scheduled: RequestStateDefinition(
      customerLabel: 'Trabajo programado',
      professionalLabel: 'Trabajo programado',
      conversationLabel: 'Trabajo programado',
      nextStep: 'Esperar que el profesional inicie el trabajo.',
      timelineStage: TimelineStage.workScheduled,
      tone: RequestStatusTone.secondary,
      customerActions: {
        RequestAction.viewSchedule,
        RequestAction.openConversation,
      },
      professionalActions: {
        RequestAction.viewSchedule,
        RequestAction.startJob,
        RequestAction.openConversation,
      },
      customerPrimaryAction: RequestAction.viewSchedule,
      professionalPrimaryAction: RequestAction.startJob,
      allowedTransitions: {RequestState.inProgress, RequestState.cancelled},
    ),
    RequestState.inProgress: RequestStateDefinition(
      customerLabel: 'En progreso',
      professionalLabel: 'En progreso',
      conversationLabel: 'En progreso',
      nextStep: 'Dar seguimiento al trabajo en curso.',
      timelineStage: TimelineStage.workInProgress,
      tone: RequestStatusTone.secondary,
      customerActions: {
        RequestAction.viewProgress,
        RequestAction.openConversation,
      },
      professionalActions: {
        RequestAction.markJobCompleted,
        RequestAction.openConversation,
      },
      customerPrimaryAction: RequestAction.viewProgress,
      professionalPrimaryAction: RequestAction.markJobCompleted,
      allowedTransitions: {
        RequestState.pendingCustomerConfirmation,
        RequestState.cancelled,
      },
    ),
    RequestState.pendingCustomerConfirmation: RequestStateDefinition(
      customerLabel: 'Pendiente de confirmación',
      professionalLabel: 'Pendiente de confirmación',
      conversationLabel: 'Pendiente de confirmación',
      nextStep: 'El cliente debe confirmar el trabajo completado.',
      timelineStage: TimelineStage.workCompleted,
      tone: RequestStatusTone.warning,
      customerActions: {
        RequestAction.openConversation,
        RequestAction.confirmJob,
        RequestAction.reportProblem,
      },
      professionalActions: {RequestAction.openConversation},
      customerPrimaryAction: RequestAction.openConversation,
      professionalPrimaryAction: RequestAction.openConversation,
      allowedTransitions: {RequestState.completed},
    ),
    RequestState.completed: RequestStateDefinition(
      customerLabel: 'Completado',
      professionalLabel: 'Completada',
      conversationLabel: 'Completada',
      nextStep: 'El trabajo ha sido completado.',
      timelineStage: TimelineStage.workCompleted,
      tone: RequestStatusTone.success,
      customerActions: {RequestAction.viewSummary, RequestAction.rateService},
      professionalActions: {RequestAction.viewSummary},
      customerPrimaryAction: RequestAction.rateService,
      professionalPrimaryAction: null,
      allowedTransitions: {RequestState.reviewed},
    ),
    RequestState.reviewed: RequestStateDefinition(
      customerLabel: 'Servicio calificado',
      professionalLabel: 'Servicio calificado',
      conversationLabel: 'Servicio calificado',
      nextStep: 'La calificación fue enviada correctamente.',
      timelineStage: TimelineStage.workCompleted,
      tone: RequestStatusTone.success,
      customerActions: {RequestAction.viewSummary},
      professionalActions: {RequestAction.viewSummary},
      customerPrimaryAction: null,
      professionalPrimaryAction: null,
      allowedTransitions: {},
    ),
    RequestState.cancelled: RequestStateDefinition(
      customerLabel: 'Cancelado',
      professionalLabel: 'Rechazada',
      conversationLabel: 'Cancelada',
      nextStep: 'Buscar otro profesional.',
      timelineStage: null,
      tone: RequestStatusTone.error,
      customerActions: {},
      professionalActions: {},
      customerPrimaryAction: null,
      professionalPrimaryAction: null,
      allowedTransitions: {},
    ),
  };
}

extension RequestStatusStateMachine on RequestStatus {
  RequestStateDefinition get definition => RequestStateMachine.definition(this);

  String get customerLabel => definition.customerLabel;
  String get professionalLabel => definition.professionalLabel;
  String get conversationLabel => definition.conversationLabel;
}
