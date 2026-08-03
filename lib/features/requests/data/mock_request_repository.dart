import 'package:linko/features/requests/domain/models/app_user.dart';
import 'package:linko/features/requests/domain/models/conversation_message.dart';
import 'package:linko/features/requests/domain/models/professional_profile.dart';
import 'package:linko/features/requests/domain/models/quotation.dart';
import 'package:linko/features/requests/domain/models/request_state.dart';
import 'package:linko/features/requests/domain/models/service_request.dart';
import 'package:linko/features/requests/domain/models/service_rating.dart';
import 'package:linko/features/requests/domain/models/timeline_event.dart';
import 'package:linko/features/requests/domain/repositories/request_repository.dart';
import 'package:linko/features/requests/domain/services/request_state_machine.dart';

class MockRequestRepository implements RequestRepository {
  MockRequestRepository() {
    _seed();
  }

  final Map<String, ServiceRequest> _requests = {};
  final Map<String, Quotation> _quotations = {};
  final Map<String, List<ConversationMessage>> _messages = {};
  final Map<String, List<TimelineEvent>> _timeline = {};
  final Map<String, ServiceRating> _ratings = {};

  @override
  void createRequest(ServiceRequest request) {
    if (_requests.containsKey(request.id)) {
      throw StateError('La solicitud ya existe: ${request.id}');
    }
    _requests[request.id] = request;
    _messages[request.id] = _initialMessages(request.id);
    _timeline[request.id] = _initialTimeline(request);
  }

  void replaceRequest(ServiceRequest request) {
    if (!_requests.containsKey(request.id)) {
      throw StateError('No se encontró la solicitud.');
    }
    _requests[request.id] = request;
  }

  @override
  List<ServiceRequest> getCustomerRequests(String customerId) {
    return List.unmodifiable(_requests.values);
  }

  @override
  List<ServiceRequest> getProfessionalRequests(String professionalId) {
    return List.unmodifiable(
      _requests.values.where(
        (request) => request.professional.user.id == professionalId,
      ),
    );
  }

  @override
  ServiceRequest? getRequestById(String requestId) => _requests[requestId];

  @override
  void updateStatus(String requestId, RequestState state) {
    final request = _requireRequest(requestId);
    RequestStateMachine.ensureTransition(request.state, state);
    _requests[requestId] = request.copyWith(
      state: state,
      updatedAt: DateTime.now(),
    );
    final stage = RequestStateMachine.definition(state).timelineStage;
    if (stage != null) {
      final timeline = _timeline[requestId]!;
      final index = timeline.indexWhere((event) => event.stage == stage);
      if (index >= 0) {
        final event = timeline[index];
        timeline[index] = TimelineEvent(
          id: event.id,
          requestId: event.requestId,
          stage: event.stage,
          title: event.title,
          description: event.description,
          dateLabel: 'Ahora',
        );
      }
    }
  }

  @override
  Quotation? getQuotation(String requestId) => _quotations[requestId];

  @override
  void sendQuotation(Quotation quotation) {
    if (_quotations.containsKey(quotation.requestId)) {
      throw StateError('La solicitud ya tiene una cotización.');
    }
    final request = _requireRequest(quotation.requestId);
    if (!RequestStateMachine.allows(
      request.state,
      RequestActor.professional,
      RequestAction.sendQuotation,
    )) {
      throw StateError('La solicitud no permite enviar una cotización.');
    }
    _quotations[quotation.requestId] = quotation;
    updateStatus(quotation.requestId, RequestState.quoted);
    _messages[quotation.requestId]!.add(
      ConversationMessage(
        id: '${quotation.requestId}-quotation-system',
        requestId: quotation.requestId,
        author: MessageAuthor.system,
        text: 'El profesional envió una cotización.',
        timeLabel: 'Ahora',
      ),
    );
    final timeline = _timeline[quotation.requestId]!;
    final index = timeline.indexWhere(
      (event) => event.stage == TimelineStage.quotationSent,
    );
    timeline[index] = TimelineEvent(
      id: timeline[index].id,
      requestId: quotation.requestId,
      stage: TimelineStage.quotationSent,
      title: 'Cotización enviada',
      description: 'El profesional compartió una cotización.',
      dateLabel: 'Ahora',
    );
  }

  @override
  void acceptQuotation(String requestId) {
    final request = _requireRequest(requestId);
    if (_quotations[requestId] == null) {
      throw StateError('La solicitud no tiene una cotización.');
    }
    if (request.state == RequestState.accepted) {
      return;
    }
    if (!RequestStateMachine.allows(
      request.state,
      RequestActor.customer,
      RequestAction.acceptQuotation,
    )) {
      throw StateError('La solicitud no permite aceptar una cotización.');
    }
    updateStatus(requestId, RequestState.accepted);
    sendMessage(
      ConversationMessage(
        id: '$requestId-quotation-accepted',
        requestId: requestId,
        author: MessageAuthor.system,
        text: 'El cliente aceptó la cotización.',
        timeLabel: 'Ahora',
        type: ConversationMessageType.system,
      ),
    );
  }

  @override
  List<ConversationMessage> getMessages(String requestId) {
    _requireRequest(requestId);
    return List.unmodifiable(_messages[requestId]!);
  }

  @override
  void sendMessage(ConversationMessage message) {
    final request = _requireRequest(message.requestId);
    _messages[message.requestId]!.add(message);
    _requests[message.requestId] = request.copyWith(updatedAt: DateTime.now());
  }

  @override
  void proposeSchedule(String requestId, String scheduleLabel) {
    final request = _requireRequest(requestId);
    final alreadyProposed = _messages[requestId]!.any(
      (message) =>
          message.type == ConversationMessageType.scheduleProposal &&
          message.scheduleStatus == ScheduleProposalStatus.pending,
    );
    if (alreadyProposed) {
      return;
    }
    if (!RequestStateMachine.allows(
      request.state,
      RequestActor.professional,
      RequestAction.proposeSchedule,
    )) {
      throw StateError('La solicitud no permite proponer una fecha.');
    }
    sendMessage(
      ConversationMessage(
        id: '$requestId-schedule-${DateTime.now().microsecondsSinceEpoch}',
        requestId: requestId,
        author: MessageAuthor.professional,
        text: 'El profesional propuso una fecha para el trabajo.',
        timeLabel: 'Ahora',
        type: ConversationMessageType.scheduleProposal,
        scheduleLabel: scheduleLabel,
        scheduleStatus: ScheduleProposalStatus.pending,
      ),
    );
  }

  @override
  void confirmSchedule(String requestId, String messageId) {
    final request = _requireRequest(requestId);
    if (request.state == RequestState.scheduled) {
      return;
    }
    if (!RequestStateMachine.allows(
      request.state,
      RequestActor.customer,
      RequestAction.confirmSchedule,
    )) {
      throw StateError('La solicitud no permite confirmar una fecha.');
    }
    _updateScheduleMessage(
      requestId,
      messageId,
      ScheduleProposalStatus.confirmed,
    );
    updateStatus(requestId, RequestState.scheduled);
    sendMessage(
      ConversationMessage(
        id: '$requestId-schedule-confirmed',
        requestId: requestId,
        author: MessageAuthor.system,
        text: 'El cliente confirmó la fecha del trabajo.',
        timeLabel: 'Ahora',
        type: ConversationMessageType.system,
      ),
    );
  }

  @override
  void requestScheduleChange(String requestId, String messageId) {
    final request = _requireRequest(requestId);
    if (!RequestStateMachine.allows(
      request.state,
      RequestActor.customer,
      RequestAction.requestScheduleChange,
    )) {
      throw StateError('La solicitud no permite solicitar otra fecha.');
    }
    _updateScheduleMessage(
      requestId,
      messageId,
      ScheduleProposalStatus.changeRequested,
    );
    sendMessage(
      ConversationMessage(
        id: '$requestId-schedule-change',
        requestId: requestId,
        author: MessageAuthor.system,
        text: 'El cliente solicitó cambiar la fecha del trabajo.',
        timeLabel: 'Ahora',
        type: ConversationMessageType.system,
      ),
    );
  }

  @override
  void startJob(String requestId) {
    final request = _requireRequest(requestId);
    if (request.state == RequestState.inProgress) {
      return;
    }
    if (!RequestStateMachine.allows(
      request.state,
      RequestActor.professional,
      RequestAction.startJob,
    )) {
      throw StateError('Only scheduled jobs can be started.');
    }
    updateStatus(requestId, RequestState.inProgress);
    sendMessage(
      ConversationMessage(
        id: '$requestId-work-started',
        requestId: requestId,
        author: MessageAuthor.system,
        text: 'El profesional inició el trabajo.',
        timeLabel: 'Ahora',
        type: ConversationMessageType.workStarted,
      ),
    );
  }

  @override
  void markJobCompleted(String requestId) {
    final request = _requireRequest(requestId);
    if (request.state == RequestState.pendingCustomerConfirmation ||
        request.state == RequestState.completed) {
      return;
    }
    if (!RequestStateMachine.allows(
      request.state,
      RequestActor.professional,
      RequestAction.markJobCompleted,
    )) {
      throw StateError('La solicitud no permite completar el trabajo.');
    }
    updateStatus(requestId, RequestState.pendingCustomerConfirmation);
    sendMessage(
      ConversationMessage(
        id: '$requestId-job-completed',
        requestId: requestId,
        author: MessageAuthor.system,
        text: 'El profesional indicó que el trabajo ha finalizado.',
        timeLabel: 'Ahora',
        type: ConversationMessageType.jobCompleted,
      ),
    );
  }

  @override
  void confirmJob(String requestId) {
    final request = _requireRequest(requestId);
    if (request.state == RequestState.completed) {
      return;
    }
    if (!RequestStateMachine.allows(
      request.state,
      RequestActor.customer,
      RequestAction.confirmJob,
    )) {
      throw StateError('La solicitud no permite confirmar el trabajo.');
    }
    updateStatus(requestId, RequestState.completed);
    sendMessage(
      ConversationMessage(
        id: '$requestId-job-confirmed',
        requestId: requestId,
        author: MessageAuthor.system,
        text: 'El cliente confirmó el trabajo completado.',
        timeLabel: 'Ahora',
        type: ConversationMessageType.system,
      ),
    );
  }

  @override
  void reportCompletedWorkProblem(String requestId) {
    final request = _requireRequest(requestId);
    if (!RequestStateMachine.allows(
      request.state,
      RequestActor.customer,
      RequestAction.reportProblem,
    )) {
      throw StateError('La solicitud no permite reportar un problema.');
    }
    sendMessage(
      ConversationMessage(
        id: '$requestId-completed-work-problem',
        requestId: requestId,
        author: MessageAuthor.system,
        text: 'El cliente reportó un problema con el trabajo realizado.',
        timeLabel: 'Ahora',
        type: ConversationMessageType.system,
      ),
    );
  }

  @override
  ServiceRating? getRating(String requestId) => _ratings[requestId];

  @override
  void submitRating(ServiceRating rating) {
    final request = _requireRequest(rating.requestId);
    if (_ratings.containsKey(rating.requestId)) {
      return;
    }
    if (!RequestStateMachine.allows(
      request.state,
      RequestActor.customer,
      RequestAction.rateService,
    )) {
      throw StateError('La solicitud no permite enviar una calificación.');
    }
    if (rating.stars < 1 || rating.stars > 5) {
      throw ArgumentError.value(rating.stars, 'stars');
    }
    if (rating.professionalId != request.professional.user.id) {
      throw StateError('La calificación no corresponde al profesional.');
    }
    _ratings[rating.requestId] = rating;
    updateStatus(rating.requestId, RequestState.reviewed);
    sendMessage(
      ConversationMessage(
        id: '${rating.requestId}-service-reviewed',
        requestId: rating.requestId,
        author: MessageAuthor.system,
        text: 'El cliente calificó el servicio.',
        timeLabel: 'Ahora',
        type: ConversationMessageType.system,
      ),
    );
  }

  @override
  ProfessionalRatingSummary getProfessionalRatingSummary(
    String professionalId,
  ) {
    final requests = getProfessionalRequests(professionalId);
    final profile = requests.firstOrNull?.professional;
    final baselineRating = profile?.rating ?? 0;
    final baselineCount = profile?.reviewCount ?? 0;
    final ratings = _ratings.values
        .where((rating) => rating.professionalId == professionalId)
        .toList();
    final total =
        baselineRating * baselineCount +
        ratings.fold<int>(0, (sum, rating) => sum + rating.stars);
    final reviewCount = baselineCount + ratings.length;
    final completedJobs = requests
        .where(
          (request) =>
              request.state == RequestState.completed ||
              request.state == RequestState.reviewed,
        )
        .length;
    return ProfessionalRatingSummary(
      averageRating: reviewCount == 0 ? 0 : total / reviewCount,
      reviewCount: reviewCount,
      completedJobsCount: completedJobs,
    );
  }

  void _updateScheduleMessage(
    String requestId,
    String messageId,
    ScheduleProposalStatus status,
  ) {
    _requireRequest(requestId);
    final messages = _messages[requestId]!;
    final index = messages.indexWhere((message) => message.id == messageId);
    if (index < 0 ||
        messages[index].type != ConversationMessageType.scheduleProposal) {
      throw StateError('Propuesta de programación no encontrada.');
    }
    messages[index] = messages[index].copyWith(scheduleStatus: status);
  }

  @override
  List<TimelineEvent> getTimeline(String requestId) {
    _requireRequest(requestId);
    return List.unmodifiable(_timeline[requestId]!);
  }

  ServiceRequest _requireRequest(String id) {
    final request = _requests[id];
    if (request == null) {
      throw StateError('Solicitud no encontrada: $id');
    }
    return request;
  }

  void _seed() {
    const carlosUser = AppUser(
      id: 'professional-carlos',
      name: 'Carlos Rodríguez',
    );
    const mariaUser = AppUser(
      id: 'professional-maria',
      name: 'María Fernández',
    );
    const andresUser = AppUser(
      id: 'professional-andres',
      name: 'Andrés Vargas',
    );
    const sofiaUser = AppUser(id: 'professional-sofia', name: 'Sofía Jiménez');
    const danielUser = AppUser(
      id: 'professional-daniel',
      name: 'Daniel Morales',
    );
    const professionals = [
      ProfessionalProfile(
        id: 'profile-carlos',
        user: carlosUser,
        profession: 'Electricista',
        rating: 4.9,
        reviewCount: 128,
        location: 'San José',
      ),
      ProfessionalProfile(
        id: 'profile-maria',
        user: mariaUser,
        profession: 'Limpieza',
        rating: 4.8,
        reviewCount: 96,
        location: 'Heredia',
      ),
      ProfessionalProfile(
        id: 'profile-andres',
        user: andresUser,
        profession: 'Plomería',
        rating: 4.9,
        reviewCount: 84,
        location: 'Alajuela',
      ),
      ProfessionalProfile(
        id: 'profile-sofia',
        user: sofiaUser,
        profession: 'Jardinería',
        rating: 4.7,
        reviewCount: 73,
        location: 'Cartago',
      ),
      ProfessionalProfile(
        id: 'profile-daniel',
        user: danielUser,
        profession: 'Pintura',
        rating: 4.8,
        reviewCount: 91,
        location: 'San José',
      ),
    ];
    const customers = [
      AppUser(id: 'customer-ana', name: 'Ana Martínez'),
      AppUser(id: 'customer-diego', name: 'Diego Ramírez'),
      AppUser(id: 'customer-laura', name: 'Laura Gómez'),
      AppUser(id: 'customer-marco', name: 'Marco Solano'),
      AppUser(id: 'customer-elena', name: 'Elena Vargas'),
    ];
    final seeds = [
      _Seed(
        id: 'request-ana-air',
        customer: customers[0],
        professional: professionals[0],
        service: 'Aire acondicionado',
        category: ServiceCategory.airConditioning,
        description:
            'El equipo no está enfriando correctamente y hace un ruido extraño.',
        location: 'Escazú, San José',
        availability: 'Lo antes posible',
        state: RequestState.pending,
        photos: 2,
      ),
      _Seed(
        id: 'request-diego-electric',
        customer: customers[1],
        professional: professionals[2],
        service: 'Electricista',
        category: ServiceCategory.electrical,
        description: 'Varios tomacorrientes dejaron de funcionar.',
        location: 'Curridabat, San José',
        availability: 'Soy flexible',
        state: RequestState.underReview,
        photos: 0,
      ),
      _Seed(
        id: 'request-laura-maintenance',
        customer: customers[2],
        professional: professionals[1],
        service: 'Limpieza',
        category: ServiceCategory.cleaning,
        description: 'Necesito limpieza profunda de una oficina pequeña.',
        location: 'Heredia centro',
        availability: 'Fecha específica',
        state: RequestState.quoted,
        photos: 1,
      ),
      _Seed(
        id: 'request-marco-review',
        customer: customers[3],
        professional: professionals[3],
        service: 'Jardinería',
        category: ServiceCategory.maintenance,
        description: 'Necesito una revisión general del jardín.',
        location: 'Alajuela centro',
        availability: 'Soy flexible',
        state: RequestState.inProgress,
        photos: 0,
      ),
      _Seed(
        id: 'request-elena-paint',
        customer: customers[4],
        professional: professionals[4],
        service: 'Pintura',
        category: ServiceCategory.maintenance,
        description: 'Pintura interior de sala y comedor.',
        location: 'San José',
        availability: 'Por coordinar',
        state: RequestState.completed,
        photos: 1,
      ),
    ];

    for (var index = 0; index < seeds.length; index++) {
      final seed = seeds[index];
      final request = ServiceRequest(
        id: seed.id,
        customer: seed.customer,
        professional: seed.professional,
        serviceName: seed.service,
        category: seed.category,
        description: seed.description,
        location: seed.location,
        availabilityLabel: seed.availability,
        state: seed.state,
        updatedAt: DateTime(2026, 7, 24, 9 + index),
        createdAtLabel: '24 de julio de 2026',
        memberSinceLabel: 'Miembro desde 2024',
        attachedPhotoCount: seed.photos,
      );
      _requests[request.id] = request;
      _messages[request.id] = _initialMessages(request.id);
      _timeline[request.id] = _initialTimeline(request);
      if ((RequestStateMachine.definition(request.state).timelineStage?.index ??
              -1) >=
          TimelineStage.quotationSent.index) {
        _quotations[request.id] = Quotation(
          requestId: request.id,
          laborAmount: 45000 + (index * 5000),
          materialsAmount: 10000,
          workDescription: 'Incluye el trabajo y los materiales coordinados.',
          estimatedDuration: '1 día',
          startTiming: 'Por coordinar con el cliente',
          validityDays: 7,
        );
        _messages[request.id]!.insert(
          0,
          ConversationMessage(
            id: '${request.id}-seed-quotation-system',
            requestId: request.id,
            author: MessageAuthor.system,
            text: 'El profesional envió una cotización.',
            timeLabel: '9:20 a. m.',
          ),
        );
      }
    }
  }

  List<ConversationMessage> _initialMessages(String requestId) {
    return [
      ConversationMessage(
        id: '$requestId-customer-1',
        requestId: requestId,
        author: MessageAuthor.customer,
        text: 'Hola, quisiera coordinar los detalles del servicio.',
        timeLabel: '9:24 a. m.',
      ),
      ConversationMessage(
        id: '$requestId-professional-1',
        requestId: requestId,
        author: MessageAuthor.professional,
        text: 'Con gusto, revisaré la solicitud.',
        timeLabel: '9:26 a. m.',
      ),
    ];
  }

  List<TimelineEvent> _initialTimeline(ServiceRequest request) {
    const descriptions = [
      'La solicitud fue enviada al profesional.',
      'El profesional está revisando los detalles.',
      'El profesional compartió una cotización.',
      'La cotización fue aceptada por el cliente.',
      'El trabajo tiene una fecha coordinada.',
      'El profesional está realizando el trabajo.',
      'El trabajo fue marcado como completado.',
    ];
    const titles = [
      'Solicitud enviada',
      'Profesional revisando',
      'Cotización enviada',
      'Cotización aceptada',
      'Trabajo programado',
      'Trabajo en progreso',
      'Trabajo completado',
    ];
    final reachedIndex =
        RequestStateMachine.definition(request.state).timelineStage?.index ?? 0;
    return [
      for (var index = 0; index < TimelineStage.values.length; index++)
        TimelineEvent(
          id: '${request.id}-timeline-$index',
          requestId: request.id,
          stage: TimelineStage.values[index],
          title: titles[index],
          description: descriptions[index],
          dateLabel: index <= reachedIndex
              ? '24 jul, ${9 + index}:10 a. m.'
              : null,
        ),
    ];
  }
}

class _Seed {
  const _Seed({
    required this.id,
    required this.customer,
    required this.professional,
    required this.service,
    required this.category,
    required this.description,
    required this.location,
    required this.availability,
    required this.state,
    required this.photos,
  });

  final String id;
  final AppUser customer;
  final ProfessionalProfile professional;
  final String service;
  final ServiceCategory category;
  final String description;
  final String location;
  final String availability;
  final RequestState state;
  final int photos;
}
