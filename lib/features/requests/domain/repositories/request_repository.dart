import 'package:linko/features/requests/domain/models/conversation_message.dart';
import 'package:linko/features/requests/domain/models/quotation.dart';
import 'package:linko/features/requests/domain/models/request_state.dart';
import 'package:linko/features/requests/domain/models/service_request.dart';
import 'package:linko/features/requests/domain/models/service_rating.dart';
import 'package:linko/features/requests/domain/models/timeline_event.dart';

abstract interface class RequestRepository {
  void createRequest(ServiceRequest request);
  List<ServiceRequest> getCustomerRequests(String customerId);
  List<ServiceRequest> getProfessionalRequests(String professionalId);
  ServiceRequest? getRequestById(String requestId);
  void updateStatus(String requestId, RequestState state);
  Quotation? getQuotation(String requestId);
  void sendQuotation(Quotation quotation);
  void acceptQuotation(String requestId);
  List<ConversationMessage> getMessages(String requestId);
  void sendMessage(ConversationMessage message);
  void proposeSchedule(String requestId, String scheduleLabel);
  void confirmSchedule(String requestId, String messageId);
  void requestScheduleChange(String requestId, String messageId);
  void startJob(String requestId);
  void markJobCompleted(String requestId);
  void confirmJob(String requestId);
  void reportCompletedWorkProblem(String requestId);
  ServiceRating? getRating(String requestId);
  void submitRating(ServiceRating rating);
  ProfessionalRatingSummary getProfessionalRatingSummary(String professionalId);
  List<TimelineEvent> getTimeline(String requestId);
}
