import 'package:flutter/material.dart';
import 'package:linko/features/requests/domain/models/request_state.dart';

class CustomerServiceRequest {
  const CustomerServiceRequest({
    required this.id,
    required this.serviceName,
    required this.categoryIcon,
    required this.professionalName,
    required this.professionalAvatar,
    required this.location,
    required this.status,
    required this.updatedLabel,
  });

  final String id;
  final String serviceName;
  final IconData categoryIcon;
  final String professionalName;
  final String professionalAvatar;
  final String location;
  final RequestState status;
  final String updatedLabel;
}
