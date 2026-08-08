import 'package:linko/features/admin/domain/admin_dashboard.dart';
import 'package:linko/features/admin/domain/admin_dashboard_repository.dart';
import 'package:linko_admin/features/admin/data/mock_admin_state.dart';
import 'package:linko/features/admin/domain/admin_professional.dart';
import 'package:linko/features/admin/domain/admin_user.dart';
import 'package:linko/features/requests/domain/models/request_state.dart';
import 'package:linko/features/requests/domain/repositories/request_repository.dart';

class MockAdminDashboardRepository implements AdminDashboardRepository {
  MockAdminDashboardRepository(
    this._requests,
    this._adminState, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final RequestRepository _requests;
  final MockAdminState _adminState;
  final DateTime Function() _clock;

  @override
  Future<AdminDashboardSnapshot> loadDashboard(
    AdminDashboardRange range,
  ) async {
    final now = _clock().toUtc();
    final since = now.subtract(range.duration);
    final requests = _requests.getCustomerRequests('customer-current').where((
      request,
    ) {
      final createdAt = request.createdAt ?? request.updatedAt;
      return !createdAt.toUtc().isBefore(since);
    }).toList();
    final users = <String>{};
    final professionals = <String, double>{};
    final activities = <AdminActivity>[];
    for (final request in requests) {
      final timestamp = (request.createdAt ?? request.updatedAt).toUtc();
      if (users.add(request.customer.id)) {
        activities.add(
          AdminActivity(
            id: 'user-${request.customer.id}',
            type: AdminActivityType.userRegistered,
            title: 'Nuevo usuario: ${request.customer.name}',
            timestamp: timestamp,
          ),
        );
      }
      if (users.add(request.professional.user.id)) {
        activities.add(
          AdminActivity(
            id: 'user-${request.professional.user.id}',
            type: AdminActivityType.userRegistered,
            title: 'Nuevo usuario: ${request.professional.user.name}',
            timestamp: timestamp,
          ),
        );
      }
      final professionalId = request.professional.user.id;
      final verified =
          _adminState.verification[professionalId] ==
          ProfessionalVerificationStatus.verified;
      final active =
          (_adminState.professionalStatuses[professionalId] ??
              AdminAccountStatus.active) ==
          AdminAccountStatus.active;
      if (verified && active && !professionals.containsKey(professionalId)) {
        professionals[professionalId] = request.professional.rating;
        activities.add(
          AdminActivity(
            id: 'professional-${request.professional.user.id}',
            type: AdminActivityType.professionalCreated,
            title: 'Nuevo profesional: ${request.professional.user.name}',
            timestamp: timestamp,
          ),
        );
      }
    }
    final averageRating = professionals.isEmpty
        ? 0.0
        : professionals.values.reduce((left, right) => left + right) /
              professionals.length;
    for (final request in requests) {
      final timestamp = (request.createdAt ?? request.updatedAt).toUtc();
      activities.add(
        AdminActivity(
          id: 'request-${request.id}',
          type: AdminActivityType.requestCreated,
          title: 'Solicitud creada: ${request.serviceName}',
          timestamp: timestamp,
        ),
      );
      if (_requests.getQuotation(request.id) != null) {
        activities.add(
          AdminActivity(
            id: 'quotation-${request.id}',
            type: AdminActivityType.quotationSent,
            title: 'Cotización enviada para ${request.serviceName}',
            timestamp: request.updatedAt.toUtc(),
          ),
        );
      }
      if (request.state == RequestState.completed ||
          request.state == RequestState.reviewed) {
        activities.add(
          AdminActivity(
            id: 'completed-${request.id}',
            type: AdminActivityType.jobCompleted,
            title: 'Trabajo completado: ${request.serviceName}',
            timestamp: request.updatedAt.toUtc(),
          ),
        );
      }
    }
    final reportTimestamp = now.subtract(const Duration(days: 2));
    if (!reportTimestamp.isBefore(since)) {
      activities.add(
        AdminActivity(
          id: 'report-mock-open',
          type: AdminActivityType.reportOpened,
          title: 'Reporte abierto: seguimiento de servicio',
          timestamp: reportTimestamp,
        ),
      );
    }
    activities.sort((left, right) => right.timestamp.compareTo(left.timestamp));
    return AdminDashboardSnapshot(
      metrics: AdminDashboardMetrics(
        totalUsers: users.length,
        totalProfessionals: professionals.length,
        activeRequests: requests
            .where((request) => !request.state.isArchived)
            .length,
        completedJobs: requests
            .where(
              (request) =>
                  request.state == RequestState.completed ||
                  request.state == RequestState.reviewed,
            )
            .length,
        cancelledRequests: requests
            .where((request) => request.state == RequestState.cancelled)
            .length,
        averageRating: averageRating,
      ),
      activities: List.unmodifiable(activities.take(20)),
    );
  }
}
