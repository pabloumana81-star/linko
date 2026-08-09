import 'package:linko/features/requests/domain/repositories/request_repository.dart';
import 'package:linko/features/admin/domain/admin_request.dart';
import 'package:linko/features/requests/domain/models/request_state.dart';

class MockAdminRequestsRepository implements AdminRequestsRepository {
  MockAdminRequestsRepository(this._requests);

  final RequestRepository _requests;
  final Set<String> _flagged = {};
  final Map<String, List<AdminRequestAuditEntry>> _audits = {};

  @override
  Future<List<AdminRequest>> listRequests() async => List.unmodifiable(
    _requests
        .getCustomerRequests('customer-current')
        .map(
          (request) => AdminRequest(
            id: request.id,
            title: request.serviceName,
            category: request.category.name,
            status: request.state.name,
            customerName: request.customer.name,
            professionalName: request.professional.user.name,
            createdAt: request.createdAt ?? request.updatedAt,
            updatedAt: request.updatedAt,
            description: request.description,
            scheduledAt: request.scheduledAt,
            adminReviewFlag: _flagged.contains(request.id),
            auditHistory: List.unmodifiable(_audits[request.id] ?? const []),
          ),
        ),
  );

  @override
  Future<void> performAction(
    String requestId,
    AdminRequestAction action,
    String note,
  ) async {
    if (note.trim().isEmpty) {
      throw ArgumentError('Debes indicar una nota o motivo.');
    }
    final items = await listRequests();
    final current = items.where((item) => item.id == requestId).firstOrNull;
    if (current == null) throw StateError('Solicitud no encontrada.');
    if (action == AdminRequestAction.flagForReview) {
      if (_flagged.contains(requestId)) {
        throw StateError('La solicitud ya está marcada para revisión.');
      }
      if ({'completed', 'reviewed', 'cancelled'}.contains(current.status)) {
        throw StateError('No puedes marcar una solicitud archivada.');
      }
      _flagged.add(requestId);
    } else if (action == AdminRequestAction.cancel) {
      if ({
        'pendingCustomerConfirmation',
        'completed',
        'reviewed',
        'cancelled',
      }.contains(current.status)) {
        throw StateError('No puedes cancelar una solicitud finalizada.');
      }
      _requests.updateStatus(requestId, RequestState.cancelled);
    }
    final next = action == AdminRequestAction.cancel
        ? 'cancelled'
        : current.status;
    final history = _audits.putIfAbsent(requestId, () => []);
    history.insert(
      0,
      AdminRequestAuditEntry(
        id: 'audit-${history.length + 1}',
        adminId: 'admin-current',
        action: action.name,
        previousStatus: current.status,
        newStatus: next,
        note: note.trim(),
        createdAt: DateTime.now(),
      ),
    );
  }
}
