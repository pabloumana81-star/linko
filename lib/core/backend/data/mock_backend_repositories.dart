import 'dart:async';

import 'package:linko/app/app_mode.dart';
import 'package:linko/core/backend/repositories/authentication_repository.dart';
import 'package:linko/core/backend/repositories/conversations_repository.dart';
import 'package:linko/core/backend/repositories/professionals_repository.dart';
import 'package:linko/core/backend/repositories/profile_repository.dart';
import 'package:linko/core/backend/repositories/quotations_repository.dart';
import 'package:linko/core/backend/repositories/ratings_repository.dart';
import 'package:linko/core/backend/repositories/service_requests_repository.dart';
import 'package:linko/features/auth/domain/models/app_user_profile.dart';
import 'package:linko/features/requests/domain/models/conversation_message.dart';
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
  Future<AppUserProfile?> signInWithApple() => _authenticate(
    id: 'mock-apple-user',
    name: 'Usuario Apple',
    email: 'apple@mock.linko',
  );

  @override
  Future<AppUserProfile?> signInWithGoogle() => _authenticate(
    id: 'mock-google-user',
    name: 'Usuario Google',
    email: 'google@mock.linko',
  );

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
  final Map<String, AppUserProfile> _profiles = {};

  @override
  Future<AppUserProfile> getOrCreateProfile(AppUserProfile authUser) async {
    return _profiles.putIfAbsent(authUser.id, () => authUser);
  }

  @override
  Future<AppUserProfile> updateProfile({
    required String userId,
    String? displayName,
    String? avatarUrl,
    AppMode? activeMode,
  }) async {
    final current = _profiles[userId];
    if (current == null) {
      throw StateError('No existe el perfil $userId.');
    }
    final updated = current.copyWith(
      displayName: displayName,
      avatarUrl: avatarUrl,
      activeMode: activeMode,
      updatedAt: DateTime.now().toUtc(),
    );
    _profiles[userId] = updated;
    return updated;
  }
}

class MockProfessionalsRepository implements ProfessionalsRepository {
  MockProfessionalsRepository(this._requests);

  final RequestRepository _requests;

  @override
  Future<List<ProfessionalProfile>> getProfessionals() async {
    final profiles = <String, ProfessionalProfile>{};
    for (final request in _requests.getCustomerRequests('customer-current')) {
      profiles[request.professional.user.id] = request.professional;
    }
    return List.unmodifiable(profiles.values);
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
}

class MockServiceRequestsRepository implements ServiceRequestsRepository {
  MockServiceRequestsRepository(this._requests);

  final RequestRepository _requests;

  @override
  Future<void> createRequest(ServiceRequest request) async {
    _requests.createRequest(request);
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
  Future<ServiceRequest?> getRequestById(String requestId) async =>
      _requests.getRequestById(requestId);

  @override
  Future<List<TimelineEvent>> getTimeline(String requestId) async =>
      _requests.getTimeline(requestId);

  @override
  Future<void> updateStatus(String requestId, RequestState state) async {
    _requests.updateStatus(requestId, state);
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
  }
}

class MockConversationsRepository implements ConversationsRepository {
  MockConversationsRepository(this._requests);

  final RequestRepository _requests;

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

  @override
  Future<void> acceptQuotation(String requestId) async {
    _requests.acceptQuotation(requestId);
  }

  @override
  Future<Quotation?> getQuotation(String requestId) async =>
      _requests.getQuotation(requestId);

  @override
  Future<void> sendQuotation(Quotation quotation) async {
    _requests.sendQuotation(quotation);
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
