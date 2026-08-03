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
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthenticationRepository implements AuthenticationRepository {
  SupabaseAuthenticationRepository(this._client, {this.redirectTo});

  final SupabaseClient _client;
  final String? redirectTo;

  @override
  Stream<AppUserProfile?> authStateChanges() => _client.auth.onAuthStateChange
      .map((event) => event.session?.user)
      .map((user) => user == null ? null : _appUserProfile(user));

  @override
  Future<AppUserProfile?> restoreSession() async {
    final user = _client.auth.currentUser;
    return user == null ? null : _appUserProfile(user);
  }

  @override
  Future<void> sendEmailLink(String email) {
    return _client.auth.signInWithOtp(
      email: email,
      emailRedirectTo: redirectTo,
    );
  }

  @override
  Future<AppUserProfile?> signInWithApple() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: redirectTo,
    );
    final user = _client.auth.currentUser;
    return user == null ? null : _appUserProfile(user);
  }

  @override
  Future<AppUserProfile?> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectTo,
    );
    final user = _client.auth.currentUser;
    return user == null ? null : _appUserProfile(user);
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

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
      createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now().toUtc(),
    );
  }
}

class ProfileRepositorySupabase implements ProfileRepository {
  ProfileRepositorySupabase(this._client);

  final SupabaseClient _client;

  static const _selection =
      'id,email,display_name,avatar_url,active_mode,created_at,updated_at';

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
  }) async {
    final values = <String, Object?>{};
    if (displayName != null) values['display_name'] = displayName;
    if (avatarUrl != null) values['avatar_url'] = avatarUrl;
    if (activeMode != null) values['active_mode'] = _modeValue(activeMode);
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

  static const _selection =
      'id,user_id,display_name,profession,rating,review_count,location';

  @override
  Future<List<ProfessionalProfile>> getProfessionals() async {
    final rows = await _client
        .from('professional_profiles')
        .select(_selection)
        .order('display_name');
    return rows.map(_professional).toList(growable: false);
  }

  @override
  Future<ProfessionalProfile?> getProfessionalById(
    String professionalId,
  ) async {
    final row = await _client
        .from('professional_profiles')
        .select(_selection)
        .eq('id', professionalId)
        .maybeSingle();
    return row == null ? null : _professional(row);
  }
}

class ServiceRequestsRepositorySupabase implements ServiceRequestsRepository {
  ServiceRequestsRepositorySupabase(
    this._client, [
    this._mapper = const ServiceRequestSupabaseMapper(),
  ]);

  final SupabaseClient _client;
  final ServiceRequestSupabaseMapper _mapper;

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
    return const [];
  }

  @override
  Future<void> updateStatus(String requestId, RequestState state) async {
    await _client
        .from('service_requests')
        .update({'status': RequestStatusMapper.toDatabase(state)})
        .eq('id', requestId);
  }

  @override
  Future<void> updateSchedule(String requestId, DateTime? scheduledAt) async {
    await _client
        .from('service_requests')
        .update({'scheduled_at': scheduledAt?.toUtc().toIso8601String()})
        .eq('id', requestId);
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

class SupabaseQuotationsRepository implements QuotationsRepository {
  SupabaseQuotationsRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<Quotation?> getQuotation(String requestId) async {
    final row = await _client
        .from('quotations')
        .select()
        .eq('request_id', requestId)
        .maybeSingle();
    return row == null ? null : _quotation(row);
  }

  @override
  Future<void> sendQuotation(Quotation quotation) async {
    await _client.rpc(
      'send_quotation',
      params: {
        'p_request_id': quotation.requestId,
        'p_labor_amount': quotation.laborAmount,
        'p_materials_amount': quotation.materialsAmount,
        'p_work_description': quotation.workDescription,
        'p_estimated_duration': quotation.estimatedDuration,
        'p_start_timing': quotation.startTiming,
        'p_validity_days': quotation.validityDays,
        'p_warranty_label': quotation.warrantyLabel,
      },
    );
  }

  @override
  Future<void> acceptQuotation(String requestId) async {
    await _client.rpc('accept_quotation', params: {'p_request_id': requestId});
  }
}

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

ProfessionalProfile _professional(Map<String, dynamic> row) {
  return ProfessionalProfile(
    id: row['id'] as String,
    user: AppUser(
      id: row['user_id'] as String,
      name: row['display_name'] as String,
    ),
    profession: row['profession'] as String,
    rating: (row['rating'] as num?)?.toDouble() ?? 0,
    reviewCount: (row['review_count'] as num?)?.toInt() ?? 0,
    location: row['location'] as String? ?? '',
  );
}

Quotation _quotation(Map<String, dynamic> row) => Quotation(
  requestId: row['request_id'] as String,
  laborAmount: (row['labor_amount'] as num).toInt(),
  materialsAmount: (row['materials_amount'] as num).toInt(),
  workDescription: row['work_description'] as String,
  estimatedDuration: row['estimated_duration'] as String,
  startTiming: row['start_timing'] as String,
  validityDays: (row['validity_days'] as num).toInt(),
  warrantyLabel:
      row['warranty_label'] as String? ?? '30 días sobre el trabajo realizado',
);

ServiceRating _rating(Map<String, dynamic> row) => ServiceRating(
  requestId: row['request_id'] as String,
  professionalId: row['professional_id'] as String,
  stars: (row['stars'] as num).toInt(),
  comment: row['comment'] as String?,
);
