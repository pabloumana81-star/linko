import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko/features/home/presentation/models/incoming_service_request.dart';
import 'package:linko/features/home/presentation/models/quotation_draft.dart';
import 'package:linko/features/requests/domain/models/quotation.dart';
import 'package:linko/features/requests/domain/models/request_state.dart';
import 'package:linko/features/requests/presentation/adapters/request_view_adapters.dart';
import 'package:linko/features/requests/presentation/providers/request_providers.dart';

class ProfessionalRequestsState {
  const ProfessionalRequestsState({
    required this.requests,
    this.quotations = const {},
  });

  final List<IncomingServiceRequest> requests;
  final Map<String, QuotationDraft> quotations;
}

class ProfessionalRequestsNotifier extends Notifier<ProfessionalRequestsState> {
  @override
  ProfessionalRequestsState build() {
    return ProfessionalRequestsState(
      requests: _repositoryRequests(),
      quotations: _repositoryQuotations(),
    );
  }

  void reject(String requestId) {
    ref
        .read(requestRepositoryProvider)
        .updateStatus(requestId, RequestState.cancelled);
    state = ProfessionalRequestsState(
      requests: _repositoryRequests(),
      quotations: state.quotations,
    );
    _invalidate(requestId);
  }

  bool sendQuotation(QuotationDraft draft) {
    if (ref.read(requestRepositoryProvider).getQuotation(draft.requestId) !=
        null) {
      return false;
    }
    ref
        .read(requestRepositoryProvider)
        .sendQuotation(
          Quotation(
            requestId: draft.requestId,
            laborAmount: draft.laborAmount,
            materialsAmount: draft.materialsAmount,
            workDescription: draft.workDescription,
            estimatedDuration: draft.estimatedDuration.label,
            startTiming: draft.startTiming.label,
            validityDays: draft.validityDays,
          ),
        );
    state = ProfessionalRequestsState(
      requests: _repositoryRequests(),
      quotations: Map.unmodifiable({
        ...state.quotations,
        draft.requestId: draft,
      }),
    );
    _invalidate(draft.requestId);
    return true;
  }

  List<IncomingServiceRequest> _repositoryRequests() {
    return List.unmodifiable(
      ref
          .read(requestRepositoryProvider)
          .getProfessionalRequests(currentProfessionalId)
          .map((request) => request.toIncomingRequest()),
    );
  }

  Map<String, QuotationDraft> _repositoryQuotations() {
    final repository = ref.read(requestRepositoryProvider);
    final drafts = <String, QuotationDraft>{};
    for (final request in repository.getProfessionalRequests(
      currentProfessionalId,
    )) {
      final quotation = repository.getQuotation(request.id);
      if (quotation == null) {
        continue;
      }
      drafts[request.id] = QuotationDraft(
        requestId: request.id,
        customerName: request.customer.name,
        serviceCategory: request.serviceName,
        workDescription: quotation.workDescription,
        laborAmount: quotation.laborAmount,
        materialsAmount: quotation.materialsAmount,
        estimatedDuration: QuotationDuration.values.firstWhere(
          (duration) => duration.label == quotation.estimatedDuration,
          orElse: () => QuotationDuration.oneDay,
        ),
        startTiming: QuotationStartTiming.values.firstWhere(
          (timing) => timing.label == quotation.startTiming,
          orElse: () => QuotationStartTiming.coordinateWithCustomer,
        ),
        validityDays: quotation.validityDays,
      );
    }
    return Map.unmodifiable(drafts);
  }

  void _invalidate(String requestId) {
    ref
      ..invalidate(customerRequestsProvider)
      ..invalidate(professionalRequestsProvider)
      ..invalidate(requestDetailProvider(requestId))
      ..invalidate(conversationProvider(requestId))
      ..invalidate(timelineProvider(requestId));
  }
}

final professionalRequestFlowProvider =
    NotifierProvider<ProfessionalRequestsNotifier, ProfessionalRequestsState>(
      ProfessionalRequestsNotifier.new,
    );
