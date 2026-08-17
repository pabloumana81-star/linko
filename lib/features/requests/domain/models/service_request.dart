import 'package:linko/features/requests/domain/models/app_user.dart';
import 'package:linko/features/requests/domain/models/professional_profile.dart';
import 'package:linko/features/requests/domain/models/request_state.dart';

enum ServiceCategory {
  airConditioning,
  electrical,
  maintenance,
  plumbing,
  cleaning,
}

extension ServiceRequestLocation on ServiceRequest {
  String get displayLocation =>
      location.trim().isEmpty ? 'No especificada' : location;
}

class ServiceRequest {
  const ServiceRequest({
    required this.id,
    required this.customer,
    required this.professional,
    required this.serviceName,
    required this.category,
    required this.description,
    required this.location,
    required this.availabilityLabel,
    required this.state,
    required this.updatedAt,
    required this.createdAtLabel,
    required this.memberSinceLabel,
    required this.attachedPhotoCount,
    this.scheduledAt,
    this.createdAt,
  });

  final String id;
  final AppUser customer;
  final ProfessionalProfile professional;
  final String serviceName;
  final ServiceCategory category;
  final String description;
  final String location;
  final String availabilityLabel;
  final RequestState state;
  final DateTime updatedAt;
  final String createdAtLabel;
  final String memberSinceLabel;
  final int attachedPhotoCount;
  final DateTime? scheduledAt;
  final DateTime? createdAt;

  ServiceRequest copyWith({
    RequestState? state,
    DateTime? updatedAt,
    DateTime? scheduledAt,
    bool clearSchedule = false,
  }) {
    return ServiceRequest(
      id: id,
      customer: customer,
      professional: professional,
      serviceName: serviceName,
      category: category,
      description: description,
      location: location,
      availabilityLabel: availabilityLabel,
      state: state ?? this.state,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAtLabel: createdAtLabel,
      memberSinceLabel: memberSinceLabel,
      attachedPhotoCount: attachedPhotoCount,
      scheduledAt: clearSchedule ? null : scheduledAt ?? this.scheduledAt,
      createdAt: createdAt,
    );
  }
}
