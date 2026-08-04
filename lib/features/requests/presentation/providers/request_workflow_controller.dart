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

  Future<void> createQuotation(Quotation quotation) async {
    if (_isMock) {
      ref.read(requestRepositoryProvider).sendQuotation(quotation);
      return;
    }
    await ref.read(activeQuotationsRepositoryProvider).sendQuotation(quotation);
  }

  Future<void> acceptQuotation(String requestId) async {
    if (_isMock) {
      ref.read(requestRepositoryProvider).acceptQuotation(requestId);
      return;
    }
    await ref
        .read(activeQuotationsRepositoryProvider)
        .acceptQuotation(requestId);
  }

  Future<void> rejectQuotation(String requestId) async {
    if (_isMock) {
      await ref
          .read(activeQuotationsRepositoryProvider)
          .rejectQuotation(requestId);
      return;
    }
    await ref
        .read(activeQuotationsRepositoryProvider)
        .rejectQuotation(requestId);
  }

  Future<void> rejectRequest(String requestId) async {
    if (_isMock) {
      ref
          .read(requestRepositoryProvider)
          .updateStatus(requestId, RequestState.cancelled);
      return;
    }
    await ref
        .read(activeServiceRequestsRepositoryProvider)
        .updateStatus(requestId, RequestState.cancelled);
  }

  Future<void> proposeSchedule(String requestId, String scheduleLabel) async {
    if (_isMock) {
      ref
          .read(requestRepositoryProvider)
          .proposeSchedule(requestId, scheduleLabel);
      return;
    }
    await ref
        .read(activeServiceRequestsRepositoryProvider)
        .appendEvent(
          requestId: requestId,
          eventType: 'schedule_proposed',
          payload: {'schedule_label': scheduleLabel},
        );
  }

  Future<void> acceptSchedule(String requestId, String messageId) async {
    if (_isMock) {
      ref.read(requestRepositoryProvider).confirmSchedule(requestId, messageId);
      return;
    }
    await ref
        .read(activeServiceRequestsRepositoryProvider)
        .transitionStatus(
          requestId: requestId,
          nextStatus: RequestState.scheduled,
          eventType: 'schedule_accepted',
        );
  }

  Future<void> startWork(String requestId) async {
    if (_isMock) {
      ref.read(requestRepositoryProvider).startJob(requestId);
      return;
    }
    await ref
        .read(activeServiceRequestsRepositoryProvider)
        .transitionStatus(
          requestId: requestId,
          nextStatus: RequestState.inProgress,
          eventType: 'work_started',
        );
  }

  Future<void> completeWork(String requestId) async {
    if (_isMock) {
      ref.read(requestRepositoryProvider).markJobCompleted(requestId);
      return;
    }
    await ref
        .read(activeServiceRequestsRepositoryProvider)
        .transitionStatus(
          requestId: requestId,
          nextStatus: RequestState.pendingCustomerConfirmation,
          eventType: 'work_completed',
        );
  }

  Future<void> requestRating(String requestId) async {
    if (_isMock) {
      ref.read(requestRepositoryProvider).confirmJob(requestId);
      return;
    }
    await ref
        .read(activeServiceRequestsRepositoryProvider)
        .transitionStatus(
          requestId: requestId,
          nextStatus: RequestState.completed,
          eventType: 'rating_requested',
        );
  }
}

final requestWorkflowControllerProvider = Provider<RequestWorkflowController>(
  RequestWorkflowController.new,
);
