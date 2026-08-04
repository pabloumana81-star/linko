import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko/core/backend/backend_config.dart';
import 'package:linko/core/backend/backend_providers.dart';
import 'package:linko/features/requests/domain/models/quotation.dart';
import 'package:linko/features/requests/domain/models/request_state.dart';
import 'package:linko/features/requests/presentation/providers/request_providers.dart';

class RequestWorkflowController {
  const RequestWorkflowController(this.ref);

  final Ref ref;

  bool get _isMock =>
      ref.read(backendRepositoriesProvider).mode == BackendMode.mock;

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
    if (_isMock) {
      ref.read(requestRepositoryProvider).sendQuotation(quotation);
      _refresh(quotation.requestId);
      return;
    }
    await ref.read(activeQuotationsRepositoryProvider).sendQuotation(quotation);
    _refresh(quotation.requestId);
  }

  Future<void> acceptQuotation(String requestId) async {
    if (_isMock) {
      ref.read(requestRepositoryProvider).acceptQuotation(requestId);
      _refresh(requestId);
      return;
    }
    await ref
        .read(activeQuotationsRepositoryProvider)
        .acceptQuotation(requestId);
    _refresh(requestId);
  }

  Future<void> rejectQuotation(String requestId) async {
    if (_isMock) {
      await ref
          .read(activeQuotationsRepositoryProvider)
          .rejectQuotation(requestId);
      _refresh(requestId);
      return;
    }
    await ref
        .read(activeQuotationsRepositoryProvider)
        .rejectQuotation(requestId);
    _refresh(requestId);
  }

  Future<void> rejectRequest(String requestId) async {
    if (_isMock) {
      ref
          .read(requestRepositoryProvider)
          .updateStatus(requestId, RequestState.cancelled);
      _refresh(requestId);
      return;
    }
    await ref
        .read(activeServiceRequestsRepositoryProvider)
        .updateStatus(requestId, RequestState.cancelled);
    _refresh(requestId);
  }

  Future<void> proposeSchedule(String requestId, String scheduleLabel) async {
    if (_isMock) {
      ref
          .read(requestRepositoryProvider)
          .proposeSchedule(requestId, scheduleLabel);
      _refresh(requestId);
      return;
    }
    await ref
        .read(activeServiceRequestsRepositoryProvider)
        .appendEvent(
          requestId: requestId,
          eventType: 'schedule_proposed',
          payload: {'schedule_label': scheduleLabel},
        );
    _refresh(requestId);
  }

  Future<void> acceptSchedule(String requestId, String messageId) async {
    if (_isMock) {
      ref.read(requestRepositoryProvider).confirmSchedule(requestId, messageId);
      _refresh(requestId);
      return;
    }
    await ref
        .read(activeServiceRequestsRepositoryProvider)
        .transitionStatus(
          requestId: requestId,
          nextStatus: RequestState.scheduled,
          eventType: 'schedule_accepted',
        );
    _refresh(requestId);
  }

  Future<void> startWork(String requestId) async {
    if (_isMock) {
      ref.read(requestRepositoryProvider).startJob(requestId);
      _refresh(requestId);
      return;
    }
    await ref
        .read(activeServiceRequestsRepositoryProvider)
        .transitionStatus(
          requestId: requestId,
          nextStatus: RequestState.inProgress,
          eventType: 'work_started',
        );
    _refresh(requestId);
  }

  Future<void> completeWork(String requestId) async {
    if (_isMock) {
      ref.read(requestRepositoryProvider).markJobCompleted(requestId);
      _refresh(requestId);
      return;
    }
    await ref
        .read(activeServiceRequestsRepositoryProvider)
        .transitionStatus(
          requestId: requestId,
          nextStatus: RequestState.pendingCustomerConfirmation,
          eventType: 'work_completed',
        );
    _refresh(requestId);
  }

  Future<void> requestRating(String requestId) async {
    if (_isMock) {
      ref.read(requestRepositoryProvider).confirmJob(requestId);
      _refresh(requestId);
      return;
    }
    await ref
        .read(activeServiceRequestsRepositoryProvider)
        .transitionStatus(
          requestId: requestId,
          nextStatus: RequestState.completed,
          eventType: 'rating_requested',
        );
    _refresh(requestId);
  }
}

final requestWorkflowControllerProvider = Provider<RequestWorkflowController>(
  RequestWorkflowController.new,
);
