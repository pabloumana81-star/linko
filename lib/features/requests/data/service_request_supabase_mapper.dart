import 'package:linko/features/requests/domain/models/app_user.dart';
import 'package:linko/features/requests/domain/models/professional_profile.dart';
import 'package:linko/features/requests/domain/models/request_state.dart';
import 'package:linko/features/requests/domain/models/service_request.dart';

class InvalidRequestStatusException implements FormatException {
  const InvalidRequestStatusException(this.value);

  final Object? value;

  @override
  String get message => 'El estado de la solicitud no es válido.';

  @override
  int? get offset => null;

  @override
  Object? get source => value;

  @override
  String toString() => message;
}

abstract final class RequestStatusMapper {
  static RequestStatus fromDatabase(Object? value) {
    if (value is! String) throw InvalidRequestStatusException(value);
    for (final status in RequestStatus.values) {
      if (toDatabase(status) == value) return status;
    }
    throw InvalidRequestStatusException(value);
  }

  static String toDatabase(RequestStatus status) => switch (status) {
    RequestStatus.pending => 'pending',
    RequestStatus.underReview => 'under_review',
    RequestStatus.quoted => 'quoted',
    RequestStatus.accepted => 'accepted',
    RequestStatus.scheduled => 'scheduled',
    RequestStatus.inProgress => 'in_progress',
    RequestStatus.pendingCustomerConfirmation =>
      'pending_customer_confirmation',
    RequestStatus.completed => 'completed',
    RequestStatus.reviewed => 'reviewed',
    RequestStatus.cancelled => 'cancelled',
  };
}

class ServiceRequestSupabaseMapper {
  const ServiceRequestSupabaseMapper();

  Map<String, Object?> toInsert(ServiceRequest request) {
    if (!isUuid(request.id) ||
        !isUuid(request.customer.id) ||
        !isUuid(request.professional.id)) {
      throw const FormatException(
        'Los identificadores de la solicitud deben ser UUID válidos.',
      );
    }
    return {
      'id': request.id,
      'customer_id': request.customer.id,
      'professional_id': request.professional.id,
      'service_category': request.category.name,
      'title': request.serviceName,
      'description': request.description,
      'status': RequestStatusMapper.toDatabase(request.state),
      'scheduled_at': request.scheduledAt?.toUtc().toIso8601String(),
    };
  }

  static bool isUuid(String value) => RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  ).hasMatch(value);

  ServiceRequest fromRow(Map<String, dynamic> row) {
    final customer = _relation(row['customer']);
    final professional = _relation(row['professional']);
    final createdAt = _date(row['created_at']);
    return ServiceRequest(
      id: row['id'] as String,
      customer: AppUser(
        id: row['customer_id'] as String,
        name: customer?['display_name'] as String? ?? 'Cliente LinkO',
      ),
      professional: ProfessionalProfile(
        id: row['professional_id'] as String,
        user: AppUser(
          id:
              professional?['user_id'] as String? ??
              row['professional_id'] as String,
          name: professional?['display_name'] as String? ?? 'Profesional LinkO',
        ),
        profession:
            professional?['profession'] as String? ?? row['title'] as String,
        rating: (professional?['rating'] as num?)?.toDouble() ?? 0,
        reviewCount: (professional?['review_count'] as num?)?.toInt() ?? 0,
        location: professional?['location'] as String? ?? '',
      ),
      serviceName: row['title'] as String,
      category: _category(row['service_category']),
      description: row['description'] as String,
      location: '',
      availabilityLabel: row['scheduled_at'] == null
          ? 'Soy flexible'
          : 'Fecha programada',
      state: RequestStatusMapper.fromDatabase(row['status']),
      updatedAt: _date(row['updated_at']),
      createdAt: createdAt,
      scheduledAt: _nullableDate(row['scheduled_at']),
      createdAtLabel: 'Recientemente',
      memberSinceLabel: 'Miembro de LinkO',
      attachedPhotoCount: 0,
    );
  }

  ServiceCategory _category(Object? value) {
    if (value is String) {
      for (final category in ServiceCategory.values) {
        if (category.name == value) return category;
      }
    }
    return ServiceCategory.maintenance;
  }

  Map<String, dynamic>? _relation(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is List && value.isNotEmpty && value.first is Map) {
      return Map<String, dynamic>.from(value.first as Map);
    }
    return null;
  }

  DateTime _date(Object? value) {
    final result = _nullableDate(value);
    if (result == null) throw const FormatException('Fecha inválida.');
    return result;
  }

  DateTime? _nullableDate(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toUtc() : null;
}
