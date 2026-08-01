import 'package:linko/features/requests/domain/models/request_state.dart';
import 'package:linko/features/requests/domain/models/service_request.dart';
import 'package:linko/features/requests/domain/models/timeline_event.dart';

abstract interface class ServiceRequestsRepository {
  Future<void> createRequest(ServiceRequest request);
  Future<List<ServiceRequest>> getCustomerRequests(String customerId);
  Future<List<ServiceRequest>> getProfessionalRequests(String professionalId);
  Future<ServiceRequest?> getRequestById(String requestId);
  Future<void> updateStatus(String requestId, RequestState state);
  Future<List<TimelineEvent>> getTimeline(String requestId);
}
