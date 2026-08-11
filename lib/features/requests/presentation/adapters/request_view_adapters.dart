import 'package:flutter/material.dart';
import 'package:linko/features/home/presentation/models/customer_service_request.dart';
import 'package:linko/features/home/presentation/models/incoming_service_request.dart';
import 'package:linko/features/home/presentation/models/request_draft.dart';
import 'package:linko/features/requests/domain/models/service_request.dart';

extension ServiceRequestViewAdapter on ServiceRequest {
  IncomingServiceRequest toIncomingRequest() {
    return IncomingServiceRequest(
      id: id,
      customerName: customer.name,
      serviceCategory: serviceName,
      description: description,
      location: location,
      timing: _timing,
      status: state,
      relativeDate: _updatedLabel,
      creationDate: createdAtLabel,
      memberSince: memberSinceLabel,
      attachedPhotoCount: attachedPhotoCount,
    );
  }

  CustomerServiceRequest toCustomerRequest() {
    return CustomerServiceRequest(
      id: id,
      serviceName: serviceName,
      categoryIcon: _categoryIcon,
      professionalName: professional.user.name,
      professionalAvatar: _initials(professional.user.name),
      status: state,
      updatedLabel: _updatedLabel,
    );
  }

  RequestTiming get _timing {
    if (availabilityLabel.contains('Fecha')) {
      return RequestTiming.specificDate;
    }
    if (availabilityLabel.contains('flexible')) {
      return RequestTiming.flexible;
    }
    return RequestTiming.asSoonAsPossible;
  }

  IconData get _categoryIcon => switch (category) {
    ServiceCategory.airConditioning => Icons.ac_unit_rounded,
    ServiceCategory.electrical => Icons.electrical_services_rounded,
    ServiceCategory.maintenance => Icons.home_repair_service_rounded,
    ServiceCategory.plumbing => Icons.plumbing_rounded,
    ServiceCategory.cleaning => Icons.cleaning_services_rounded,
  };

  String get _updatedLabel {
    final difference = DateTime.now().difference(updatedAt);
    if (difference.inDays > 0) {
      return 'Actualizada hace ${difference.inDays} días';
    }
    return 'Actualizada recientemente';
  }

  String _initials(String name) {
    return name.split(RegExp(r'\s+')).take(2).map((part) => part[0]).join();
  }
}
