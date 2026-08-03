import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linko/core/backend/data/mock_backend_repositories.dart';
import 'package:linko/core/backend/repositories/service_requests_repository.dart';
import 'package:linko/features/requests/data/mock_request_repository.dart';
import 'package:linko/features/requests/data/service_request_supabase_mapper.dart';
import 'package:linko/features/requests/domain/models/request_state.dart';
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
  });

  group('Supabase mapping', () {
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

    await expectLater(
      container.read(persistedCustomerRequestsProvider.future),
      throwsA(isA<StateError>()),
    );
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
}
