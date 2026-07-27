import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko/features/home/presentation/data/placeholder_incoming_requests.dart';
import 'package:linko/features/home/presentation/models/incoming_service_request.dart';
import 'package:linko/features/home/presentation/models/quotation_draft.dart';
import 'package:linko/features/home/presentation/models/request_status.dart';

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
      requests: List.unmodifiable(placeholderIncomingRequests),
    );
  }

  IncomingServiceRequest requestById(String id) {
    return state.requests.firstWhere((request) => request.id == id);
  }

  void reject(String requestId) {
    _updateStatus(requestId, RequestStatus.rejected);
  }

  bool sendQuotation(QuotationDraft draft) {
    if (state.quotations.containsKey(draft.requestId)) {
      return false;
    }
    final quotations = {...state.quotations, draft.requestId: draft};
    state = ProfessionalRequestsState(
      requests: _requestsWithStatus(draft.requestId, RequestStatus.quoted),
      quotations: Map.unmodifiable(quotations),
    );
    return true;
  }

  void _updateStatus(String requestId, RequestStatus status) {
    state = ProfessionalRequestsState(
      requests: _requestsWithStatus(requestId, status),
      quotations: state.quotations,
    );
  }

  List<IncomingServiceRequest> _requestsWithStatus(
    String requestId,
    RequestStatus status,
  ) {
    return List.unmodifiable(
      state.requests.map(
        (request) => request.id == requestId
            ? request.copyWith(status: status)
            : request,
      ),
    );
  }
}

final professionalRequestsProvider =
    NotifierProvider<ProfessionalRequestsNotifier, ProfessionalRequestsState>(
      ProfessionalRequestsNotifier.new,
    );
