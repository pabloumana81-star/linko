import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko/core/backend/backend_config.dart';
import 'package:linko/core/backend/backend_providers.dart';
import 'package:linko/core/diagnostics/diagnostics_service.dart';
import 'package:linko/features/requests/domain/models/quotation.dart';
import 'package:linko/features/requests/domain/models/request_state.dart';
import 'package:linko/features/requests/domain/models/service_rating.dart';
import 'package:linko/features/requests/domain/models/service_request.dart';
import 'package:linko/features/requests/presentation/providers/request_providers.dart';

class RequestWorkflowController {
  const RequestWorkflowController(this.ref);

  final Ref ref;

  bool get _isMock =>
      ref.read(backendRepositoriesProvider).mode == BackendMode.mock;

  DiagnosticsService get _diagnostics => ref.read(diagnosticsServiceProvider);

  Future<ServiceRequest> _request(String requestId) async {
    final request = _isMock
        ? ref.read(requestRepositoryProvider).getRequestById(requestId)
        : await ref
              .read(activeServiceRequestsRepositoryProvider)
              .getRequestById(requestId);
    if (request == null) {
      throw StateError('No se encontró la solicitud $requestId.');
    }
    return request;
  }

  void _log(
    WorkflowEventType type,
    ServiceRequest request,
    RequestState? previousState,
    RequestState newState,
  ) {
    _diagnostics.workflow(
      type: type,
      requestId: request.id,
      customerId: request.customer.id,
      professionalId: request.professional.user.id,
      previousState: previousState,
      newState: newState,
    );
  }

  void _refresh(String requestId) {
    ref
      ..invalidate(persistedCustomerRequestsProvider)
      ..invalidate(persistedProfessionalRequestsProvider)
      ..invalidate(persistedRequestDetailProvider(requestId))
      ..invalidate(customerRequestsProvider)
      ..invalidate(professionalRequestsProvider)
      ..invalidate(requestDetailProvider(requestId))
      ..invalidate(conversationProvider(requestId))
      ..invalidate(timelineProvider(requestId));
  }

  Future<void> createQuotation(Quotation quotation) async {
    await _diagnostics.guard('quote_sent', () async {
      final request = await _request(quotation.requestId);
      if (_isMock) {
        ref.read(requestRepositoryProvider).sendQuotation(quotation);
      } else {
        await ref
            .read(activeQuotationsRepositoryProvider)
            .sendQuotation(quotation);
      }
      _refresh(quotation.requestId);
      _log(
        WorkflowEventType.quoteSent,
        request,
        request.state,
        RequestState.quoted,
      );
    });
  }

  void recordQuotationSent(String requestId, RequestState previousState) {
    final request = ref
        .read(requestRepositoryProvider)
        .getRequestById(requestId);
    if (request == null) return;
    _log(
      WorkflowEventType.quoteSent,
      request,
      previousState,
      RequestState.quoted,
    );
  }

  Future<void> acceptQuotation(String requestId) async {
    await _diagnostics.guard('quote_accepted', () async {
      final request = await _request(requestId);
      if (_isMock) {
        ref.read(requestRepositoryProvider).acceptQuotation(requestId);
      } else {
        await ref
            .read(activeQuotationsRepositoryProvider)
            .acceptQuotation(requestId);
      }
      _refresh(requestId);
      _log(
        WorkflowEventType.quoteAccepted,
        request,
        request.state,
        RequestState.accepted,
      );
    });
  }

  Future<void> rejectQuotation(String requestId) async {
    await _diagnostics.guard('quote_rejected', () async {
      await ref
          .read(activeQuotationsRepositoryProvider)
          .rejectQuotation(requestId);
      _refresh(requestId);
    });
  }

  Future<void> rejectRequest(String requestId) async {
    await _diagnostics.guard('request_rejected', () async {
      if (_isMock) {
        ref
            .read(requestRepositoryProvider)
            .updateStatus(requestId, RequestState.cancelled);
      } else {
        await ref
            .read(activeServiceRequestsRepositoryProvider)
            .updateStatus(requestId, RequestState.cancelled);
      }
      _refresh(requestId);
    });
  }

  Future<void> proposeSchedule(String requestId, String scheduleLabel) async {
    await _diagnostics.guard('schedule_proposed', () async {
      final request = await _request(requestId);
      if (_isMock) {
        ref
            .read(requestRepositoryProvider)
            .proposeSchedule(requestId, scheduleLabel);
      } else {
        await ref
            .read(activeServiceRequestsRepositoryProvider)
            .appendEvent(
              requestId: requestId,
              eventType: 'schedule_proposed',
              payload: {'schedule_label': scheduleLabel},
            );
      }
      _refresh(requestId);
      _log(
        WorkflowEventType.scheduleProposed,
        request,
        request.state,
        request.state,
      );
    });
  }

  Future<void> acceptSchedule(String requestId, String messageId) async {
    await _diagnostics.guard('schedule_confirmed', () async {
      final request = await _request(requestId);
      if (_isMock) {
        ref
            .read(requestRepositoryProvider)
            .confirmSchedule(requestId, messageId);
      } else {
        await ref
            .read(activeServiceRequestsRepositoryProvider)
            .transitionStatus(
              requestId: requestId,
              nextStatus: RequestState.scheduled,
              eventType: 'schedule_accepted',
            );
      }
      _refresh(requestId);
      _log(
        WorkflowEventType.scheduleConfirmed,
        request,
        request.state,
        RequestState.scheduled,
      );
    });
  }

  Future<void> startWork(String requestId) async {
    await _diagnostics.guard('work_started', () async {
      final request = await _request(requestId);
      if (_isMock) {
        ref.read(requestRepositoryProvider).startJob(requestId);
      } else {
        await ref
            .read(activeServiceRequestsRepositoryProvider)
            .transitionStatus(
              requestId: requestId,
              nextStatus: RequestState.inProgress,
              eventType: 'work_started',
            );
      }
      _refresh(requestId);
      _log(
        WorkflowEventType.workStarted,
        request,
        request.state,
        RequestState.inProgress,
      );
    });
  }

  Future<void> completeWork(String requestId) async {
    await _diagnostics.guard('work_completed', () async {
      final request = await _request(requestId);
      if (_isMock) {
        ref.read(requestRepositoryProvider).markJobCompleted(requestId);
      } else {
        await ref
            .read(activeServiceRequestsRepositoryProvider)
            .transitionStatus(
              requestId: requestId,
              nextStatus: RequestState.pendingCustomerConfirmation,
              eventType: 'work_completed',
            );
      }
      _refresh(requestId);
      _log(
        WorkflowEventType.workCompleted,
        request,
        request.state,
        RequestState.pendingCustomerConfirmation,
      );
    });
  }

  Future<void> requestRating(String requestId) async {
    await _diagnostics.guard('completion_confirmed', () async {
      if (_isMock) {
        ref.read(requestRepositoryProvider).confirmJob(requestId);
      } else {
        await ref
            .read(activeServiceRequestsRepositoryProvider)
            .transitionStatus(
              requestId: requestId,
              nextStatus: RequestState.completed,
              eventType: 'rating_requested',
            );
      }
      _refresh(requestId);
    });
  }

  Future<void> createRequest(ServiceRequest request) async {
    await _diagnostics.guard('request_created', () async {
      await ref
          .read(activeServiceRequestsRepositoryProvider)
          .createRequest(request);
      _refresh(request.id);
      _log(
        WorkflowEventType.requestCreated,
        request,
        null,
        RequestState.pending,
      );
      _log(
        WorkflowEventType.professionalAssigned,
        request,
        RequestState.pending,
        RequestState.pending,
      );
    });
  }

  Future<void> submitRating(ServiceRating rating) async {
    await _diagnostics.guard('rating_submitted', () async {
      final request = await _request(rating.requestId);
      if (_isMock) {
        ref.read(requestRepositoryProvider).submitRating(rating);
      } else {
        await ref.read(ratingsRepositoryProvider).submitRating(rating);
      }
      _refresh(rating.requestId);
      ref.invalidate(ratingProvider(rating.requestId));
      ref.invalidate(
        professionalRatingSummaryProvider(request.professional.user.id),
      );
      _log(
        WorkflowEventType.ratingSubmitted,
        request,
        request.state,
        RequestState.reviewed,
      );
    });
  }
}

final requestWorkflowControllerProvider = Provider<RequestWorkflowController>(
  RequestWorkflowController.new,
);
