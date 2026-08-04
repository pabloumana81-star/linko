import 'package:linko_admin/features/admin/domain/admin_professional.dart';
import 'package:linko_admin/features/admin/domain/admin_professionals_repository.dart';
import 'package:linko_admin/features/admin/domain/admin_user.dart';
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
        (row) => _professional(Map<String, dynamic>.from(row as Map)),
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
      professional: _professional(
        Map<String, dynamic>.from(data['professional'] as Map),
      ),
      profession: data['profession'] as String,
      location: data['location'] as String,
      skills: List<String>.from(data['skills'] as List? ?? const []),
      portfolio: List<String>.from(data['portfolio'] as List? ?? const []),
      reviewCount: (data['review_count'] as num).toInt(),
      reviews: List<String>.from(data['reviews'] as List? ?? const []),
      cancelledJobs: (data['cancelled_jobs'] as num).toInt(),
      currentRequests: List<String>.from(
        data['current_requests'] as List? ?? const [],
      ),
      conversationCount: (data['conversation_count'] as num).toInt(),
      timeline: (data['timeline'] as List? ?? const [])
          .map((row) => _audit(Map<String, dynamic>.from(row as Map)))
          .toList(),
    );
  }

  @override
  Future<void> approveVerification(String id) =>
      _action(id, 'verificationApproved');
  @override
  Future<void> rejectVerification(String id) =>
      _action(id, 'verificationRejected');
  @override
  Future<void> suspendProfessional(String id) =>
      _action(id, 'accountSuspended');
  @override
  Future<void> reactivateProfessional(String id) =>
      _action(id, 'accountReactivated');

  @override
  Future<List<ProfessionalAuditEntry>> getAuditLog(String id) async =>
      (await getProfessional(id))?.timeline ?? const [];

  Future<void> _action(String id, String action) async {
    await _client.rpc(
      'perform_admin_professional_action',
      params: {'p_professional_id': id, 'p_action': action},
    );
  }

  AdminProfessional _professional(Map<String, dynamic> row) =>
      AdminProfessional(
        id: row['id'] as String,
        name: row['name'] as String,
        email: row['email'] as String?,
        photoUrl: row['photo_url'] as String?,
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

  ProfessionalAuditEntry _audit(Map<String, dynamic> row) =>
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
