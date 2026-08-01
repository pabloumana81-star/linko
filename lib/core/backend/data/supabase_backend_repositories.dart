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

class SupabaseServiceRequestsRepository implements ServiceRequestsRepository {
  SupabaseServiceRequestsRepository(this._client);

  final SupabaseClient _client;

  static const _selection =
      '*,customer:profiles!customer_id(id,display_name,member_since_label),'
      'professional:professional_profiles!professional_id('
      'id,user_id,display_name,profession,rating,review_count,location)';

  @override
  Future<void> createRequest(ServiceRequest request) async {
    await _client.from('service_requests').insert({
      'id': request.id,
      'customer_id': request.customer.id,
      'professional_id': request.professional.id,
      'service_name': request.serviceName,
      'category': request.category.name,
      'description': request.description,
      'location': request.location,
      'availability_label': request.availabilityLabel,
      'status': request.state.name,
      'attached_photo_count': request.attachedPhotoCount,
    });
  }

  @override
  Future<List<ServiceRequest>> getCustomerRequests(String customerId) async {
    final rows = await _client
        .from('service_requests')
        .select(_selection)
        .eq('customer_id', customerId)
        .order('updated_at', ascending: false);
    return rows.map(_serviceRequest).toList(growable: false);
  }

  @override
  Future<List<ServiceRequest>> getProfessionalRequests(
    String professionalId,
  ) async {
    final rows = await _client
        .from('service_requests')
        .select(_selection)
        .eq('professional_id', professionalId)
        .order('updated_at', ascending: false);
    return rows.map(_serviceRequest).toList(growable: false);
  }

  @override
  Future<ServiceRequest?> getRequestById(String requestId) async {
    final row = await _client
        .from('service_requests')
        .select(_selection)
        .eq('id', requestId)
        .maybeSingle();
    return row == null ? null : _serviceRequest(row);
  }

  @override
  Future<List<TimelineEvent>> getTimeline(String requestId) async {
    final rows = await _client
        .from('timeline_events')
        .select()
        .eq('request_id', requestId)
        .order('created_at');
    return rows.map(_timelineEvent).toList(growable: false);
  }

  @override
  Future<void> updateStatus(String requestId, RequestState state) async {
    await _client.rpc(
      'update_request_status',
      params: {'p_request_id': requestId, 'p_status': state.name},
    );
  }
}

class SupabaseConversationsRepository implements ConversationsRepository {
  SupabaseConversationsRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<ConversationMessage>> getMessages(String requestId) async {
    final rows = await _client
        .from('conversation_messages')
        .select()
        .eq('request_id', requestId)
        .order('created_at');
    return rows.map(_conversationMessage).toList(growable: false);
  }

  @override
  Future<void> sendMessage(ConversationMessage message) async {
    await _client.from('conversation_messages').insert({
      'id': message.id,
      'request_id': message.requestId,
      'author': message.author.name,
      'body': message.text,
      'type': message.type.name,
      'schedule_label': message.scheduleLabel,
      'schedule_status': message.scheduleStatus?.name,
    });
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

ServiceRequest _serviceRequest(Map<String, dynamic> row) {
  final customer = row['customer'] as Map<String, dynamic>;
  final professional = row['professional'] as Map<String, dynamic>;
  return ServiceRequest(
    id: row['id'] as String,
    customer: AppUser(
      id: customer['id'] as String,
      name: customer['display_name'] as String,
    ),
    professional: _professional(professional),
    serviceName: row['service_name'] as String,
    category: _enumByName(ServiceCategory.values, row['category'] as String),
    description: row['description'] as String,
    location: row['location'] as String,
    availabilityLabel: row['availability_label'] as String,
    state: _enumByName(RequestState.values, row['status'] as String),
    updatedAt: DateTime.parse(row['updated_at'] as String),
    createdAtLabel: row['created_at_label'] as String? ?? 'Recientemente',
    memberSinceLabel:
        customer['member_since_label'] as String? ?? 'Miembro de LinkO',
    attachedPhotoCount: (row['attached_photo_count'] as num?)?.toInt() ?? 0,
  );
}

ConversationMessage _conversationMessage(Map<String, dynamic> row) {
  final scheduleStatus = row['schedule_status'] as String?;
  return ConversationMessage(
    id: row['id'] as String,
    requestId: row['request_id'] as String,
    author: _enumByName(MessageAuthor.values, row['author'] as String),
    text: row['body'] as String,
    timeLabel: row['time_label'] as String? ?? 'Ahora',
    type: _enumByName(
      ConversationMessageType.values,
      row['type'] as String? ?? 'text',
    ),
    scheduleLabel: row['schedule_label'] as String?,
    scheduleStatus: scheduleStatus == null
        ? null
        : _enumByName(ScheduleProposalStatus.values, scheduleStatus),
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

TimelineEvent _timelineEvent(Map<String, dynamic> row) => TimelineEvent(
  id: row['id'] as String,
  requestId: row['request_id'] as String,
  stage: _enumByName(TimelineStage.values, row['stage'] as String),
  title: row['title'] as String,
  description: row['description'] as String,
  dateLabel: row['date_label'] as String?,
);

T _enumByName<T extends Enum>(List<T> values, String name) {
  return values.firstWhere(
    (value) => value.name == name,
    orElse: () => throw FormatException('Valor de enum desconocido: $name'),
  );
}
