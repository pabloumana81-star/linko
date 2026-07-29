import 'package:flutter_test/flutter_test.dart';
import 'package:linko/features/requests/data/mock_request_repository.dart';
import 'package:linko/features/requests/domain/models/app_user.dart';
import 'package:linko/features/requests/domain/models/conversation_message.dart';
import 'package:linko/features/requests/domain/models/professional_profile.dart';
import 'package:linko/features/requests/domain/models/quotation.dart';
import 'package:linko/features/requests/domain/models/request_state.dart';
import 'package:linko/features/requests/domain/models/service_request.dart';
import 'package:linko/features/requests/domain/models/service_rating.dart';
import 'package:linko/features/requests/domain/models/timeline_event.dart';

void main() {
  late MockRequestRepository repository;

  setUp(() {
    repository = MockRequestRepository();
  });

  test(
    'loads professional requests from the shared collection by assignee',
    () {
      final customerRequests = repository.getCustomerRequests(
        'customer-current',
      );
      final professionalRequests = repository.getProfessionalRequests(
        'professional-carlos',
      );

      expect(customerRequests, isNotEmpty);
      expect(professionalRequests, isNotEmpty);
      expect(
        professionalRequests,
        everyElement(
          predicate<ServiceRequest>(
            (request) => request.professional.user.id == 'professional-carlos',
          ),
        ),
      );
      expect(
        customerRequests.map((request) => request.id),
        containsAll(professionalRequests.map((request) => request.id)),
      );
      expect(
        repository.getRequestById(professionalRequests.first.id),
        same(professionalRequests.first),
      );
    },
  );

  test(
    'new customer request is persisted and appears only for its assignee',
    () {
      final request = ServiceRequest(
        id: 'request-new-carlos',
        customer: const AppUser(id: 'customer-current', name: 'Cliente LinkO'),
        professional: const ProfessionalProfile(
          id: 'profile-professional-carlos',
          user: AppUser(id: 'professional-carlos', name: 'Carlos Rodríguez'),
          profession: 'Electricista',
          rating: 4.9,
          reviewCount: 128,
          location: 'San José',
        ),
        serviceName: 'Electricista',
        category: ServiceCategory.electrical,
        description: 'Revisión de una instalación residencial.',
        location: 'Escazú, San José',
        availabilityLabel: 'Soy flexible',
        state: RequestState.pending,
        updatedAt: DateTime(2026, 7, 27),
        createdAtLabel: 'Ahora',
        memberSinceLabel: 'Miembro desde 2026',
        attachedPhotoCount: 0,
      );

      repository.createRequest(request);

      expect(repository.getRequestById(request.id), same(request));
      expect(
        repository.getCustomerRequests('customer-current'),
        contains(same(request)),
      );
      expect(
        repository.getProfessionalRequests('professional-carlos'),
        contains(same(request)),
      );
      expect(
        repository.getProfessionalRequests('professional-maria'),
        isNot(contains(same(request))),
      );
    },
  );

  test('sending quotation stores it and updates all related request data', () {
    final request = repository.getCustomerRequests('customer-current').first;
    final messagesBefore = repository.getMessages(request.id).length;
    final quotationEventBefore = repository
        .getTimeline(request.id)
        .firstWhere((event) => event.stage == TimelineStage.quotationSent);
    expect(quotationEventBefore.dateLabel, isNull);

    const quotation = Quotation(
      requestId: 'request-ana-air',
      laborAmount: 25000,
      materialsAmount: 5000,
      workDescription: 'Diagnóstico y reparación completa del equipo.',
      estimatedDuration: 'Medio día',
      startTiming: 'Lo antes posible',
      validityDays: 7,
    );
    repository.sendQuotation(quotation);

    expect(repository.getQuotation(request.id), same(quotation));
    expect(repository.getRequestById(request.id)?.state, RequestState.quoted);
    expect(repository.getMessages(request.id), hasLength(messagesBefore + 1));
    expect(
      repository.getMessages(request.id).last.author,
      MessageAuthor.system,
    );
    expect(
      repository.getMessages(request.id).last.text,
      'El profesional envió una cotización.',
    );
    expect(
      repository
          .getTimeline(request.id)
          .firstWhere((event) => event.stage == TimelineStage.quotationSent)
          .dateLabel,
      'Ahora',
    );
  });

  test(
    'accepting quotation synchronizes status, timeline, and conversation',
    () {
      const requestId = 'request-laura-maintenance';
      final messagesBefore = repository.getMessages(requestId).length;

      repository.acceptQuotation(requestId);

      expect(
        repository.getRequestById(requestId)?.state,
        RequestState.accepted,
      );
      expect(
        repository
            .getProfessionalRequests('professional-maria')
            .singleWhere((request) => request.id == requestId)
            .state,
        RequestState.accepted,
      );
      expect(repository.getMessages(requestId), hasLength(messagesBefore + 1));
      expect(
        repository.getMessages(requestId).last.text,
        'El cliente aceptó la cotización.',
      );
      expect(
        repository
            .getTimeline(requestId)
            .firstWhere(
              (event) => event.stage == TimelineStage.quotationAccepted,
            )
            .dateLabel,
        'Ahora',
      );
    },
  );

  test('sending message appends it and updates request updatedAt', () {
    final request = repository.getCustomerRequests('customer-current')[1];
    final previousUpdatedAt = request.updatedAt;
    final previousCount = repository.getMessages(request.id).length;
    final message = ConversationMessage(
      id: 'new-message',
      requestId: request.id,
      author: MessageAuthor.customer,
      text: '¿Podemos coordinar para mañana?',
      timeLabel: 'Ahora',
    );

    repository.sendMessage(message);

    expect(repository.getMessages(request.id), hasLength(previousCount + 1));
    expect(repository.getMessages(request.id).last, same(message));
    expect(
      repository
          .getRequestById(request.id)!
          .updatedAt
          .isAfter(previousUpdatedAt),
      isTrue,
    );
  });

  test('updates request state in memory', () {
    final request = repository.getCustomerRequests('customer-current')[2];
    repository.acceptQuotation(request.id);
    repository.updateStatus(request.id, RequestState.scheduled);
    expect(
      repository.getRequestById(request.id)?.state,
      RequestState.scheduled,
    );
    expect(
      repository
          .getTimeline(request.id)
          .firstWhere((event) => event.stage == TimelineStage.workScheduled)
          .dateLabel,
      'Ahora',
    );
  });

  test('schedule proposal confirmation updates request and timeline', () {
    const requestId = 'request-laura-maintenance';
    repository.acceptQuotation(requestId);
    repository.proposeSchedule(requestId, '30/7/2026 a las 9:00 a. m.');
    final proposal = repository.getMessages(requestId).last;

    expect(proposal.type, ConversationMessageType.scheduleProposal);
    expect(proposal.scheduleStatus, ScheduleProposalStatus.pending);

    repository.confirmSchedule(requestId, proposal.id);

    expect(repository.getRequestById(requestId)?.state, RequestState.scheduled);
    expect(
      repository
          .getMessages(requestId)
          .firstWhere((message) => message.id == proposal.id)
          .scheduleStatus,
      ScheduleProposalStatus.confirmed,
    );
    expect(
      repository
          .getTimeline(requestId)
          .firstWhere((event) => event.stage == TimelineStage.workScheduled)
          .dateLabel,
      'Ahora',
    );
    expect(
      repository.getMessages(requestId).last.text,
      'El cliente confirmó la fecha del trabajo.',
    );
  });

  test('customer can request a change to schedule proposal', () {
    const requestId = 'request-laura-maintenance';
    repository.acceptQuotation(requestId);
    repository.proposeSchedule(requestId, '31/7/2026 a las 2:00 p. m.');
    final proposal = repository.getMessages(requestId).last;

    repository.requestScheduleChange(requestId, proposal.id);

    expect(
      repository
          .getMessages(requestId)
          .firstWhere((message) => message.id == proposal.id)
          .scheduleStatus,
      ScheduleProposalStatus.changeRequested,
    );
    expect(
      repository.getMessages(requestId).last.text,
      'El cliente solicitó cambiar la fecha del trabajo.',
    );
  });

  test('starting a scheduled job synchronizes all shared request data', () {
    const requestId = 'request-laura-maintenance';
    repository.acceptQuotation(requestId);
    repository.updateStatus(requestId, RequestState.scheduled);
    final messagesBefore = repository.getMessages(requestId).length;

    repository.startJob(requestId);

    expect(
      repository
          .getCustomerRequests('customer-current')
          .firstWhere((request) => request.id == requestId)
          .state,
      RequestState.inProgress,
    );
    expect(
      repository
          .getProfessionalRequests('professional-maria')
          .firstWhere((request) => request.id == requestId)
          .state,
      RequestState.inProgress,
    );
    expect(repository.getMessages(requestId), hasLength(messagesBefore + 1));
    expect(
      repository.getMessages(requestId).last.type,
      ConversationMessageType.workStarted,
    );
    expect(
      repository.getMessages(requestId).last.text,
      'El profesional inició el trabajo.',
    );
    expect(
      repository
          .getTimeline(requestId)
          .firstWhere((event) => event.stage == TimelineStage.workInProgress)
          .dateLabel,
      'Ahora',
    );
  });

  test('a job can only be started from scheduled state', () {
    const requestId = 'request-laura-maintenance';

    expect(() => repository.startJob(requestId), throwsA(isA<StateError>()));
  });

  test('professional completion waits for customer confirmation', () {
    const requestId = 'request-laura-maintenance';
    repository.acceptQuotation(requestId);
    repository.updateStatus(requestId, RequestState.scheduled);
    repository.startJob(requestId);

    repository.markJobCompleted(requestId);
    final messagesAfterCompletion = repository.getMessages(requestId).length;
    repository.markJobCompleted(requestId);

    expect(
      repository.getRequestById(requestId)?.state,
      RequestState.pendingCustomerConfirmation,
    );
    expect(
      repository
          .getProfessionalRequests('professional-maria')
          .singleWhere((request) => request.id == requestId)
          .state,
      RequestState.pendingCustomerConfirmation,
    );
    expect(
      repository.getMessages(requestId).last.type,
      ConversationMessageType.jobCompleted,
    );
    expect(
      repository.getMessages(requestId).last.text,
      'El profesional indicó que el trabajo ha finalizado.',
    );
    expect(
      repository.getMessages(requestId),
      hasLength(messagesAfterCompletion),
    );
    expect(() => repository.startJob(requestId), throwsStateError);
    expect(
      repository
          .getTimeline(requestId)
          .firstWhere((event) => event.stage == TimelineStage.workCompleted)
          .dateLabel,
      'Ahora',
    );
  });

  test('customer confirms completed job across the shared request', () {
    const requestId = 'request-laura-maintenance';
    repository.acceptQuotation(requestId);
    repository.updateStatus(requestId, RequestState.scheduled);
    repository.startJob(requestId);
    repository.markJobCompleted(requestId);

    repository.confirmJob(requestId);
    final messagesAfterConfirmation = repository.getMessages(requestId).length;
    repository.confirmJob(requestId);

    expect(repository.getRequestById(requestId)?.state, RequestState.completed);
    expect(
      repository
          .getCustomerRequests('customer-current')
          .singleWhere((request) => request.id == requestId)
          .state,
      RequestState.completed,
    );
    expect(
      repository.getMessages(requestId),
      hasLength(messagesAfterConfirmation),
    );
    expect(() => repository.markJobCompleted(requestId), returnsNormally);
    expect(
      repository
          .getProfessionalRequests('professional-maria')
          .singleWhere((request) => request.id == requestId)
          .state,
      RequestState.completed,
    );
  });

  test('reporting a problem keeps customer confirmation pending', () {
    const requestId = 'request-laura-maintenance';
    repository.acceptQuotation(requestId);
    repository.updateStatus(requestId, RequestState.scheduled);
    repository.startJob(requestId);
    repository.markJobCompleted(requestId);

    repository.reportCompletedWorkProblem(requestId);

    expect(
      repository.getRequestById(requestId)?.state,
      RequestState.pendingCustomerConfirmation,
    );
    expect(
      repository.getMessages(requestId).last.text,
      'El cliente reportó un problema con el trabajo realizado.',
    );
  });

  test('customer cannot confirm completion while work is in progress', () {
    const requestId = 'request-laura-maintenance';
    repository.acceptQuotation(requestId);
    repository.updateStatus(requestId, RequestState.scheduled);
    repository.startJob(requestId);

    expect(() => repository.confirmJob(requestId), throwsStateError);
    expect(
      repository.getRequestById(requestId)?.state,
      RequestState.inProgress,
    );
  });

  test('completed service accepts ratings from 1 to 5 stars', () {
    for (var stars = 1; stars <= 5; stars++) {
      final currentRepository = MockRequestRepository();
      currentRepository.submitRating(
        ServiceRating(
          requestId: 'request-elena-paint',
          professionalId: 'professional-daniel',
          stars: stars,
          comment: null,
        ),
      );

      expect(currentRepository.getRating('request-elena-paint')?.stars, stars);
      expect(
        currentRepository.getRequestById('request-elena-paint')?.state,
        RequestState.reviewed,
      );
    }
  });

  test('rating is shared, idempotent, and updates professional summary', () {
    const requestId = 'request-elena-paint';
    final before = repository.getProfessionalRatingSummary(
      'professional-daniel',
    );
    repository.submitRating(
      const ServiceRating(
        requestId: requestId,
        professionalId: 'professional-daniel',
        stars: 5,
        comment: 'Excelente servicio.',
      ),
    );
    final messagesAfterRating = repository.getMessages(requestId).length;
    repository.submitRating(
      const ServiceRating(
        requestId: requestId,
        professionalId: 'professional-daniel',
        stars: 1,
        comment: null,
      ),
    );
    final after = repository.getProfessionalRatingSummary(
      'professional-daniel',
    );

    expect(repository.getRating(requestId)?.comment, 'Excelente servicio.');
    expect(repository.getMessages(requestId), hasLength(messagesAfterRating));
    expect(
      repository.getMessages(requestId).last.text,
      'El cliente calificó el servicio.',
    );
    expect(after.reviewCount, before.reviewCount + 1);
    expect(
      after.averageRating,
      closeTo(
        (before.averageRating * before.reviewCount + 5) /
            (before.reviewCount + 1),
        0.0001,
      ),
    );
    expect(after.completedJobsCount, 1);
  });

  test('rating is blocked before completion', () {
    expect(
      () => repository.submitRating(
        const ServiceRating(
          requestId: 'request-marco-review',
          professionalId: 'professional-sofia',
          stars: 5,
          comment: null,
        ),
      ),
      throwsStateError,
    );
    expect(repository.getRating('request-marco-review'), isNull);
  });
}
