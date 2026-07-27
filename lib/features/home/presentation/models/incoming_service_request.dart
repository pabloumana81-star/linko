import 'package:linko/features/home/presentation/models/request_draft.dart';
import 'package:linko/features/home/presentation/models/request_status.dart';

class IncomingServiceRequest {
  const IncomingServiceRequest({
    required this.id,
    required this.customerName,
    required this.serviceCategory,
    required this.description,
    required this.location,
    required this.timing,
    required this.status,
    required this.relativeDate,
    required this.creationDate,
    required this.memberSince,
    required this.attachedPhotoCount,
    this.selectedDate,
  });

  final String id;
  final String customerName;
  final String serviceCategory;
  final String description;
  final String location;
  final RequestTiming timing;
  final RequestStatus status;
  final String relativeDate;
  final String creationDate;
  final String memberSince;
  final int attachedPhotoCount;
  final DateTime? selectedDate;

  IncomingServiceRequest copyWith({RequestStatus? status}) {
    return IncomingServiceRequest(
      id: id,
      customerName: customerName,
      serviceCategory: serviceCategory,
      description: description,
      location: location,
      timing: timing,
      status: status ?? this.status,
      relativeDate: relativeDate,
      creationDate: creationDate,
      memberSince: memberSince,
      attachedPhotoCount: attachedPhotoCount,
      selectedDate: selectedDate,
    );
  }
}
