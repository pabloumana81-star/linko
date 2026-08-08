import 'package:linko_admin/features/admin/data/mock_admin_state.dart';
import 'package:linko/features/admin/domain/admin_professional.dart';
import 'package:linko/features/admin/domain/admin_professionals_repository.dart';
import 'package:linko/features/admin/domain/admin_user.dart';
import 'package:linko/features/requests/domain/models/request_state.dart';
import 'package:linko/features/requests/domain/models/service_rating.dart';
import 'package:linko/features/requests/domain/repositories/request_repository.dart';

class MockAdminProfessionalsRepository implements AdminProfessionalsRepository {
  MockAdminProfessionalsRepository(
    this._requests,
    this._state, {
    DateTime Function()? clock,
    this.adminId = 'admin-user',
  }) : _clock = clock ?? DateTime.now;

  final RequestRepository _requests;
  final MockAdminState _state;
  final DateTime Function() _clock;
  final String adminId;

  @override
  Future<List<AdminProfessional>> listProfessionals(
    AdminProfessionalQuery query,
  ) async {
    final search = query.search.trim().toLowerCase();
    final items = _professionals().values.where((item) {
      final matchesSearch =
          search.isEmpty ||
          item.name.toLowerCase().contains(search) ||
          (item.email?.toLowerCase().contains(search) ?? false) ||
          item.id.toLowerCase().contains(search);
      final matchesRating = switch (query.rating) {
        ProfessionalRatingFilter.topRated => item.averageRating >= 4.8,
        ProfessionalRatingFilter.lowRated => item.averageRating < 4.8,
        null => true,
      };
      return matchesSearch &&
          (query.verification == null ||
              item.verification == query.verification) &&
          (query.accountStatus == null ||
              item.accountStatus == query.accountStatus) &&
          matchesRating;
    }).toList()..sort((left, right) => left.name.compareTo(right.name));
    return List.unmodifiable(items);
  }

  @override
  Future<AdminProfessionalDetail?> getProfessional(
    String professionalId,
  ) async {
    final professional = _professionals()[professionalId];
    if (professional == null) return null;
    final requests = _requests.getProfessionalRequests(professionalId).toList();
    final profile = requests.first.professional;
    final ratings = requests
        .map((request) => _requests.getRating(request.id))
        .whereType<ServiceRating>()
        .toList();
    return AdminProfessionalDetail(
      professional: professional,
      profession: profile.profession,
      location: profile.location,
      coverageArea: 'Gran Área Metropolitana',
      experienceYears: 5,
      skills: [profile.profession],
      portfolio: const [],
      verificationDocuments: const ['Documento de identidad'],
      reviewCount: profile.reviewCount + ratings.length,
      reviews: ratings
          .map((rating) => rating.comment)
          .whereType<String>()
          .toList(),
      cancelledJobs: requests
          .where((request) => request.state == RequestState.cancelled)
          .length,
      currentRequests: requests
          .where((request) => !request.state.isArchived)
          .map((request) => request.serviceName)
          .toList(),
      conversationCount: requests
          .where((request) => _requests.getMessages(request.id).isNotEmpty)
          .length,
      timeline: await getAuditLog(professionalId),
    );
  }

  @override
  Future<void> approveVerification(String professionalId) async => _verify(
    professionalId,
    ProfessionalVerificationStatus.verified,
    ProfessionalAuditAction.verificationApproved,
  );

  @override
  Future<void> rejectVerification(String professionalId, String reason) async {
    _requireReason(reason);
    _verify(
      professionalId,
      ProfessionalVerificationStatus.rejected,
      ProfessionalAuditAction.verificationRejected,
      reason: reason,
    );
  }

  @override
  Future<void> requestAdditionalInformation(
    String professionalId,
    String reason,
  ) async {
    _requireReason(reason);
    _verify(
      professionalId,
      ProfessionalVerificationStatus.pending,
      ProfessionalAuditAction.additionalInformationRequested,
      reason: reason,
      recordWhenUnchanged: true,
    );
  }

  @override
  Future<void> suspendProfessional(String professionalId) async => _status(
    professionalId,
    AdminAccountStatus.suspended,
    ProfessionalAuditAction.accountSuspended,
  );

  @override
  Future<void> reactivateProfessional(String professionalId) async => _status(
    professionalId,
    AdminAccountStatus.active,
    ProfessionalAuditAction.accountReactivated,
  );

  @override
  Future<List<ProfessionalAuditEntry>> getAuditLog(
    String professionalId,
  ) async => List.unmodifiable(
    _state.professionalAudit
        .where((entry) => entry.professionalId == professionalId)
        .toList()
        .reversed,
  );

  Map<String, AdminProfessional> _professionals() {
    final result = <String, AdminProfessional>{};
    for (final request in _requests.getCustomerRequests('customer-current')) {
      final profile = request.professional;
      final id = profile.user.id;
      final requests = _requests.getProfessionalRequests(id);
      result[id] = AdminProfessional(
        id: id,
        name: profile.user.name,
        email: '$id@mock.linko',
        photoUrl: null,
        categories: [profile.profession],
        verification:
            _state.verification[id] ?? ProfessionalVerificationStatus.pending,
        averageRating: profile.rating,
        completedJobs: requests
            .where(
              (item) =>
                  item.state == RequestState.completed ||
                  item.state == RequestState.reviewed,
            )
            .length,
        activeJobs: requests.where((item) => !item.state.isArchived).length,
        registeredAt: request.createdAt ?? request.updatedAt,
        accountStatus:
            _state.professionalStatuses[id] ?? AdminAccountStatus.active,
      );
    }
    return result;
  }

  void _require(String id) {
    if (!_professionals().containsKey(id)) {
      throw StateError('No se encontró el profesional.');
    }
  }

  void _verify(
    String id,
    ProfessionalVerificationStatus next,
    ProfessionalAuditAction action, {
    String? reason,
    bool recordWhenUnchanged = false,
  }) {
    _require(id);
    final previous =
        _state.verification[id] ?? ProfessionalVerificationStatus.pending;
    if (previous == next && !recordWhenUnchanged) return;
    _state.verification[id] = next;
    _state.availability.setVerified(
      id,
      verified: next == ProfessionalVerificationStatus.verified,
    );
    _record(
      id,
      action,
      previous.name,
      reason == null ? next.name : '${next.name}: $reason',
    );
  }

  void _requireReason(String reason) {
    if (reason.trim().isEmpty) {
      throw ArgumentError('Debes indicar un motivo.');
    }
  }

  void _status(
    String id,
    AdminAccountStatus next,
    ProfessionalAuditAction action,
  ) {
    _require(id);
    final previous =
        _state.professionalStatuses[id] ?? AdminAccountStatus.active;
    if (previous == next) return;
    _state.professionalStatuses[id] = next;
    _state.availability.setSuspended(
      id,
      suspended: next == AdminAccountStatus.suspended,
    );
    _record(id, action, previous.name, next.name);
  }

  void _record(
    String id,
    ProfessionalAuditAction action,
    String previous,
    String next,
  ) {
    _state.professionalAudit.add(
      ProfessionalAuditEntry(
        id: 'professional-audit-${_state.professionalAudit.length + 1}',
        adminId: adminId,
        professionalId: id,
        action: action,
        previousValue: previous,
        newValue: next,
        timestamp: _clock().toUtc(),
      ),
    );
  }
}
