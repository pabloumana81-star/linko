import 'package:linko/features/home/presentation/models/professional_profile_data.dart';

enum RequestTiming { asSoonAsPossible, specificDate, flexible }

extension RequestTimingLabel on RequestTiming {
  String get label {
    return switch (this) {
      RequestTiming.asSoonAsPossible => 'Lo antes posible',
      RequestTiming.specificDate => 'En una fecha específica',
      RequestTiming.flexible => 'Soy flexible',
    };
  }
}

extension RequestDateLabel on DateTime {
  String get spanishDate {
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];

    return '$day de ${months[month - 1]} de $year';
  }
}

class RequestDraft {
  const RequestDraft({
    required this.professional,
    required this.description,
    required this.location,
    required this.timing,
    required this.attachedPhotoCount,
    this.selectedDate,
  });

  final ProfessionalProfileData professional;
  final String description;
  final String location;
  final RequestTiming timing;
  final DateTime? selectedDate;
  final int attachedPhotoCount;
}
