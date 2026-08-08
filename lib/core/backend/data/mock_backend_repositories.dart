import 'dart:async';

import 'package:linko/app/app_mode.dart';
import 'package:linko/core/backend/data/account_status_store.dart';
import 'package:linko/core/backend/repositories/authentication_repository.dart';
import 'package:linko/core/backend/repositories/conversations_repository.dart';
import 'package:linko/core/backend/repositories/professionals_repository.dart';
import 'package:linko/core/backend/repositories/profile_repository.dart';
import 'package:linko/core/backend/repositories/quotations_repository.dart';
import 'package:linko/core/backend/repositories/ratings_repository.dart';
import 'package:linko/core/backend/repositories/reports_repository.dart';
import 'package:linko/core/backend/repositories/service_requests_repository.dart';
import 'package:linko/core/backend/data/professional_availability_store.dart';
import 'package:linko/features/auth/domain/models/app_user_profile.dart';
import 'package:linko/features/requests/domain/models/conversation_message.dart';
import 'package:linko/features/requests/domain/models/conversation.dart';
import 'package:linko/features/requests/domain/models/professional_profile.dart';
import 'package:linko/features/requests/domain/models/quotation.dart';
import 'package:linko/features/requests/domain/models/request_state.dart';
import 'package:linko/features/requests/domain/models/service_rating.dart';
import 'package:linko/features/requests/domain/models/service_request.dart';
import 'package:linko/features/requests/domain/models/timeline_event.dart';
import 'package:linko/features/requests/domain/repositories/request_repository.dart';
import 'package:linko/features/requests/data/mock_request_repository.dart';

class MockAuthenticationRepository implements AuthenticationRepository {
  MockAuthenticationRepository({AppUserProfile? initialUser})
    : _currentUser = initialUser;

  final _changes = StreamController<AppUserProfile?>.broadcast();
  AppUserProfile? _currentUser;

  @override
  Stream<AppUserProfile?> authStateChanges() => _changes.stream;

  @override
  Future<AppUserProfile?> restoreSession() async => _currentUser;

  @override
  Future<void> sendEmailLink(String email) async {
    if (!email.contains('@')) {
      throw ArgumentError('Ingresa un correo electrónico válido.');
    }
  }

  @override
  Future<void> signInWithApple() async {
    await _authenticate(
      id: 'mock-apple-user',
      name: 'Usuario Apple',
      email: 'apple@mock.linko',
    );
  }

  @override
  Future<void> signInWithGoogle() async {
    await _authenticate(
      id: 'mock-google-user',
      name: 'Usuario Google',
      email: 'google@mock.linko',
    );
  }

  Future<AppUserProfile> _authenticate({
    required String id,
    required String name,
    required String email,
  }) async {
    _currentUser = AppUserProfile(
      id: id,
      displayName: name,
      email: email,
      avatarUrl: null,
      activeMode: AppMode.customer,
      createdAt: DateTime.utc(2026),
    );
    _changes.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _changes.add(null);
  }
}

class MockProfileRepository implements ProfileRepository {
  MockProfileRepository([AccountStatusStore? statuses])
    : _statuses = statuses ?? AccountStatusStore();

  final AccountStatusStore _statuses;
  final Map<String, AppUserProfile> _profiles = {};

  @override
  Future<AppUserProfile> getOrCreateProfile(AppUserProfile authUser) async {
    final profile = _profiles.putIfAbsent(authUser.id, () => authUser);
    final status = _statuses.statusOf(profile.id);
    return profile.accountStatus == status
        ? profile
        : profile.copyWith(accountStatus: status);
  }

  @override
  Stream<AppUserProfile?> watchProfile(String userId) =>
      _statuses.watch(userId).map((status) {
        final profile = _profiles[userId];
        return profile?.copyWith(accountStatus: status);
      });

  @override
  Future<AppUserProfile> updateProfile({
    required String userId,
    String? displayName,
    String? avatarUrl,
    AppMode? activeMode,
    bool? onboardingCompleted,
  }) async {
    final current = _profiles[userId];
    if (current == null) {
      throw StateError('No existe el perfil $userId.');
    }
    final updated = current.copyWith(
      displayName: displayName,
      avatarUrl: avatarUrl,
      activeMode: activeMode,
      onboardingCompleted: onboardingCompleted,
      updatedAt: DateTime.now().toUtc(),
    );
    _profiles[userId] = updated;
    return updated;
  }
}

class MockReportsRepository implements ReportsRepository {
  MockReportsRepository(this._requests);

  final RequestRepository _requests;

  @override
  Future<void> createReport({
    required String reporterId,
    required String requestId,
    required String reason,
  }) async {
    _requests.reportCompletedWorkProblem(requestId);
  }
}

class MockProfessionalsRepository implements ProfessionalsRepository {
  MockProfessionalsRepository(
    this._requests, [
    ProfessionalAvailabilityStore? availability,
  ]) : _availability = availability ?? ProfessionalAvailabilityStore();

  final RequestRepository _requests;
  final ProfessionalAvailabilityStore _availability;

  @override
  Future<List<ProfessionalProfile>> getProfessionals() async {
    final profiles = <String, ProfessionalProfile>{};
    for (final request in _requests.getCustomerRequests('customer-current')) {
      profiles[request.professional.user.id] = request.professional;
    }
    return List.unmodifiable(
      profiles.values
          .where((profile) => _availability.isAvailable(profile.user.id))
          .map(
            (profile) => ProfessionalProfile(
              id: profile.id,
              user: profile.user,
              profession: profile.profession,
              rating: profile.rating,
              reviewCount: profile.reviewCount,
              location: profile.location,
              isVerified: _availability.isVerified(profile.user.id),
            ),
          ),
    );
  }

  @override
  Future<ProfessionalProfile?> getProfessionalById(
    String professionalId,
  ) async {
    final professionals = await getProfessionals();
    for (final professional in professionals) {
      if (professional.user.id == professionalId ||
          professional.id == professionalId) {
        return professional;
      }
    }
    return null;
  }

  @override
  Stream<List<ProfessionalProfile>> watchProfessionals() async* {
    yield await getProfessionals();
    await for (final _ in _availability.changes) {
      yield await getProfessionals();
    }
  }
}

class MockServiceRequestsRepository implements ServiceRequestsRepository {
  MockServiceRequestsRepository(this._requests);

  final RequestRepository _requests;
  final Map<String, StreamController<RequestStatus>> _statusWatchers = {};
  final Map<String, StreamController<List<TimelineEvent>>> _timelineWatchers =
      {};
  final _requestsChanged = StreamController<void>.broadcast();

  @override
  Future<void> createRequest(ServiceRequest request) async {
    _requests.createRequest(request);
    _requestsChanged.add(null);
  }

  @override
  Future<List<ServiceRequest>> listCustomerRequests(String customerId) async =>
      _requests.getCustomerRequests(customerId);

  @override
  Future<List<ServiceRequest>> getCustomerRequests(String customerId) =>
      listCustomerRequests(customerId);

  @override
  Future<List<ServiceRequest>> listProfessionalRequests(
    String professionalId,
  ) async => _requests.getProfessionalRequests(professionalId);

  @override
  Future<List<ServiceRequest>> getProfessionalRequests(String professionalId) =>
      listProfessionalRequests(professionalId);

  @override
  Stream<List<ServiceRequest>> watchCustomerRequests(String customerId) async* {
    yield await listCustomerRequests(customerId);
    await for (final _ in _requestsChanged.stream) {
      yield await listCustomerRequests(customerId);
    }
  }

  @override
  Stream<List<ServiceRequest>> watchProfessionalRequests(
    String professionalId,
  ) async* {
    yield await listProfessionalRequests(professionalId);
    await for (final _ in _requestsChanged.stream) {
      yield await listProfessionalRequests(professionalId);
    }
  }

  @override
  Future<ServiceRequest?> getRequestById(String requestId) async =>
      _requests.getRequestById(requestId);

  @override
  Future<List<TimelineEvent>> getTimeline(String requestId) async =>
      _requests.getTimeline(requestId);

  @override
  Future<void> updateStatus(String requestId, RequestState state) async {
    _requests.updateStatus(requestId, state);
    _emitWorkflow(requestId);
    _requestsChanged.add(null);
  }

  @override
  Future<void> updateSchedule(String requestId, DateTime? scheduledAt) async {
    final request = _requests.getRequestById(requestId);
    if (request == null) throw StateError('No se encontró la solicitud.');
    (_requests as MockRequestRepository).replaceRequest(
      request.copyWith(
        scheduledAt: scheduledAt,
        clearSchedule: scheduledAt == null,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
    _requestsChanged.add(null);
  }

  @override
  Stream<RequestStatus> watchStatus(String requestId) {
    final request = _requests.getRequestById(requestId);
    if (request == null) throw StateError('No se encontró la solicitud.');
    final controller = _statusWatchers.putIfAbsent(
      requestId,
      StreamController<RequestStatus>.broadcast,
    );
    scheduleMicrotask(() {
      if (!controller.isClosed) controller.add(request.state);
    });
    return controller.stream;
  }

  @override
  Stream<List<TimelineEvent>> watchTimeline(String requestId) {
    final controller = _timelineWatchers.putIfAbsent(
      requestId,
      StreamController<List<TimelineEvent>>.broadcast,
    );
    scheduleMicrotask(() {
      if (!controller.isClosed) {
        controller.add(_requests.getTimeline(requestId));
      }
    });
    return controller.stream;
  }

  @override
  Future<void> transitionStatus({
    required String requestId,
    required RequestStatus nextStatus,
    required String eventType,
    Map<String, dynamic> payload = const {},
  }) async {
    _requests.updateStatus(requestId, nextStatus);
    _emitWorkflow(requestId);
    _requestsChanged.add(null);
  }

  @override
  Future<void> appendEvent({
    required String requestId,
    required String eventType,
    Map<String, dynamic> payload = const {},
  }) async {}

  void _emitWorkflow(String requestId) {
    final request = _requests.getRequestById(requestId);
    final statusController = _statusWatchers[requestId];
    if (request != null &&
        statusController != null &&
        !statusController.isClosed) {
      statusController.add(request.state);
    }
    final timelineController = _timelineWatchers[requestId];
    if (timelineController != null && !timelineController.isClosed) {
      timelineController.add(_requests.getTimeline(requestId));
    }
  }
}

class MockConversationsRepository implements ConversationsRepository {
  MockConversationsRepository(this._requests);

  final RequestRepository _requests;
  final Map<String, StreamController<List<ConversationMessage>>> _watchers = {};

  @override
  Future<Conversation> getOrCreateConversation({
    required String serviceRequestId,
    required String customerId,
    required String professionalId,
  }) async {
    final now = DateTime.now().toUtc();
    return Conversation(
      id: 'mock-conversation-$serviceRequestId',
      serviceRequestId: serviceRequestId,
      customerId: customerId,
      professionalId: professionalId,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<List<ConversationMessage>> listMessages(String conversationId) async {
    const prefix = 'mock-conversation-';
    if (!conversationId.startsWith(prefix)) return const [];
    return _requests.getMessages(conversationId.substring(prefix.length));
  }

  @override
  Future<ConversationMessage> sendTextMessage({
    required String conversationId,
    required String serviceRequestId,
    required String senderId,
    required MessageAuthor author,
    required String body,
  }) async => _send(
    ConversationMessage(
      id: '$conversationId-${DateTime.now().microsecondsSinceEpoch}',
      requestId: serviceRequestId,
      conversationId: conversationId,
      senderId: senderId,
      author: author,
      text: body,
      timeLabel: 'Ahora',
      createdAt: DateTime.now().toUtc(),
    ),
  );

  @override
  Future<ConversationMessage> sendSystemMessage({
    required String conversationId,
    required String serviceRequestId,
    required String body,
    Map<String, dynamic>? metadata,
  }) async => _send(
    ConversationMessage(
      id: '$conversationId-${DateTime.now().microsecondsSinceEpoch}',
      requestId: serviceRequestId,
      conversationId: conversationId,
      author: MessageAuthor.system,
      text: body,
      timeLabel: 'Ahora',
      type: ConversationMessageType.system,
      metadata: metadata,
      createdAt: DateTime.now().toUtc(),
    ),
  );

  @override
  Future<ConversationMessage> sendActionCard({
    required String conversationId,
    required String serviceRequestId,
    required String senderId,
    required MessageAuthor author,
    required ConversationMessageType actionType,
    required String body,
    required Map<String, dynamic> metadata,
  }) async => _send(
    ConversationMessage(
      id: '$conversationId-${DateTime.now().microsecondsSinceEpoch}',
      requestId: serviceRequestId,
      conversationId: conversationId,
      senderId: senderId,
      author: author,
      text: body,
      timeLabel: 'Ahora',
      type: actionType,
      metadata: metadata,
      createdAt: DateTime.now().toUtc(),
    ),
  );

  ConversationMessage _send(ConversationMessage message) {
    _requests.sendMessage(message);
    final conversationId = message.conversationId;
    if (conversationId != null) {
      final watcher = _watchers[conversationId];
      if (watcher != null && !watcher.isClosed) {
        unawaited(listMessages(conversationId).then(watcher.add));
      }
    }
    return message;
  }

  @override
  Stream<List<ConversationMessage>> watchMessages(String conversationId) {
    final controller = _watchers.putIfAbsent(
      conversationId,
      StreamController<List<ConversationMessage>>.broadcast,
    );
    scheduleMicrotask(() async {
      if (!controller.isClosed) {
        controller.add(await listMessages(conversationId));
      }
    });
    return controller.stream;
  }

  @override
  Stream<ConversationConnectionStatus> watchConnection(String conversationId) =>
      Stream.value(ConversationConnectionStatus.connected);

  @override
  Future<void> disposeConversation(String conversationId) async {
    await _watchers.remove(conversationId)?.close();
  }

  @override
  Future<void> dispose() async {
    for (final id in _watchers.keys.toList()) {
      await disposeConversation(id);
    }
  }

  @override
  Future<List<ConversationMessage>> getMessages(String requestId) async =>
      _requests.getMessages(requestId);

  @override
  Future<void> sendMessage(ConversationMessage message) async {
    _requests.sendMessage(message);
  }
}

class MockQuotationsRepository implements QuotationsRepository {
  MockQuotationsRepository(this._requests);

  final RequestRepository _requests;
  final Map<String, QuotationStatus> _statuses = {};
  final Map<String, StreamController<Quotation?>> _watchers = {};

  @override
  Future<void> acceptQuotation(String requestId) async {
    _requests.acceptQuotation(requestId);
    _statuses[requestId] = QuotationStatus.accepted;
    _emit(requestId);
  }

  @override
  Future<Quotation?> getQuotation(String requestId) async =>
      _quotation(requestId);

  @override
  Future<void> sendQuotation(Quotation quotation) async {
    _requests.sendQuotation(quotation);
    _statuses[quotation.requestId] = QuotationStatus.pending;
    _emit(quotation.requestId);
  }

  @override
  Future<void> rejectQuotation(String requestId) async {
    _requests.updateStatus(requestId, RequestState.cancelled);
    _statuses[requestId] = QuotationStatus.rejected;
    _emit(requestId);
  }

  @override
  Stream<Quotation?> watchQuotation(String requestId) {
    final controller = _watchers.putIfAbsent(
      requestId,
      StreamController<Quotation?>.broadcast,
    );
    scheduleMicrotask(() {
      if (!controller.isClosed) controller.add(_quotation(requestId));
    });
    return controller.stream;
  }

  Quotation? _quotation(String requestId) {
    final quotation = _requests.getQuotation(requestId);
    return quotation?.copyWith(status: _statuses[requestId]);
  }

  void _emit(String requestId) {
    final controller = _watchers[requestId];
    if (controller != null && !controller.isClosed) {
      controller.add(_quotation(requestId));
    }
  }
}

class MockRatingsRepository implements RatingsRepository {
  MockRatingsRepository(this._requests);

  final RequestRepository _requests;

  @override
  Future<ServiceRating?> getRating(String requestId) async =>
      _requests.getRating(requestId);

  @override
  Future<ProfessionalRatingSummary> getProfessionalSummary(
    String professionalId,
  ) async => _requests.getProfessionalRatingSummary(professionalId);

  @override
  Future<void> submitRating(ServiceRating rating) async {
    _requests.submitRating(rating);
  }
}
