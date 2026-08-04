import 'package:linko/features/requests/domain/models/request_state.dart';
import 'package:linko/features/requests/domain/models/service_request.dart';
import 'package:linko/features/requests/domain/models/timeline_event.dart';

abstract interface class ServiceRequestsRepository {
  Future<void> createRequest(ServiceRequest request);
  Future<List<ServiceRequest>> listCustomerRequests(String customerId);
  Future<List<ServiceRequest>> listProfessionalRequests(String professionalId);
  Future<List<ServiceRequest>> getCustomerRequests(String customerId) =>
      listCustomerRequests(customerId);
  Future<List<ServiceRequest>> getProfessionalRequests(String professionalId) =>
      listProfessionalRequests(professionalId);
  Future<ServiceRequest?> getRequestById(String requestId);
  Future<void> updateStatus(String requestId, RequestState state);
  Future<void> updateSchedule(String requestId, DateTime? scheduledAt);
  Future<List<TimelineEvent>> getTimeline(String requestId);
  Stream<RequestStatus> watchStatus(String requestId);
  Stream<List<TimelineEvent>> watchTimeline(String requestId);
  Future<void> transitionStatus({
    required String requestId,
    required RequestStatus nextStatus,
    required String eventType,
    Map<String, dynamic> payload = const {},
  });
  Future<void> appendEvent({
    required String requestId,
    required String eventType,
    Map<String, dynamic> payload = const {},
  });
}
