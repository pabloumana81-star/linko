import 'package:linko/features/home/presentation/models/incoming_service_request.dart';
import 'package:linko/features/home/presentation/models/request_draft.dart';
import 'package:linko/features/home/presentation/models/request_status.dart';

final placeholderIncomingRequests = [
  IncomingServiceRequest(
    id: 'request-ana-air',
    customerName: 'Ana Martínez',
    serviceCategory: 'Aire acondicionado',
    description:
        'El equipo no está enfriando correctamente y hace un ruido extraño '
        'cuando está encendido.',
    location: 'Escazú, San José',
    timing: RequestTiming.asSoonAsPossible,
    status: RequestStatus.newRequest,
    relativeDate: 'Hace 10 min',
    creationDate: '24 de julio de 2026',
    memberSince: 'Miembro desde 2024',
    attachedPhotoCount: 2,
  ),
  IncomingServiceRequest(
    id: 'request-diego-electric',
    customerName: 'Diego Ramírez',
    serviceCategory: 'Electricista',
    description:
        'Necesito revisar varios tomacorrientes que dejaron de funcionar en '
        'la sala y la cocina.',
    location: 'Curridabat, San José',
    timing: RequestTiming.flexible,
    status: RequestStatus.newRequest,
    relativeDate: 'Hace 35 min',
    creationDate: '24 de julio de 2026',
    memberSince: 'Miembro desde 2025',
    attachedPhotoCount: 0,
  ),
  IncomingServiceRequest(
    id: 'request-laura-maintenance',
    customerName: 'Laura Gómez',
    serviceCategory: 'Mantenimiento',
    description:
        'Busco mantenimiento preventivo para el sistema eléctrico de una '
        'oficina pequeña.',
    location: 'Heredia centro',
    timing: RequestTiming.specificDate,
    selectedDate: DateTime(2026, 8, 5),
    status: RequestStatus.newRequest,
    relativeDate: 'Hace 1 h',
    creationDate: '24 de julio de 2026',
    memberSince: 'Miembro desde 2023',
    attachedPhotoCount: 1,
  ),
  IncomingServiceRequest(
    id: 'request-marco-review',
    customerName: 'Marco Solano',
    serviceCategory: 'Revisión de sistemas',
    description:
        'Necesito una revisión general antes de instalar nuevos equipos en '
        'el local.',
    location: 'Alajuela centro',
    timing: RequestTiming.flexible,
    status: RequestStatus.underReview,
    relativeDate: 'Ayer',
    creationDate: '23 de julio de 2026',
    memberSince: 'Miembro desde 2022',
    attachedPhotoCount: 0,
  ),
];
