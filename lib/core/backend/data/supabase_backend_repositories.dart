import 'dart:async';

import 'package:linko/app/app_mode.dart';
import 'package:linko/core/backend/auth_redirect_policy.dart';
import 'package:linko/core/backend/repositories/authentication_repository.dart';
import 'package:linko/core/backend/repositories/conversations_repository.dart';
import 'package:linko/core/backend/repositories/professionals_repository.dart';
import 'package:linko/core/backend/repositories/profile_repository.dart';
import 'package:linko/core/backend/repositories/quotations_repository.dart';
import 'package:linko/core/backend/repositories/ratings_repository.dart';
import 'package:linko/core/backend/repositories/reports_repository.dart';
import 'package:linko/core/backend/repositories/service_requests_repository.dart';
import 'package:linko/features/auth/domain/models/app_user_profile.dart';
import 'package:linko/features/requests/domain/models/app_user.dart';
import 'package:linko/features/requests/domain/models/conversation_message.dart';
import 'package:linko/features/requests/domain/models/professional_profile.dart';
import 'package:linko/features/requests/domain/models/quotation.dart';
import 'package:linko/features/requests/domain/models/request_state.dart';
import 'package:linko/features/requests/domain/models/service_rating.dart';
import 'package:linko/features/requests/domain/models/service_request.dart';
import 'package:linko/features/requests/domain/models/timeline_event.dart';
import 'package:linko/features/requests/data/service_request_supabase_mapper.dart';
import 'package:linko/features/requests/data/conversation_supabase_mapper.dart';
import 'package:linko/features/requests/domain/models/conversation.dart';
import 'package:linko/features/requests/data/request_workflow_supabase_mapper.dart';
import 'package:linko/features/requests/domain/services/request_state_machine.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class SupabaseAuthenticationRepository implements AuthenticationRepository {
  SupabaseAuthenticationRepository(
    this._client, {
    required this.redirectTo,
    required this.redirectTarget,
  });

  final SupabaseClient _client;
  final String redirectTo;
  final AuthRedirectTarget redirectTarget;

  @override
  Stream<AppUserProfile?> authStateChanges() => _client.auth.onAuthStateChange
      .map((event) => event.session?.user)
      .map((user) => user == null ? null : _appUserProfile(user))
      .distinct((previous, next) => previous?.id == next?.id);

  @override
  Future<AppUserProfile?> restoreSession() async {
    var session = _client.auth.currentSession;
    if (session == null) return null;
    if (session.isExpired) {
      session = (await _client.auth.refreshSession()).session;
    }
    if (session == null) return null;
    final user = (await _client.auth.getUser(session.accessToken)).user;
    return user == null ? null : _appUserProfile(user);
  }

  @override
  Future<void> sendEmailLink(String email) {
    _validateRedirect();
    return _client.auth.signInWithOtp(
      email: email,
      emailRedirectTo: redirectTo,
    );
  }

  @override
  Future<void> signInWithApple() async {
    _validateRedirect();
    final launched = await _client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: redirectTo,
    );
    if (!launched) {
      throw const AuthenticationLaunchException(
        'No fue posible abrir el acceso con Apple.',
      );
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    _validateRedirect();
    final launched = await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectTo,
    );
    if (!launched) {
      throw const AuthenticationLaunchException(
        'No fue posible abrir el acceso con Google.',
      );
    }
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  void _validateRedirect() {
    AuthRedirectPolicy.validate(redirectTo, redirectTarget);
  }

  AppUserProfile _appUserProfile(User user) {
    final metadata = user.userMetadata;
    final name =
        metadata?['full_name'] as String? ??
        metadata?['name'] as String? ??
        user.email ??
        'Usuario LinkO';
    final mode = metadata?['active_mode'] == 'professional'
        ? AppMode.professional
        : AppMode.customer;
    return AppUserProfile(
      id: user.id,
      displayName: name,
      email: user.email,
      avatarUrl: metadata?['avatar_url'] as String?,
      activeMode: mode,
      role: metadata?['role'] == 'admin' ? UserRole.admin : UserRole.user,
      createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now().toUtc(),
    );
  }
}

class ProfileRepositorySupabase implements ProfileRepository {
  ProfileRepositorySupabase(this._client);

  final SupabaseClient _client;

  static const _selection =
      'id,email,display_name,avatar_url,active_mode,role,account_status,onboarding_completed,created_at,updated_at';

  @override
  Stream<AppUserProfile?> watchProfile(String userId) => _client
      .from('profiles')
      .stream(primaryKey: ['id'])
      .eq('id', userId)
      .map((rows) => rows.isEmpty ? null : _profile(rows.single));

  @override
  Future<AppUserProfile> getOrCreateProfile(AppUserProfile authUser) async {
    final existing = await _client
        .from('profiles')
        .select(_selection)
        .eq('id', authUser.id)
        .maybeSingle();
    if (existing != null) {
      return _profile(existing);
    }

    final created = await _client
        .from('profiles')
        .upsert({
          'id': authUser.id,
          'email': authUser.email,
          'display_name': authUser.displayName,
          'avatar_url': authUser.avatarUrl,
          'active_mode': _modeValue(authUser.activeMode),
        }, onConflict: 'id')
        .select(_selection)
        .single();
    return _profile(created);
  }

  @override
  Future<AppUserProfile> updateProfile({
    required String userId,
    String? displayName,
    String? avatarUrl,
    AppMode? activeMode,
    bool? onboardingCompleted,
  }) async {
    final values = <String, Object?>{};
    if (displayName != null) values['display_name'] = displayName;
    if (avatarUrl != null) values['avatar_url'] = avatarUrl;
    if (activeMode != null) values['active_mode'] = _modeValue(activeMode);
    if (onboardingCompleted != null) {
      values['onboarding_completed'] = onboardingCompleted;
    }
    if (values.isEmpty) {
      final current = await _client
          .from('profiles')
          .select(_selection)
          .eq('id', userId)
          .single();
      return _profile(current);
    }
    final updated = await _client
        .from('profiles')
        .update(values)
        .eq('id', userId)
        .select(_selection)
        .single();
    return _profile(updated);
  }

  AppUserProfile _profile(Map<String, dynamic> row) {
    return AppUserProfile(
      id: row['id'] as String,
      email: row['email'] as String?,
      displayName: row['display_name'] as String,
      avatarUrl: row['avatar_url'] as String?,
      activeMode: row['active_mode'] == 'professional'
          ? AppMode.professional
          : AppMode.customer,
      role: row['role'] == 'admin' ? UserRole.admin : UserRole.user,
      accountStatus: row['account_status'] == 'suspended'
          ? AccountStatus.suspended
          : AccountStatus.active,
      onboardingCompleted: row['onboarding_completed'] as bool,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  String _modeValue(AppMode mode) => switch (mode) {
    AppMode.customer => 'customer',
    AppMode.professional => 'professional',
  };
}

class SupabaseProfessionalsRepository implements ProfessionalsRepository {
  SupabaseProfessionalsRepository(this._client);

  final SupabaseClient _client;
  static const portfolioBucket = 'professional-portfolio';
  static const verificationBucket = 'professional-verification';

  @override
  Future<List<ProfessionalProfile>> getProfessionals() async {
    final rows = await _client.rpc('list_available_professionals') as List;
    return rows
        .map((row) => _mapProfessional(Map<String, dynamic>.from(row as Map)))
        .toList(growable: false);
  }

  @override
  Future<ProfessionalProfile?> getProfessionalById(
    String professionalId,
  ) async {
    final rows = await getProfessionals();
    for (final professional in rows) {
      if (professional.id == professionalId ||
          professional.user.id == professionalId) {
        return professional;
      }
    }
    return null;
  }

  @override
  Future<ProfessionalProfile?> getOwnProfessionalProfile() async {
    final row = await _client.rpc('get_own_professional_profile');
    if (row == null) return null;
    return _mapProfessional(Map<String, dynamic>.from(row as Map));
  }

  @override
  Future<void> updateOwnProfessionalProfile(
    ProfessionalProfileUpdate update,
  ) async {
    await _client.rpc(
      'update_own_professional_profile',
      params: {
        'p_profession': update.profession,
        'p_location': update.location,
        'p_biography': update.biography,
        'p_services': update.services,
        'p_experience_years': update.experienceYears,
        'p_experience_description': update.experienceDescription,
        'p_coverage_area': update.coverageArea,
      },
    );
  }

  @override
  Future<void> uploadOwnPortfolioImage(ProfessionalUploadFile file) async {
    ProfessionalStorageRules.validatePortfolio(file);
    final userId = _requireUserId();
    final path = '$userId/${const Uuid().v4()}${_extension(file.mimeType)}';
    await _client.storage
        .from(portfolioBucket)
        .uploadBinary(
          path,
          file.bytes,
          fileOptions: FileOptions(contentType: file.mimeType, upsert: false),
        );
    try {
      await _client.rpc(
        'add_own_portfolio_object',
        params: {
          'p_path': path,
          'p_name': file.name,
          'p_mime_type': file.mimeType,
          'p_size': file.bytes.length,
        },
      );
    } catch (_) {
      await _client.storage.from(portfolioBucket).remove([path]);
      rethrow;
    }
  }

  @override
  Future<void> deleteOwnPortfolioImage(String imageUrl) async {
    final path = _publicObjectPath(imageUrl, portfolioBucket);
    if (path == null) {
      await _client.rpc(
        'remove_own_legacy_portfolio_url',
        params: {'p_url': imageUrl},
      );
      return;
    }
    final userId = _requireUserId();
    if (!path.startsWith('$userId/')) {
      throw ArgumentError('La imagen no pertenece a este perfil.');
    }
    await _client.storage.from(portfolioBucket).remove([path]);
    await _client.rpc('remove_own_portfolio_object', params: {'p_path': path});
  }

  @override
  Future<List<ProfessionalVerificationDocument>>
  getOwnVerificationDocuments() async {
    final response = await _client.rpc('get_own_professional_verification');
    if (response == null) return const [];
    final data = Map<String, dynamic>.from(response as Map);
    return _verificationDocuments(data['documents']);
  }

  @override
  Future<void> uploadOwnVerificationDocument(
    ProfessionalUploadFile file,
  ) async {
    ProfessionalStorageRules.validateVerification(file);
    final userId = _requireUserId();
    final path = '$userId/${const Uuid().v4()}${_extension(file.mimeType)}';
    await _client.storage
        .from(verificationBucket)
        .uploadBinary(
          path,
          file.bytes,
          fileOptions: FileOptions(contentType: file.mimeType, upsert: false),
        );
    try {
      await _client.rpc(
        'add_own_verification_document',
        params: {
          'p_path': path,
          'p_name': file.name,
          'p_mime_type': file.mimeType,
          'p_size': file.bytes.length,
        },
      );
    } catch (_) {
      await _client.storage.from(verificationBucket).remove([path]);
      rethrow;
    }
  }

  @override
  Future<void> deleteOwnVerificationDocument(String objectPath) async {
    final userId = _requireUserId();
    if (!objectPath.startsWith('$userId/')) {
      throw ArgumentError('El documento no pertenece a este perfil.');
    }
    await _client.storage.from(verificationBucket).remove([objectPath]);
    await _client.rpc(
      'remove_own_verification_document',
      params: {'p_path': objectPath},
    );
  }

  ProfessionalProfile _mapProfessional(Map<String, dynamic> row) =>
      _professional(
        row,
        portfolioUrl: (path) =>
            _client.storage.from(portfolioBucket).getPublicUrl(path),
      );

  String _requireUserId() {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw StateError('Debes iniciar sesión como profesional.');
    return id;
  }

  @override
  Stream<List<ProfessionalProfile>> watchProfessionals() {
    late final StreamController<List<ProfessionalProfile>> controller;
    late final RealtimeChannel channel;
    Timer? refreshTimer;

    var loading = false;
    var refreshPending = false;

    Future<void> refresh() async {
      if (controller.isClosed) return;

      if (loading) {
        refreshPending = true;
        return;
      }

      loading = true;

      try {
        controller.add(await getProfessionals());
      } catch (error, stackTrace) {
        if (!controller.isClosed) {
          controller.addError(error, stackTrace);
        }
      } finally {
        loading = false;

        if (refreshPending && !controller.isClosed) {
          refreshPending = false;
          await refresh();
        }
      }
    }

    controller = StreamController<List<ProfessionalProfile>>();

    channel = _client
        .channel('main-professional-availability')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'profiles',
          callback: (_) => refresh(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'professional_profiles',
          callback: (_) => refresh(),
        );

    channel.subscribe((_, _) => refresh());

    // Realtime puede no entregar una transición de una fila que antes
    // no era visible por RLS. Este refresco periódico garantiza convergencia.
    refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) => refresh());

    controller.onListen = refresh;

    controller.onCancel = () async {
      refreshTimer?.cancel();
      await _client.removeChannel(channel);
    };

    return controller.stream;
  }
}

class SupabaseReportsRepository implements ReportsRepository {
  SupabaseReportsRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<void> createReport({
    required String reporterId,
    required String requestId,
    required String reason,
  }) async {
    await _client.from('reports').insert({
      'reporter_id': reporterId,
      'request_id': requestId,
      'reason': reason,
    });
  }
}

class ServiceRequestsRepositorySupabase implements ServiceRequestsRepository {
  ServiceRequestsRepositorySupabase(
    this._client, [
    this._mapper = const ServiceRequestSupabaseMapper(),
    this._workflowMapper = const RequestWorkflowSupabaseMapper(),
  ]);

  final SupabaseClient _client;
  final ServiceRequestSupabaseMapper _mapper;
  final RequestWorkflowSupabaseMapper _workflowMapper;

  static const _selection =
      '*,customer:profiles!customer_id(id,display_name),'
      'professional:profiles!professional_id(id,display_name)';

  @override
  Future<void> createRequest(ServiceRequest request) async {
    await _client.from('service_requests').insert(_mapper.toInsert(request));
  }

  @override
  Future<List<ServiceRequest>> listCustomerRequests(String customerId) async {
    final rows = await _client
        .from('service_requests')
        .select(_selection)
        .eq('customer_id', customerId)
        .order('updated_at', ascending: false);
    return rows.map(_mapper.fromRow).toList(growable: false);
  }

  @override
  Future<List<ServiceRequest>> getCustomerRequests(String customerId) =>
      listCustomerRequests(customerId);

  @override
  Future<List<ServiceRequest>> listProfessionalRequests(
    String professionalId,
  ) async {
    final rows = await _client
        .from('service_requests')
        .select(_selection)
        .eq('professional_id', professionalId)
        .order('updated_at', ascending: false);
    return rows.map(_mapper.fromRow).toList(growable: false);
  }

  @override
  Future<List<ServiceRequest>> getProfessionalRequests(String professionalId) =>
      listProfessionalRequests(professionalId);

  @override
  Stream<List<ServiceRequest>> watchCustomerRequests(String customerId) =>
      _watchRequestList(
        channelName: 'customer-requests:$customerId',
        load: () => listCustomerRequests(customerId),
      );

  @override
  Stream<List<ServiceRequest>> watchProfessionalRequests(
    String professionalId,
  ) => _watchRequestList(
    channelName: 'professional-requests:$professionalId',
    load: () => listProfessionalRequests(professionalId),
  );

  @override
  Future<ServiceRequest?> getRequestById(String requestId) async {
    final row = await _client
        .from('service_requests')
        .select(_selection)
        .eq('id', requestId)
        .maybeSingle();
    return row == null ? null : _mapper.fromRow(row);
  }

  @override
  Future<List<TimelineEvent>> getTimeline(String requestId) async {
    final rows = await _client
        .from('request_events')
        .select()
        .eq('request_id', requestId)
        .order('created_at')
        .order('id');
    return rows.map(_workflowMapper.eventFromRow).toList(growable: false);
  }

  @override
  Future<void> updateStatus(String requestId, RequestState state) async {
    final current = await getRequestById(requestId);
    if (current == null) throw StateError('No se encontró la solicitud.');
    RequestStateMachine.ensureTransition(current.state, state);
    await _client.rpc(
      'transition_request_status',
      params: {
        'p_request_id': requestId,
        'p_expected_status': RequestStatusMapper.toDatabase(current.state),
        'p_new_status': RequestStatusMapper.toDatabase(state),
        'p_event_type': null,
        'p_payload': const <String, dynamic>{},
      },
    );
  }

  @override
  Future<void> updateSchedule(String requestId, DateTime? scheduledAt) async {
    await _client.rpc(
      'update_request_schedule',
      params: {
        'p_request_id': requestId,
        'p_scheduled_at': scheduledAt?.toUtc().toIso8601String(),
      },
    );
  }

  @override
  Stream<RequestStatus> watchStatus(String requestId) {
    late final StreamController<RequestStatus> controller;
    late final RealtimeChannel channel;
    RequestStatus? lastStatus;

    void addStatus(Object? value) {
      if (controller.isClosed) return;
      final status = RequestStatusMapper.fromDatabase(value);
      if (status != lastStatus) {
        lastStatus = status;
        controller.add(status);
      }
    }

    Future<void> loadInitial() async {
      try {
        final row = await _client
            .from('service_requests')
            .select('status')
            .eq('id', requestId)
            .single();
        addStatus(row['status']);
      } catch (error, stackTrace) {
        if (!controller.isClosed) controller.addError(error, stackTrace);
      }
    }

    controller = StreamController<RequestStatus>();
    channel = _client
        .channel('request-status:$requestId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'service_requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: requestId,
          ),
          callback: (payload) => addStatus(payload.newRecord['status']),
        )
        .subscribe((status, error) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            unawaited(loadInitial());
          } else if (status == RealtimeSubscribeStatus.channelError ||
              status == RealtimeSubscribeStatus.timedOut) {
            controller.addError(
              StateError('No fue posible sincronizar la solicitud.'),
            );
          }
        });
    controller.onCancel = () => _client.removeChannel(channel);
    return controller.stream;
  }

  @override
  Stream<List<TimelineEvent>> watchTimeline(String requestId) {
    final buffer = RequestEventBuffer();
    late final StreamController<List<TimelineEvent>> controller;
    late final RealtimeChannel channel;

    void addEvents(Iterable<TimelineEvent> events) {
      if (!controller.isClosed) controller.add(buffer.merge(events));
    }

    Future<void> loadInitial() async {
      try {
        addEvents(await getTimeline(requestId));
      } catch (error, stackTrace) {
        if (!controller.isClosed) controller.addError(error, stackTrace);
      }
    }

    controller = StreamController<List<TimelineEvent>>();
    channel = _client
        .channel('request-timeline:$requestId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'request_events',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'request_id',
            value: requestId,
          ),
          callback: (payload) =>
              addEvents([_workflowMapper.eventFromRow(payload.newRecord)]),
        )
        .subscribe((status, error) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            unawaited(loadInitial());
          } else if (status == RealtimeSubscribeStatus.channelError ||
              status == RealtimeSubscribeStatus.timedOut) {
            controller.addError(
              StateError('No fue posible sincronizar la línea de tiempo.'),
            );
          }
        });
    controller.onCancel = () => _client.removeChannel(channel);
    return controller.stream;
  }

  Stream<List<ServiceRequest>> _watchRequestList({
    required String channelName,
    required Future<List<ServiceRequest>> Function() load,
  }) {
    late final StreamController<List<ServiceRequest>> controller;
    late final RealtimeChannel channel;
    var loading = false;

    Future<void> refresh() async {
      if (loading || controller.isClosed) return;
      loading = true;
      try {
        controller.add(await load());
      } catch (error, stackTrace) {
        controller.addError(error, stackTrace);
      } finally {
        loading = false;
      }
    }

    controller = StreamController<List<ServiceRequest>>();
    channel = _client
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'service_requests',
          callback: (_) => refresh(),
        )
        .subscribe((status, error) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            unawaited(refresh());
          } else if (status == RealtimeSubscribeStatus.channelError ||
              status == RealtimeSubscribeStatus.timedOut) {
            controller.addError(
              StateError('No fue posible sincronizar las solicitudes.'),
            );
          }
        });
    controller.onCancel = () => _client.removeChannel(channel);
    return controller.stream;
  }

  @override
  Future<void> transitionStatus({
    required String requestId,
    required RequestStatus nextStatus,
    required String eventType,
    Map<String, dynamic> payload = const {},
  }) async {
    final current = await getRequestById(requestId);
    if (current == null) throw StateError('No se encontró la solicitud.');
    RequestStateMachine.ensureTransition(current.state, nextStatus);
    await _client.rpc(
      'transition_request_status',
      params: {
        'p_request_id': requestId,
        'p_expected_status': RequestStatusMapper.toDatabase(current.state),
        'p_new_status': RequestStatusMapper.toDatabase(nextStatus),
        'p_event_type': eventType,
        'p_payload': payload,
      },
    );
  }

  @override
  Future<void> appendEvent({
    required String requestId,
    required String eventType,
    Map<String, dynamic> payload = const {},
  }) {
    if (eventType != 'schedule_proposed') {
      throw StateError('El evento de solicitud no está permitido.');
    }
    return _client.rpc(
      'propose_request_schedule',
      params: {'p_request_id': requestId, 'p_payload': payload},
    );
  }
}

typedef SupabaseServiceRequestsRepository = ServiceRequestsRepositorySupabase;

class ConversationsRepositorySupabase implements ConversationsRepository {
  ConversationsRepositorySupabase(
    this._client, [
    this._mapper = const ConversationSupabaseMapper(),
  ]);

  final SupabaseClient _client;
  final ConversationSupabaseMapper _mapper;
  final Map<String, Conversation> _conversations = {};
  final Map<String, _RealtimeConversation> _subscriptions = {};

  @override
  Future<Conversation> getOrCreateConversation({
    required String serviceRequestId,
    required String customerId,
    required String professionalId,
  }) async {
    var row = await _client
        .from('conversations')
        .select()
        .eq('service_request_id', serviceRequestId)
        .maybeSingle();
    if (row == null) {
      try {
        row = await _client
            .from('conversations')
            .insert({
              'service_request_id': serviceRequestId,
              'customer_id': customerId,
              'professional_id': professionalId,
            })
            .select()
            .single();
      } on PostgrestException catch (error) {
        if (error.code != '23505') rethrow;
        row = await _client
            .from('conversations')
            .select()
            .eq('service_request_id', serviceRequestId)
            .single();
      }
    }
    final conversation = _mapper.conversationFromRow(row);
    _conversations[conversation.id] = conversation;
    return conversation;
  }

  @override
  Future<List<ConversationMessage>> listMessages(String conversationId) async {
    final conversation = _requireConversation(conversationId);
    final rows = await _client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at')
        .order('id');
    return rows
        .map((row) => _message(row, conversation))
        .toList(growable: false);
  }

  @override
  Future<ConversationMessage> sendTextMessage({
    required String conversationId,
    required String serviceRequestId,
    required String senderId,
    required MessageAuthor author,
    required String body,
  }) => _insertMessage(
    conversationId: conversationId,
    senderId: senderId,
    type: 'text',
    body: body,
  );

  @override
  Future<ConversationMessage> sendSystemMessage({
    required String conversationId,
    required String serviceRequestId,
    required String body,
    Map<String, dynamic>? metadata,
  }) => _insertMessage(
    conversationId: conversationId,
    senderId: null,
    type: 'system',
    body: body,
    metadata: metadata,
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
  }) => _insertMessage(
    conversationId: conversationId,
    senderId: senderId,
    type: 'actionCard',
    body: body,
    metadata: {...metadata, 'action_type': _mapper.actionType(actionType)},
  );

  Future<ConversationMessage> _insertMessage({
    required String conversationId,
    required String? senderId,
    required String type,
    required String? body,
    Map<String, dynamic>? metadata,
  }) async {
    final conversation = _requireConversation(conversationId);
    final row = await _client
        .from('messages')
        .insert(
          _mapper.messageToInsert(
            conversationId: conversationId,
            senderId: senderId,
            type: type,
            body: body,
            metadata: metadata,
          ),
        )
        .select()
        .single();
    final message = _message(row, conversation);
    _subscriptions[conversationId]?.add(message);
    return message;
  }

  @override
  Stream<List<ConversationMessage>> watchMessages(String conversationId) {
    final existing = _subscriptions[conversationId];
    if (existing != null) return existing.messages.stream;
    final conversation = _requireConversation(conversationId);
    final realtime = _RealtimeConversation();
    _subscriptions[conversationId] = realtime;
    realtime.connection.add(ConversationConnectionStatus.connecting);
    () async {
      try {
        final channel = _client
            .channel('messages:$conversationId')
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'messages',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'conversation_id',
                value: conversationId,
              ),
              callback: (payload) {
                if (!realtime.disposed) {
                  realtime.add(_message(payload.newRecord, conversation));
                }
              },
            )
            .subscribe((status, error) {
              if (realtime.disposed) return;
              if (status == RealtimeSubscribeStatus.subscribed) {
                realtime.connection.add(ConversationConnectionStatus.connected);
                unawaited(
                  listMessages(conversationId).then(realtime.addAll).catchError(
                    (Object error, StackTrace stackTrace) {
                      if (!realtime.disposed) {
                        realtime.messages.addError(error, stackTrace);
                      }
                    },
                  ),
                );
              } else {
                realtime.connection.add(
                  ConversationConnectionStatus.disconnected,
                );
              }
            });
        realtime.channel = channel;
        realtime.addAll(await listMessages(conversationId));
      } catch (error, stackTrace) {
        if (!realtime.disposed) {
          realtime.messages.addError(error, stackTrace);
          realtime.connection.add(ConversationConnectionStatus.disconnected);
        }
      }
    }();
    return realtime.messages.stream;
  }

  @override
  Stream<ConversationConnectionStatus> watchConnection(String conversationId) {
    watchMessages(conversationId);
    return _subscriptions[conversationId]!.connection.stream;
  }

  @override
  Future<void> disposeConversation(String conversationId) async {
    final realtime = _subscriptions.remove(conversationId);
    if (realtime == null) return;
    realtime.disposed = true;
    final channel = realtime.channel;
    if (channel != null) await _client.removeChannel(channel);
    await realtime.messages.close();
    await realtime.connection.close();
  }

  @override
  Future<void> dispose() async {
    for (final id in _subscriptions.keys.toList()) {
      await disposeConversation(id);
    }
  }

  @override
  Future<List<ConversationMessage>> getMessages(String requestId) async {
    final row = await _client
        .from('conversations')
        .select()
        .eq('service_request_id', requestId)
        .maybeSingle();
    if (row == null) return const [];
    final conversation = _mapper.conversationFromRow(row);
    _conversations[conversation.id] = conversation;
    return listMessages(conversation.id);
  }

  @override
  Future<void> sendMessage(ConversationMessage message) async {
    final conversationId = message.conversationId;
    if (conversationId == null) {
      throw StateError('La conversación no está disponible.');
    }
    if (message.type == ConversationMessageType.text) {
      await sendTextMessage(
        conversationId: conversationId,
        serviceRequestId: message.requestId,
        senderId: message.senderId!,
        author: message.author,
        body: message.text,
      );
    } else if (message.type == ConversationMessageType.system) {
      await sendSystemMessage(
        conversationId: conversationId,
        serviceRequestId: message.requestId,
        body: message.text,
        metadata: message.metadata,
      );
    } else {
      await sendActionCard(
        conversationId: conversationId,
        serviceRequestId: message.requestId,
        senderId: message.senderId!,
        author: message.author,
        actionType: message.type,
        body: message.text,
        metadata: message.metadata ?? const {},
      );
    }
  }

  Conversation _requireConversation(String id) {
    final conversation = _conversations[id];
    if (conversation == null) {
      throw StateError('La conversación no está disponible.');
    }
    return conversation;
  }

  ConversationMessage _message(
    Map<String, dynamic> row,
    Conversation conversation,
  ) => _mapper.messageFromRow(
    row,
    serviceRequestId: conversation.serviceRequestId,
    customerId: conversation.customerId,
    professionalId: conversation.professionalId,
  );
}

typedef SupabaseConversationsRepository = ConversationsRepositorySupabase;

class _RealtimeConversation {
  final messages = StreamController<List<ConversationMessage>>.broadcast();
  final connection = StreamController<ConversationConnectionStatus>.broadcast();
  final buffer = ConversationMessageBuffer();
  RealtimeChannel? channel;
  bool disposed = false;

  void add(ConversationMessage message) => addAll([message]);

  void addAll(Iterable<ConversationMessage> values) {
    if (!disposed) messages.add(buffer.merge(values));
  }
}

class QuotationsRepositorySupabase implements QuotationsRepository {
  QuotationsRepositorySupabase(
    this._client, [
    this._mapper = const RequestWorkflowSupabaseMapper(),
  ]);

  final SupabaseClient _client;
  final RequestWorkflowSupabaseMapper _mapper;

  @override
  Future<Quotation?> getQuotation(String requestId) async {
    final row = await _client
        .from('quotations')
        .select()
        .eq('request_id', requestId)
        .maybeSingle();
    return row == null ? null : _mapper.quotationFromRow(row);
  }

  @override
  Future<void> sendQuotation(Quotation quotation) async {
    final current = await _requestStatus(quotation.requestId);
    RequestStateMachine.ensureTransition(current, RequestState.quoted);
    await _client.rpc(
      'create_request_quotation',
      params: {
        'p_request_id': quotation.requestId,
        'p_expected_status': RequestStatusMapper.toDatabase(current),
        'p_price': quotation.totalAmount,
        'p_description': quotation.workDescription,
        'p_estimated_duration': quotation.estimatedDuration,
      },
    );
  }

  @override
  Future<void> acceptQuotation(String requestId) async {
    await _resolve(requestId, QuotationStatus.accepted);
  }

  @override
  Future<void> rejectQuotation(String requestId) async {
    await _resolve(requestId, QuotationStatus.rejected);
  }

  Future<void> _resolve(String requestId, QuotationStatus resolution) async {
    final current = await _requestStatus(requestId);
    final next = resolution == QuotationStatus.accepted
        ? RequestState.accepted
        : RequestState.cancelled;
    RequestStateMachine.ensureTransition(current, next);
    await _client.rpc(
      'resolve_request_quotation',
      params: {
        'p_request_id': requestId,
        'p_expected_status': RequestStatusMapper.toDatabase(current),
        'p_resolution': resolution.name,
      },
    );
  }

  @override
  Stream<Quotation?> watchQuotation(String requestId) => _client
      .from('quotations')
      .stream(primaryKey: ['request_id'])
      .eq('request_id', requestId)
      .map(
        (rows) => rows.isEmpty ? null : _mapper.quotationFromRow(rows.single),
      );

  Future<RequestStatus> _requestStatus(String requestId) async {
    final row = await _client
        .from('service_requests')
        .select('status')
        .eq('id', requestId)
        .single();
    return RequestStatusMapper.fromDatabase(row['status']);
  }
}

typedef SupabaseQuotationsRepository = QuotationsRepositorySupabase;

class SupabaseRatingsRepository implements RatingsRepository {
  SupabaseRatingsRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<ServiceRating?> getRating(String requestId) async {
    final row = await _client
        .from('ratings')
        .select()
        .eq('request_id', requestId)
        .maybeSingle();
    return row == null ? null : _rating(row);
  }

  @override
  Future<ProfessionalRatingSummary> getProfessionalSummary(
    String professionalId,
  ) async {
    final row = await _client
        .from('professional_rating_summaries')
        .select()
        .eq('professional_id', professionalId)
        .maybeSingle();
    if (row == null) {
      return const ProfessionalRatingSummary(
        averageRating: 0,
        reviewCount: 0,
        completedJobsCount: 0,
      );
    }
    return ProfessionalRatingSummary(
      averageRating: (row['average_rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (row['review_count'] as num?)?.toInt() ?? 0,
      completedJobsCount: (row['completed_jobs_count'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<void> submitRating(ServiceRating rating) async {
    await _client.rpc(
      'submit_service_rating',
      params: {
        'p_request_id': rating.requestId,
        'p_professional_id': rating.professionalId,
        'p_stars': rating.stars,
        'p_comment': rating.comment,
      },
    );
  }
}

ProfessionalProfile _professional(
  Map<String, dynamic> row, {
  String Function(String path)? portfolioUrl,
}) {
  final reviews = (row['reviews'] as List? ?? const [])
      .map((item) => Map<String, dynamic>.from(item as Map))
      .map(
        (item) => ProfessionalReview(
          stars: (item['stars'] as num).toInt(),
          comment: item['comment'] as String?,
          createdAt: DateTime.parse(item['created_at'] as String),
        ),
      )
      .toList(growable: false);
  return ProfessionalProfile(
    id: row['id'] as String,
    user: AppUser(id: row['id'] as String, name: row['display_name'] as String),
    profession: row['profession'] as String,
    rating: (row['rating'] as num?)?.toDouble() ?? 0,
    reviewCount: (row['review_count'] as num?)?.toInt() ?? 0,
    location: row['location'] as String? ?? '',
    isVerified: row['verification_status'] == null
        ? true
        : row['verification_status'] == 'verified',
    avatarUrl: row['avatar_url'] as String?,
    biography: row['biography'] as String? ?? '',
    services: List<String>.from(row['services'] as List? ?? const []),
    experienceYears: (row['experience_years'] as num?)?.toInt() ?? 0,
    experienceDescription: row['experience_description'] as String? ?? '',
    portfolio: _portfolioUrls(row['portfolio'], portfolioUrl: portfolioUrl),
    completedJobsCount: (row['completed_jobs_count'] as num?)?.toInt() ?? 0,
    reviews: reviews,
    coverageArea: row['coverage_area'] as String? ?? '',
  );
}

List<String> _portfolioUrls(
  Object? value, {
  String Function(String path)? portfolioUrl,
}) {
  if (value is! List) return const [];
  return value
      .map((item) {
        if (item is String) return item;
        if (item is Map) {
          final path = item['path'] as String?;
          if (path != null && portfolioUrl != null) return portfolioUrl(path);
          return item['url'] as String?;
        }
        return null;
      })
      .whereType<String>()
      .where((url) => url.startsWith('https://'))
      .toList(growable: false);
}

List<ProfessionalVerificationDocument> _verificationDocuments(Object? value) =>
    (value as List? ?? const [])
        .map(
          (item) => item is Map
              ? Map<String, dynamic>.from(item)
              : <String, dynamic>{'name': 'Documento heredado'},
        )
        .map(
          (item) => ProfessionalVerificationDocument(
            path: item['path'] as String?,
            name: item['name'] as String? ?? 'Documento heredado',
            mimeType:
                item['mime_type'] as String? ?? 'application/octet-stream',
            size: (item['size'] as num?)?.toInt() ?? 0,
          ),
        )
        .toList(growable: false);

String _extension(String mimeType) => switch (mimeType) {
  'image/jpeg' => '.jpg',
  'image/png' => '.png',
  'image/webp' => '.webp',
  'application/pdf' => '.pdf',
  _ => '',
};

String? _publicObjectPath(String url, String bucket) {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.scheme != 'https') return null;
  final segments = uri.pathSegments;
  final index = segments.indexOf(bucket);
  if (index < 0 || index == segments.length - 1) return null;
  return segments.sublist(index + 1).join('/');
}

ServiceRating _rating(Map<String, dynamic> row) => ServiceRating(
  requestId: row['request_id'] as String,
  professionalId: row['professional_id'] as String,
  stars: (row['stars'] as num).toInt(),
  comment: row['comment'] as String?,
);
