import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko/core/backend/backend_providers.dart';
import 'package:linko/core/backend/backend_config.dart';
import 'package:linko/core/backend/data/mock_backend_repositories.dart';
import 'package:linko/core/backend/repositories/service_requests_repository.dart';
import 'package:linko/core/backend/repositories/quotations_repository.dart';
import 'package:linko/features/auth/presentation/auth_controller.dart';
import 'package:linko/features/requests/domain/models/conversation_message.dart';
import 'package:linko/features/requests/domain/models/service_request.dart';
import 'package:linko/features/requests/domain/models/quotation.dart';
import 'package:linko/features/requests/domain/models/timeline_event.dart';
import 'package:linko/features/requests/domain/models/service_rating.dart';
import 'package:linko/features/requests/domain/models/request_state.dart';
import 'package:linko/features/requests/domain/repositories/request_repository.dart';

const currentCustomerId = 'customer-current';
const currentProfessionalId = 'professional-carlos';

final requestRepositoryProvider = Provider<RequestRepository>(
  (ref) => ref.watch(backendRepositoriesProvider).mvpCompatibilityRequests,
);

final activeServiceRequestsRepositoryProvider =
    Provider<ServiceRequestsRepository>((ref) {
      if (ref.watch(backendRepositoriesProvider).mode == BackendMode.mock) {
        return MockServiceRequestsRepository(
          ref.watch(requestRepositoryProvider),
        );
      }
      return ref.watch(serviceRequestsRepositoryProvider);
    });

final activeQuotationsRepositoryProvider = Provider<QuotationsRepository>((
  ref,
) {
  if (ref.watch(backendRepositoriesProvider).mode == BackendMode.mock) {
    return MockQuotationsRepository(ref.watch(requestRepositoryProvider));
  }
  return ref.watch(quotationsRepositoryProvider);
});

final realtimeRequestStatusProvider =
    StreamProvider.family<RequestStatus, String>(
      (ref, requestId) => ref
          .watch(activeServiceRequestsRepositoryProvider)
          .watchStatus(requestId),
    );

final realtimeTimelineProvider =
    StreamProvider.family<List<TimelineEvent>, String>(
      (ref, requestId) => ref
          .watch(activeServiceRequestsRepositoryProvider)
          .watchTimeline(requestId),
    );

final realtimeQuotationProvider = StreamProvider.family<Quotation?, String>(
  (ref, requestId) =>
      ref.watch(activeQuotationsRepositoryProvider).watchQuotation(requestId),
);

String _requestActorId(Ref ref, String mockId) {
  final backendMode = ref.watch(backendRepositoriesProvider).mode;
  if (backendMode == BackendMode.mock) return mockId;
  return ref.watch(authControllerProvider).user?.id ?? mockId;
}

final persistedCustomerRequestsProvider = FutureProvider<List<ServiceRequest>>((
  ref,
) {
  return ref
      .watch(activeServiceRequestsRepositoryProvider)
      .listCustomerRequests(_requestActorId(ref, currentCustomerId));
});

final persistedProfessionalRequestsProvider =
    FutureProvider<List<ServiceRequest>>((ref) {
      return ref
          .watch(activeServiceRequestsRepositoryProvider)
          .listProfessionalRequests(
            _requestActorId(ref, currentProfessionalId),
          );
    });

final persistedRequestDetailProvider =
    FutureProvider.family<ServiceRequest?, String>((ref, requestId) {
      return ref
          .watch(activeServiceRequestsRepositoryProvider)
          .getRequestById(requestId);
    });

void invalidatePersistedRequests(Ref ref, String requestId) {
  ref
    ..invalidate(persistedCustomerRequestsProvider)
    ..invalidate(persistedProfessionalRequestsProvider)
    ..invalidate(persistedRequestDetailProvider(requestId));
}

final customerRequestsProvider = Provider<List<ServiceRequest>>((ref) {
  return ref
      .watch(requestRepositoryProvider)
      .getCustomerRequests(currentCustomerId);
});

final professionalRequestsProvider = Provider<List<ServiceRequest>>((ref) {
  return ref
      .watch(requestRepositoryProvider)
      .getProfessionalRequests(currentProfessionalId);
});

final requestDetailProvider = Provider.family<ServiceRequest?, String>((
  ref,
  requestId,
) {
  return ref.watch(requestRepositoryProvider).getRequestById(requestId);
});

final quotationProvider = Provider.family<Quotation?, String>((ref, requestId) {
  return ref.watch(requestRepositoryProvider).getQuotation(requestId);
});

final conversationProvider = Provider.family<List<ConversationMessage>, String>(
  (ref, requestId) {
    return ref.watch(requestRepositoryProvider).getMessages(requestId);
  },
);

final timelineProvider = Provider.family<List<TimelineEvent>, String>((
  ref,
  requestId,
) {
  return ref.watch(requestRepositoryProvider).getTimeline(requestId);
});

final ratingProvider = Provider.family<ServiceRating?, String>((
  ref,
  requestId,
) {
  return ref.watch(requestRepositoryProvider).getRating(requestId);
});

final professionalRatingSummaryProvider =
    Provider.family<ProfessionalRatingSummary, String>((ref, professionalId) {
      return ref
          .watch(requestRepositoryProvider)
          .getProfessionalRatingSummary(professionalId);
    });
