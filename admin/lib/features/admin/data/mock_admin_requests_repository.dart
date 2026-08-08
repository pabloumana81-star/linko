import 'package:linko/features/requests/domain/repositories/request_repository.dart';
import 'package:linko/features/admin/domain/admin_request.dart';

class MockAdminRequestsRepository implements AdminRequestsRepository {
  const MockAdminRequestsRepository(this._requests);

  final RequestRepository _requests;

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
          ),
        ),
  );
}
