import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:linko/app/app_mode.dart';
import 'package:linko/core/backend/backend_config.dart';
import 'package:linko/core/backend/data/supabase_backend_repositories.dart';
import 'package:linko/features/auth/domain/models/app_user_profile.dart';
import 'package:linko/features/requests/data/service_request_supabase_mapper.dart';
import 'package:linko/features/requests/domain/models/app_user.dart';
import 'package:linko/features/requests/domain/models/conversation_message.dart';
import 'package:linko/features/requests/domain/models/professional_profile.dart';
import 'package:linko/features/requests/domain/models/quotation.dart';
import 'package:linko/features/requests/domain/models/request_state.dart';
import 'package:linko/features/requests/domain/models/service_rating.dart';
import 'package:linko/features/requests/domain/models/service_request.dart';
import 'package:linko/features/requests/domain/models/timeline_event.dart';
import 'package:linko/features/admin/data/supabase_admin_dashboard_repository.dart';
import 'package:linko/features/admin/data/supabase_admin_professionals_repository.dart';
import 'package:linko/features/admin/data/supabase_admin_requests_repository.dart';
import 'package:linko/features/admin/data/supabase_admin_users_repository.dart';
import 'package:linko/features/admin/domain/admin_dashboard.dart';
import 'package:linko/features/admin/domain/admin_professional.dart';
import 'package:linko/features/admin/domain/admin_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

const _enabled = bool.fromEnvironment('RUN_SUPABASE_E2E');
const _mode = String.fromEnvironment('BACKEND_MODE');
const _url = String.fromEnvironment('SUPABASE_URL');
const _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
const _serviceKey = String.fromEnvironment('SUPABASE_TEST_SERVICE_ROLE_KEY');
const _linkedProjectRef = String.fromEnvironment('SUPABASE_LINKED_PROJECT_REF');

void main() {
  test(
    'complete workflow is synchronized across main, Admin and Realtime',
    () async {
      _validateEnvironment();
      final prefix = 'qa_${DateTime.now().toUtc().microsecondsSinceEpoch}';
      const password = 'LinkO-QA-only-42!';
      final service = SupabaseClient(_url, _serviceKey);
      final adminClient = SupabaseClient(_url, _anonKey);
      final customerClient = SupabaseClient(_url, _anonKey);
      final professionalClient = SupabaseClient(_url, _anonKey);
      final createdUserIds = <String>[];
      String? requestId;
      StreamIterator<RequestStatus>? customerStatuses;
      StreamIterator<RequestStatus>? professionalStatuses;
      StreamIterator<List<TimelineEvent>>? realtimeTimeline;
      StreamIterator<List<ConversationMessage>>? realtimeMessages;

      try {
        Future<User> createUser(String role, AppMode mode) async {
          final response = await service.auth.admin.createUser(
            AdminUserAttributes(
              email: '${prefix}_$role@example.invalid',
              password: password,
              emailConfirm: true,
              userMetadata: {
                'full_name': '${prefix}_$role',
                'active_mode': mode.name,
              },
            ),
          );
          final user = response.user!;
          createdUserIds.add(user.id);
          return user;
        }

        final adminUser = await createUser('admin', AppMode.customer);
        await service
            .from('profiles')
            .update({'role': 'admin'})
            .eq('id', adminUser.id);
        await adminClient.auth.signInWithPassword(
          email: '${prefix}_admin@example.invalid',
          password: password,
        );

        final customerUser = await createUser('customer', AppMode.customer);
        final professionalUser = await createUser(
          'professional',
          AppMode.professional,
        );
        await customerClient.auth.signInWithPassword(
          email: '${prefix}_customer@example.invalid',
          password: password,
        );
        await professionalClient.auth.signInWithPassword(
          email: '${prefix}_professional@example.invalid',
          password: password,
        );

        final customerProfiles = ProfileRepositorySupabase(customerClient);
        final professionalProfiles = ProfileRepositorySupabase(
          professionalClient,
        );
        final customerProfile = await customerProfiles.getOrCreateProfile(
          _authProfile(customerUser, '${prefix}_customer', AppMode.customer),
        );
        final professionalProfile = await professionalProfiles
            .getOrCreateProfile(
              _authProfile(
                professionalUser,
                '${prefix}_professional',
                AppMode.professional,
              ),
            );
        expect(customerProfile.id, customerUser.id);
        expect(professionalProfile.id, professionalUser.id);

        await professionalClient.from('professional_profiles').insert({
          'id': professionalUser.id,
          'display_name': prefix,
          'profession': 'Certificación QA',
          'location': 'San José',
          'skills': ['qa'],
          'verification_status': 'pending',
        });

        final adminUsers = SupabaseAdminUsersRepository(adminClient);
        final adminProfessionals = SupabaseAdminProfessionalsRepository(
          adminClient,
        );
        final adminRequests = SupabaseAdminRequestsRepository(adminClient);
        final adminDashboard = SupabaseAdminDashboardRepository(adminClient);
        final customerProfessionals = SupabaseProfessionalsRepository(
          customerClient,
        );
        final professionalProfessionals = SupabaseProfessionalsRepository(
          professionalClient,
        );
        await professionalProfessionals.updateOwnProfessionalProfile(
          ProfessionalProfileUpdate(
            profession: 'Certificación QA',
            location: 'San José',
            biography: '${prefix}_biography',
            services: const ['QA E2E', 'Sincronización'],
            experienceYears: 6,
            experienceDescription: '${prefix}_experience',
            coverageArea: 'GAM QA',
          ),
        );
        final ownProfessional = await professionalProfessionals
            .getOwnProfessionalProfile();
        expect(ownProfessional?.biography, '${prefix}_biography');
        expect(ownProfessional?.services, contains('QA E2E'));
        expect(
          () => customerProfessionals.updateOwnProfessionalProfile(
            const ProfessionalProfileUpdate(
              profession: 'No autorizado',
              location: '',
              biography: '',
              services: [],
              experienceYears: 0,
              experienceDescription: '',
              coverageArea: '',
            ),
          ),
          throwsA(isA<PostgrestException>()),
        );
        final discovery = StreamIterator(
          customerProfessionals.watchProfessionals(),
        );
        expect(
          await discovery.moveNext().timeout(
            _realtimeTimeout,
            onTimeout: () => throw TimeoutException('discovery_initial'),
          ),
          isTrue,
        );
        expect(
          discovery.current.any((item) => item.id == professionalUser.id),
          isFalse,
        );

        await adminProfessionals.approveVerification(professionalUser.id);
        final discovered = await _waitForProfessional(
          discovery,
          professionalUser.id,
        );
        expect(
          discovered.where((item) => item.id == professionalUser.id),
          hasLength(1),
        );
        final directProfessional = await customerProfessionals
            .getProfessionalById(professionalUser.id);
        expect(directProfessional?.id, professionalUser.id);
        expect(directProfessional?.user.name, prefix);
        expect(directProfessional?.biography, '${prefix}_biography');
        expect(directProfessional?.services, contains('QA E2E'));
        expect(directProfessional?.experienceYears, 6);
        await discovery.cancel();

        final users = await adminUsers.listUsers(
          AdminUserQuery(search: prefix),
        );
        expect(users.where((user) => user.id == customerUser.id), hasLength(1));
        expect(
          users.where((user) => user.id == professionalUser.id),
          hasLength(1),
        );
        final professionals = await adminProfessionals.listProfessionals(
          AdminProfessionalQuery(search: prefix),
        );
        expect(
          professionals.where((item) => item.id == professionalUser.id),
          hasLength(1),
        );
        final verificationAudit = await adminProfessionals.getAuditLog(
          professionalUser.id,
        );
        expect(verificationAudit, hasLength(1));

        final dashboardBefore = await adminDashboard.loadDashboard(
          AdminDashboardRange.today,
        );
        final customerRequests = ServiceRequestsRepositorySupabase(
          customerClient,
        );
        final professionalRequests = ServiceRequestsRepositorySupabase(
          professionalClient,
        );
        requestId = const Uuid().v4();
        await customerRequests.createRequest(
          ServiceRequest(
            id: requestId,
            customer: AppUser(id: customerUser.id, name: prefix),
            professional: ProfessionalProfile(
              id: professionalUser.id,
              user: AppUser(id: professionalUser.id, name: prefix),
              profession: 'Certificación QA',
              rating: 0,
              reviewCount: 0,
              location: 'San José',
              isVerified: true,
            ),
            serviceName: '${prefix}_request',
            category: ServiceCategory.maintenance,
            description: '${prefix}_description',
            location: 'San José',
            availabilityLabel: 'Flexible',
            state: RequestState.pending,
            updatedAt: DateTime.now().toUtc(),
            createdAtLabel: 'Ahora',
            memberSinceLabel: 'QA',
            attachedPhotoCount: 0,
          ),
        );

        customerStatuses = StreamIterator(
          customerRequests.watchStatus(requestId),
        );
        professionalStatuses = StreamIterator(
          professionalRequests.watchStatus(requestId),
        );
        realtimeTimeline = StreamIterator(
          customerRequests.watchTimeline(requestId),
        );
        final customerSeen = <RequestStatus>[];
        final professionalSeen = <RequestStatus>[];
        await _waitForStatus(
          customerStatuses,
          RequestState.pending,
          customerSeen,
        );
        await _waitForStatus(
          professionalStatuses,
          RequestState.pending,
          professionalSeen,
        );
        await _verifyState(
          requestId: requestId,
          expected: RequestState.pending,
          expectedEvent: 'request_created',
          customer: customerRequests,
          professional: professionalRequests,
          admin: adminRequests,
          timeline: realtimeTimeline,
        );

        final professionalList = await professionalRequests
            .listProfessionalRequests(professionalUser.id);
        expect(
          professionalList.where((request) => request.id == requestId),
          hasLength(1),
        );

        final customerConversations = ConversationsRepositorySupabase(
          customerClient,
        );
        final professionalConversations = ConversationsRepositorySupabase(
          professionalClient,
        );
        final conversation = await customerConversations
            .getOrCreateConversation(
              serviceRequestId: requestId,
              customerId: customerUser.id,
              professionalId: professionalUser.id,
            );
        final professionalConversation = await professionalConversations
            .getOrCreateConversation(
              serviceRequestId: requestId,
              customerId: customerUser.id,
              professionalId: professionalUser.id,
            );
        expect(professionalConversation.id, conversation.id);
        realtimeMessages = StreamIterator(
          customerConversations.watchMessages(conversation.id),
        );
        await _waitForMessages(realtimeMessages, 0);
        await customerConversations.sendTextMessage(
          conversationId: conversation.id,
          serviceRequestId: requestId,
          senderId: customerUser.id,
          author: MessageAuthor.customer,
          body: '${prefix}_customer_message',
        );
        await _waitForMessages(realtimeMessages, 1);
        await professionalConversations.sendTextMessage(
          conversationId: conversation.id,
          serviceRequestId: requestId,
          senderId: professionalUser.id,
          author: MessageAuthor.professional,
          body: '${prefix}_professional_message',
        );
        final messages = await _waitForMessages(realtimeMessages, 2);
        expect(messages.map((message) => message.id).toSet(), hasLength(2));

        final professionalQuotations = QuotationsRepositorySupabase(
          professionalClient,
        );
        final customerQuotations = QuotationsRepositorySupabase(customerClient);
        await professionalQuotations.sendQuotation(
          Quotation(
            requestId: requestId,
            professionalId: professionalUser.id,
            laborAmount: 45000,
            materialsAmount: 0,
            workDescription: '${prefix}_quotation',
            estimatedDuration: '1 día',
            startTiming: 'Esta semana',
            validityDays: 7,
          ),
        );
        await _stateTransition(
          requestId,
          RequestState.quoted,
          'quotation_created',
          customerStatuses,
          professionalStatuses,
          customerSeen,
          professionalSeen,
          customerRequests,
          professionalRequests,
          adminRequests,
          realtimeTimeline,
        );

        await customerQuotations.acceptQuotation(requestId);
        await _stateTransition(
          requestId,
          RequestState.accepted,
          'quotation_accepted',
          customerStatuses,
          professionalStatuses,
          customerSeen,
          professionalSeen,
          customerRequests,
          professionalRequests,
          adminRequests,
          realtimeTimeline,
        );

        await professionalRequests.appendEvent(
          requestId: requestId,
          eventType: 'schedule_proposed',
          payload: {'schedule_label': '${prefix}_schedule'},
        );
        await _verifyState(
          requestId: requestId,
          expected: RequestState.accepted,
          expectedEvent: 'schedule_proposed',
          customer: customerRequests,
          professional: professionalRequests,
          admin: adminRequests,
          timeline: realtimeTimeline,
        );

        await customerRequests.transitionStatus(
          requestId: requestId,
          nextStatus: RequestState.scheduled,
          eventType: 'schedule_accepted',
        );
        await _stateTransition(
          requestId,
          RequestState.scheduled,
          'schedule_accepted',
          customerStatuses,
          professionalStatuses,
          customerSeen,
          professionalSeen,
          customerRequests,
          professionalRequests,
          adminRequests,
          realtimeTimeline,
        );

        await professionalRequests.transitionStatus(
          requestId: requestId,
          nextStatus: RequestState.inProgress,
          eventType: 'work_started',
        );
        await _stateTransition(
          requestId,
          RequestState.inProgress,
          'work_started',
          customerStatuses,
          professionalStatuses,
          customerSeen,
          professionalSeen,
          customerRequests,
          professionalRequests,
          adminRequests,
          realtimeTimeline,
        );

        await professionalRequests.transitionStatus(
          requestId: requestId,
          nextStatus: RequestState.pendingCustomerConfirmation,
          eventType: 'work_completed',
        );
        await _stateTransition(
          requestId,
          RequestState.pendingCustomerConfirmation,
          'work_completed',
          customerStatuses,
          professionalStatuses,
          customerSeen,
          professionalSeen,
          customerRequests,
          professionalRequests,
          adminRequests,
          realtimeTimeline,
        );

        await customerRequests.transitionStatus(
          requestId: requestId,
          nextStatus: RequestState.completed,
          eventType: 'rating_requested',
        );
        await _stateTransition(
          requestId,
          RequestState.completed,
          'rating_requested',
          customerStatuses,
          professionalStatuses,
          customerSeen,
          professionalSeen,
          customerRequests,
          professionalRequests,
          adminRequests,
          realtimeTimeline,
        );

        final ratings = SupabaseRatingsRepository(customerClient);
        await ratings.submitRating(
          ServiceRating(
            requestId: requestId,
            professionalId: professionalUser.id,
            stars: 5,
            comment: '${prefix}_rating',
          ),
        );
        await _stateTransition(
          requestId,
          RequestState.reviewed,
          'rating_submitted',
          customerStatuses,
          professionalStatuses,
          customerSeen,
          professionalSeen,
          customerRequests,
          professionalRequests,
          adminRequests,
          realtimeTimeline,
        );

        expect(customerSeen.toSet(), hasLength(customerSeen.length));
        expect(professionalSeen.toSet(), hasLength(professionalSeen.length));
        expect(customerSeen, professionalSeen);
        expect(
          customerSeen,
          RequestState.values.where(
            (state) => const {
              RequestState.pending,
              RequestState.quoted,
              RequestState.accepted,
              RequestState.scheduled,
              RequestState.inProgress,
              RequestState.pendingCustomerConfirmation,
              RequestState.completed,
              RequestState.reviewed,
            }.contains(state),
          ),
        );

        final customerHistory = await customerRequests.listCustomerRequests(
          customerUser.id,
        );
        final professionalHistory = await professionalRequests
            .listProfessionalRequests(professionalUser.id);
        expect(
          customerHistory
              .singleWhere((request) => request.id == requestId)
              .state,
          RequestState.reviewed,
        );
        expect(
          professionalHistory
              .singleWhere((request) => request.id == requestId)
              .state,
          RequestState.reviewed,
        );

        final summary = await ratings.getProfessionalSummary(
          professionalUser.id,
        );
        expect(summary.averageRating, 5);
        expect(summary.reviewCount, 1);
        expect(summary.completedJobsCount, 1);
        final adminProfessional = (await adminProfessionals.listProfessionals(
          AdminProfessionalQuery(search: prefix),
        )).singleWhere((item) => item.id == professionalUser.id);
        expect(adminProfessional.averageRating, 5);
        expect(adminProfessional.completedJobs, 1);
        expect(adminProfessional.activeJobs, 0);

        final dashboardAfter = await adminDashboard.loadDashboard(
          AdminDashboardRange.today,
        );
        expect(
          dashboardAfter.metrics.completedJobs,
          dashboardBefore.metrics.completedJobs + 1,
        );
      } finally {
        await realtimeMessages?.cancel();
        await realtimeTimeline?.cancel();
        await customerStatuses?.cancel();
        await professionalStatuses?.cancel();
        if (requestId != null) {
          await service.from('reports').delete().eq('request_id', requestId);
          await service
              .from('admin_request_audit_log')
              .delete()
              .eq('request_id', requestId);
          await service.from('service_requests').delete().eq('id', requestId);
        }
        for (final id in createdUserIds.reversed) {
          await _deleteCreatedUser(service, id);
        }
        final remainingProfiles = createdUserIds.isEmpty
            ? const <dynamic>[]
            : await service
                  .from('profiles')
                  .select('id')
                  .inFilter('id', createdUserIds);
        expect(
          remainingProfiles,
          isEmpty,
          reason: 'La limpieza dejó perfiles.',
        );
        await adminClient.dispose();
        await customerClient.dispose();
        await professionalClient.dispose();
        await service.dispose();
      }
    },
    skip: _enabled ? false : 'RUN_SUPABASE_E2E no está habilitado.',
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

const _realtimeTimeout = Duration(seconds: 25);

void _validateEnvironment() {
  expect(_mode, 'supabase', reason: 'BACKEND_MODE debe ser supabase.');
  final config = BackendConfig.fromValues(
    modeValue: _mode,
    supabaseUrl: _url,
    supabaseAnonKey: _anonKey,
  );
  config.validate();
  expect(_serviceKey, isNotEmpty, reason: 'Falta la credencial aislada de QA.');
  expect(_linkedProjectRef, isNotEmpty, reason: 'Falta el proyecto enlazado.');
  expect(
    Uri.parse(_url).host.split('.').first,
    _linkedProjectRef,
    reason: 'El proyecto enlazado no coincide con SUPABASE_URL.',
  );
}

AppUserProfile _authProfile(User user, String name, AppMode mode) =>
    AppUserProfile(
      id: user.id,
      displayName: name,
      email: user.email,
      avatarUrl: null,
      activeMode: mode,
      role: UserRole.user,
      createdAt: DateTime.parse(user.createdAt),
    );

Future<void> _stateTransition(
  String requestId,
  RequestState state,
  String eventType,
  StreamIterator<RequestStatus> customerStatuses,
  StreamIterator<RequestStatus> professionalStatuses,
  List<RequestStatus> customerSeen,
  List<RequestStatus> professionalSeen,
  ServiceRequestsRepositorySupabase customer,
  ServiceRequestsRepositorySupabase professional,
  SupabaseAdminRequestsRepository admin,
  StreamIterator<List<TimelineEvent>> timeline,
) async {
  await _waitForStatus(customerStatuses, state, customerSeen);
  await _waitForStatus(professionalStatuses, state, professionalSeen);
  await _verifyState(
    requestId: requestId,
    expected: state,
    expectedEvent: eventType,
    customer: customer,
    professional: professional,
    admin: admin,
    timeline: timeline,
  );
}

Future<void> _verifyState({
  required String requestId,
  required RequestState expected,
  required String expectedEvent,
  required ServiceRequestsRepositorySupabase customer,
  required ServiceRequestsRepositorySupabase professional,
  required SupabaseAdminRequestsRepository admin,
  required StreamIterator<List<TimelineEvent>> timeline,
}) async {
  expect((await customer.getRequestById(requestId))?.state, expected);
  expect((await professional.getRequestById(requestId))?.state, expected);
  final adminRequest = (await admin.listRequests()).singleWhere(
    (request) => request.id == requestId,
  );
  expect(adminRequest.status, RequestStatusMapper.toDatabase(expected));
  final events = await _waitForTimelineEvent(timeline, expectedEvent);
  expect(events.map((event) => event.id).toSet(), hasLength(events.length));
  expect(events.where((event) => event.type == expectedEvent), hasLength(1));
  final persisted = await customer.getTimeline(requestId);
  expect(persisted.where((event) => event.type == expectedEvent), hasLength(1));
}

Future<void> _waitForStatus(
  StreamIterator<RequestStatus> iterator,
  RequestStatus expected,
  List<RequestStatus> seen,
) async {
  for (var attempt = 0; attempt < 8; attempt++) {
    expect(
      await iterator.moveNext().timeout(
        _realtimeTimeout,
        onTimeout: () => throw TimeoutException('status_${expected.name}'),
      ),
      isTrue,
    );
    seen.add(iterator.current);
    if (iterator.current == expected) return;
  }
  fail('Realtime no entregó el estado ${expected.name}.');
}

Future<List<TimelineEvent>> _waitForTimelineEvent(
  StreamIterator<List<TimelineEvent>> iterator,
  String type,
) async {
  for (var attempt = 0; attempt < 8; attempt++) {
    expect(
      await iterator.moveNext().timeout(
        _realtimeTimeout,
        onTimeout: () => throw TimeoutException('timeline_$type'),
      ),
      isTrue,
    );
    if (iterator.current.any((event) => event.type == type)) {
      return iterator.current;
    }
  }
  fail('Realtime no entregó el evento $type.');
}

Future<List<ConversationMessage>> _waitForMessages(
  StreamIterator<List<ConversationMessage>> iterator,
  int count,
) async {
  for (var attempt = 0; attempt < 8; attempt++) {
    expect(
      await iterator.moveNext().timeout(
        _realtimeTimeout,
        onTimeout: () => throw TimeoutException('messages_$count'),
      ),
      isTrue,
    );
    if (iterator.current.length >= count) return iterator.current;
  }
  fail('Realtime no entregó $count mensajes.');
}

Future<List<ProfessionalProfile>> _waitForProfessional(
  StreamIterator<List<ProfessionalProfile>> iterator,
  String professionalId,
) async {
  for (var attempt = 0; attempt < 8; attempt++) {
    expect(
      await iterator.moveNext().timeout(
        _realtimeTimeout,
        onTimeout: () => throw TimeoutException('discovery_verified'),
      ),
      isTrue,
    );
    if (iterator.current.any((item) => item.id == professionalId)) {
      return iterator.current;
    }
  }
  fail('Realtime no publicó al profesional verificado.');
}

Future<void> _deleteCreatedUser(SupabaseClient service, String id) async {
  await service.from('reports').delete().eq('reporter_id', id);
  await service.from('service_requests').delete().eq('customer_id', id);
  await service.from('service_requests').delete().eq('professional_id', id);
  await service
      .from('admin_professional_audit_log')
      .delete()
      .eq('professional_id', id);
  await service
      .from('admin_professional_audit_log')
      .delete()
      .eq('admin_id', id);
  await service.from('admin_request_audit_log').delete().eq('admin_id', id);
  await service.from('admin_audit_logs').delete().eq('user_id', id);
  await service.from('admin_audit_logs').delete().eq('admin_id', id);
  await service.auth.admin.deleteUser(id);
}
