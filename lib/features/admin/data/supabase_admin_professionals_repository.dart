import 'package:linko/features/admin/domain/admin_professional.dart';
import 'package:linko/features/admin/domain/admin_professionals_repository.dart';
import 'package:linko/features/admin/domain/admin_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAdminProfessionalsRepository
    implements AdminProfessionalsRepository {
  SupabaseAdminProfessionalsRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<AdminProfessional>> listProfessionals(
    AdminProfessionalQuery query,
  ) async {
    final response = await _client.rpc(
      'list_admin_professionals',
      params: {
        'p_search': query.search.trim(),
        'p_verification': query.verification?.name,
        'p_account_status': query.accountStatus?.name,
        'p_rating_filter': query.rating?.name,
      },
    );
    return List.unmodifiable(
      (response as List).map(
        (row) => AdminProfessionalSupabaseMapper.professional(
          Map<String, dynamic>.from(row as Map),
        ),
      ),
    );
  }

  @override
  Future<AdminProfessionalDetail?> getProfessional(
    String professionalId,
  ) async {
    final response = await _client.rpc(
      'get_admin_professional_detail',
      params: {'p_professional_id': professionalId},
    );
    if (response == null) return null;
    final data = Map<String, dynamic>.from(response as Map);
    return AdminProfessionalDetail(
      professional: AdminProfessionalSupabaseMapper.professional(
        Map<String, dynamic>.from(data['professional'] as Map),
      ),
      profession: data['profession'] as String,
      location: data['location'] as String,
      coverageArea: data['coverage_area'] as String? ?? '',
      experienceYears: (data['experience_years'] as num?)?.toInt() ?? 0,
      skills: List<String>.from(data['skills'] as List? ?? const []),
      portfolio: _textItems(data['portfolio']),
      verificationDocuments:
          (data['verification_documents'] as List? ?? const [])
              .map(
                (document) => document is Map
                    ? (document['url'] ?? document['name'] ?? '').toString()
                    : document.toString(),
              )
              .where((value) => value.isNotEmpty)
              .toList(growable: false),
      reviewCount: (data['review_count'] as num).toInt(),
      reviews: List<String>.from(data['reviews'] as List? ?? const []),
      cancelledJobs: (data['cancelled_jobs'] as num).toInt(),
      currentRequests: List<String>.from(
        data['current_requests'] as List? ?? const [],
      ),
      conversationCount: (data['conversation_count'] as num).toInt(),
      timeline: (data['timeline'] as List? ?? const [])
          .map(
            (row) => AdminProfessionalSupabaseMapper.audit(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList(),
    );
  }

  @override
  Future<void> approveVerification(String id) =>
      _action(id, 'verificationApproved');
  @override
  Future<void> rejectVerification(String id, String reason) =>
      _action(id, 'verificationRejected', reason: reason);
  @override
  Future<void> requestAdditionalInformation(String id, String reason) =>
      _action(id, 'additionalInformationRequested', reason: reason);
  @override
  Future<void> suspendProfessional(String id) =>
      _action(id, 'accountSuspended');
  @override
  Future<void> reactivateProfessional(String id) =>
      _action(id, 'accountReactivated');

  @override
  Future<List<ProfessionalAuditEntry>> getAuditLog(String id) async =>
      (await getProfessional(id))?.timeline ?? const [];

  Future<void> _action(String id, String action, {String? reason}) async {
    await _client.rpc(
      'perform_admin_professional_action',
      params: {'p_professional_id': id, 'p_action': action, 'p_reason': reason},
    );
  }

  List<String> _textItems(Object? value) => (value as List? ?? const [])
      .map(
        (item) => item is Map
            ? (item['url'] ?? item['name'] ?? item['title'] ?? '').toString()
            : item.toString(),
      )
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

class AdminProfessionalSupabaseMapper {
  const AdminProfessionalSupabaseMapper._();

  static AdminProfessional professional(Map<String, dynamic> row) =>
      AdminProfessional(
        id: row['id'] as String,
        name: row['name'] as String,
        email: row['email'] as String?,
        photoUrl: row['photo_url'] as String?,
        categories: List<String>.from(row['categories'] as List? ?? const []),
        verification: ProfessionalVerificationStatus.values.byName(
          row['verification'] as String,
        ),
        averageRating: (row['average_rating'] as num).toDouble(),
        completedJobs: (row['completed_jobs'] as num).toInt(),
        activeJobs: (row['active_jobs'] as num).toInt(),
        registeredAt: DateTime.parse(row['registered_at'] as String).toLocal(),
        accountStatus: AdminAccountStatus.values.byName(
          row['account_status'] as String,
        ),
      );

  static ProfessionalAuditEntry audit(Map<String, dynamic> row) =>
      ProfessionalAuditEntry(
        id: row['id'] as String,
        adminId: row['admin_id'] as String,
        professionalId: row['professional_id'] as String,
        action: ProfessionalAuditAction.values.byName(row['action'] as String),
        previousValue: row['previous_value'] as String,
        newValue: row['new_value'] as String,
        timestamp: DateTime.parse(row['timestamp'] as String).toLocal(),
      );
}
