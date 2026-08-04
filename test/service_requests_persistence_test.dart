import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linko/core/backend/data/mock_backend_repositories.dart';
import 'package:linko/core/backend/repositories/service_requests_repository.dart';
import 'package:linko/features/requests/data/mock_request_repository.dart';
import 'package:linko/features/requests/data/service_request_supabase_mapper.dart';
import 'package:linko/features/requests/domain/models/request_state.dart';
import 'package:linko/features/requests/domain/models/app_user.dart';
import 'package:linko/features/requests/domain/models/professional_profile.dart';
import 'package:linko/features/requests/domain/models/service_request.dart';
import 'package:linko/features/requests/domain/models/timeline_event.dart';
import 'package:linko/features/requests/presentation/providers/request_providers.dart';

void main() {
  group('service request persistence contract', () {
    late MockRequestRepository sharedStore;
    late MockServiceRequestsRepository repository;

    setUp(() {
      sharedStore = MockRequestRepository();
      repository = MockServiceRequestsRepository(sharedStore);
    });

    test(
      'creates and lists the same request for both involved sides',
      () async {
        final source = sharedStore
            .getProfessionalRequests(currentProfessionalId)
            .first;
        final request = ServiceRequest(
          id: 'shared-request',
          customer: source.customer,
          professional: source.professional,
          serviceName: source.serviceName,
          category: source.category,
          description: 'Reparar una fuga compartida',
          location: source.location,
          availabilityLabel: source.availabilityLabel,
          state: RequestState.pending,
          updatedAt: DateTime.utc(2026, 8, 3),
          createdAt: DateTime.utc(2026, 8, 3),
          createdAtLabel: 'Ahora',
          memberSinceLabel: source.memberSinceLabel,
          attachedPhotoCount: 0,
        );

        await repository.createRequest(request);

        final customerRows = await repository.listCustomerRequests(
          request.customer.id,
        );
        final professionalRows = await repository.listProfessionalRequests(
          request.professional.user.id,
        );
        expect(customerRows.any((item) => item.id == request.id), isTrue);
        expect(professionalRows.any((item) => item.id == request.id), isTrue);
        expect(
          customerRows.singleWhere((item) => item.id == request.id),
          same(professionalRows.singleWhere((item) => item.id == request.id)),
        );
      },
    );

    test('customer and professional observe a shared status update', () async {
      final request = (await repository.listProfessionalRequests(
        currentProfessionalId,
      )).first;
      await repository.updateStatus(request.id, RequestState.underReview);

      expect(
        (await repository.getRequestById(request.id))?.state,
        RequestState.underReview,
      );
      expect(
        (await repository.listCustomerRequests(
          request.customer.id,
        )).singleWhere((item) => item.id == request.id).state,
        RequestState.underReview,
      );
    });

    test('collection streams refresh both request lists', () async {
      final source = sharedStore
          .getProfessionalRequests(currentProfessionalId)
          .first;
      final request = ServiceRequest(
        id: 'realtime-shared-request',
        customer: source.customer,
        professional: source.professional,
        serviceName: source.serviceName,
        category: source.category,
        description: 'Solicitud recibida sin recargar',
        location: source.location,
        availabilityLabel: source.availabilityLabel,
        state: RequestState.pending,
        updatedAt: DateTime.utc(2026, 8, 3),
        createdAtLabel: 'Ahora',
        memberSinceLabel: source.memberSinceLabel,
        attachedPhotoCount: 0,
      );
      final customerReceived = repository
          .watchCustomerRequests(request.customer.id)
          .firstWhere((rows) => rows.any((item) => item.id == request.id));
      final professionalReceived = repository
          .watchProfessionalRequests(request.professional.user.id)
          .firstWhere((rows) => rows.any((item) => item.id == request.id));

      await repository.createRequest(request);

      expect(await customerReceived, contains(request));
      expect(await professionalReceived, contains(request));
    });
  });

  group('Supabase mapping', () {
    test('accepts only UUID identifiers for persisted requests', () {
      const mapper = ServiceRequestSupabaseMapper();
      final request = ServiceRequest(
        id: '018f47a6-7200-4d31-8f6c-1bc183202111',
        customer: const AppUser(
          id: '018f47a6-7200-4d31-8f6c-1bc183202222',
          name: 'Cliente',
        ),
        professional: const ProfessionalProfile(
          id: '018f47a6-7200-4d31-8f6c-1bc183202333',
          user: AppUser(
            id: '018f47a6-7200-4d31-8f6c-1bc183202333',
            name: 'Profesional',
          ),
          profession: 'Electricista',
          rating: 5,
          reviewCount: 1,
          location: 'San José',
        ),
        serviceName: 'Electricista',
        category: ServiceCategory.electrical,
        description: 'Revisión',
        location: 'San José',
        availabilityLabel: 'Flexible',
        state: RequestState.pending,
        updatedAt: DateTime.utc(2026, 8, 3),
        createdAtLabel: 'Ahora',
        memberSinceLabel: 'Miembro',
        attachedPhotoCount: 0,
      );

      expect(
        mapper.toInsert(request)['professional_id'],
        request.professional.id,
      );
      expect(
        () => mapper.toInsert(
          ServiceRequest(
            id: 'request-temporal',
            customer: request.customer,
            professional: request.professional,
            serviceName: request.serviceName,
            category: request.category,
            description: request.description,
            location: request.location,
            availabilityLabel: request.availabilityLabel,
            state: request.state,
            updatedAt: request.updatedAt,
            createdAtLabel: request.createdAtLabel,
            memberSinceLabel: request.memberSinceLabel,
            attachedPhotoCount: request.attachedPhotoCount,
          ),
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('maps every status explicitly in both directions', () {
      for (final status in RequestStatus.values) {
        final stored = RequestStatusMapper.toDatabase(status);
        expect(RequestStatusMapper.fromDatabase(stored), status);
      }
      expect(
        RequestStatusMapper.toDatabase(RequestStatus.inProgress),
        'in_progress',
      );
    });

    test('rejects an invalid status with a controlled Spanish message', () {
      expect(
        () => RequestStatusMapper.fromDatabase('desconocido'),
        throwsA(
          isA<InvalidRequestStatusException>().having(
            (error) => error.message,
            'message',
            'El estado de la solicitud no es válido.',
          ),
        ),
      );
    });
  });

  test('a backend failure becomes AsyncError instead of crashing', () async {
    final container = ProviderContainer(
      overrides: [
        activeServiceRequestsRepositoryProvider.overrideWithValue(
          const _FailingServiceRequestsRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final failed = Completer<void>();
    final subscription = container.listen(persistedCustomerRequestsProvider, (
      previous,
      next,
    ) {
      if (next.hasError && !failed.isCompleted) failed.complete();
    }, fireImmediately: true);
    addTearDown(subscription.close);
    await failed.future;
    expect(
      container.read(persistedCustomerRequestsProvider),
      isA<AsyncError<List<ServiceRequest>>>(),
    );
  });
}

class _FailingServiceRequestsRepository implements ServiceRequestsRepository {
  const _FailingServiceRequestsRepository();

  Never _fail() => throw StateError('Backend no disponible');

  @override
  Future<void> createRequest(ServiceRequest request) async => _fail();

  @override
  Future<ServiceRequest?> getRequestById(String requestId) async => _fail();

  @override
  Future<List<ServiceRequest>> listCustomerRequests(String customerId) async =>
      _fail();

  @override
  Future<List<ServiceRequest>> listProfessionalRequests(
    String professionalId,
  ) async => _fail();

  @override
  Stream<List<ServiceRequest>> watchCustomerRequests(String customerId) =>
      Stream.error(StateError('Backend no disponible'));

  @override
  Stream<List<ServiceRequest>> watchProfessionalRequests(
    String professionalId,
  ) => Stream.error(StateError('Backend no disponible'));

  @override
  Future<List<ServiceRequest>> getCustomerRequests(String customerId) =>
      listCustomerRequests(customerId);

  @override
  Future<List<ServiceRequest>> getProfessionalRequests(String professionalId) =>
      listProfessionalRequests(professionalId);

  @override
  Future<List<TimelineEvent>> getTimeline(String requestId) async => _fail();

  @override
  Future<void> updateSchedule(String requestId, DateTime? scheduledAt) async =>
      _fail();

  @override
  Future<void> updateStatus(String requestId, RequestState state) async =>
      _fail();

  @override
  Stream<RequestStatus> watchStatus(String requestId) => Stream.error(_fail());

  @override
  Stream<List<TimelineEvent>> watchTimeline(String requestId) =>
      Stream.error(_fail());

  @override
  Future<void> transitionStatus({
    required String requestId,
    required RequestStatus nextStatus,
    required String eventType,
    Map<String, dynamic> payload = const {},
  }) async => _fail();

  @override
  Future<void> appendEvent({
    required String requestId,
    required String eventType,
    Map<String, dynamic> payload = const {},
  }) async => _fail();
}
