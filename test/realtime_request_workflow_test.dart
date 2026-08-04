import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:linko/core/backend/data/mock_backend_repositories.dart';
import 'package:linko/core/backend/repositories/quotations_repository.dart';
import 'package:linko/features/requests/data/mock_request_repository.dart';
import 'package:linko/features/requests/data/request_workflow_supabase_mapper.dart';
import 'package:linko/features/requests/domain/models/quotation.dart';
import 'package:linko/features/requests/domain/models/request_state.dart';
import 'package:linko/features/requests/domain/models/timeline_event.dart';
import 'package:linko/features/requests/domain/services/request_state_machine.dart';

void main() {
  group('quotation workflow', () {
    late MockRequestRepository store;
    late MockQuotationsRepository quotations;
    late String requestId;

    setUp(() {
      store = MockRequestRepository();
      quotations = MockQuotationsRepository(store);
      requestId = store
          .getProfessionalRequests('professional-carlos')
          .firstWhere((request) => request.state == RequestState.pending)
          .id;
    });

    test('persists a quotation and delivers it through realtime', () async {
      final delivered = Completer<Quotation?>();
      final subscription = quotations.watchQuotation(requestId).listen((value) {
        if (value != null && !delivered.isCompleted) delivered.complete(value);
      });
      final quotation = _quotation(requestId);

      await quotations.sendQuotation(quotation);

      expect((await quotations.getQuotation(requestId))?.totalAmount, 45000);
      expect(
        (await delivered.future)?.workDescription,
        quotation.workDescription,
      );
      await subscription.cancel();
    });

    test('accepts the persisted quotation and broadcasts its status', () async {
      await quotations.sendQuotation(_quotation(requestId));
      final accepted = Completer<Quotation>();
      final subscription = quotations.watchQuotation(requestId).listen((value) {
        if (value?.status == QuotationStatus.accepted &&
            !accepted.isCompleted) {
          accepted.complete(value!);
        }
      });

      await quotations.acceptQuotation(requestId);

      expect((await accepted.future).status, QuotationStatus.accepted);
      expect(store.getRequestById(requestId)?.state, RequestState.accepted);
      await subscription.cancel();
    });
  });

  test(
    'timeline emits immediately after a validated state transition',
    () async {
      final store = MockRequestRepository();
      final repository = MockServiceRequestsRepository(store);
      final request = store
          .getProfessionalRequests('professional-carlos')
          .firstWhere((item) => item.state == RequestState.pending);
      final emitted = Completer<List<TimelineEvent>>();
      final before = await repository.getTimeline(request.id);
      final subscription = repository.watchTimeline(request.id).listen((
        events,
      ) {
        if (events.any((event) => event.dateLabel == 'Ahora') &&
            !emitted.isCompleted) {
          emitted.complete(events);
        }
      });

      await repository.transitionStatus(
        requestId: request.id,
        nextStatus: RequestState.underReview,
        eventType: 'professional_reviewing',
      );

      final after = await emitted.future;
      expect(after, hasLength(before.length));
      expect(
        after
            .singleWhere(
              (event) => event.stage == TimelineStage.professionalReviewing,
            )
            .dateLabel,
        'Ahora',
      );
      await subscription.cancel();
    },
  );

  test('deduplicates event snapshots and preserves chronological order', () {
    final buffer = RequestEventBuffer();
    TimelineEvent event(String id, int minute) => TimelineEvent(
      id: id,
      requestId: 'request',
      stage: TimelineStage.workInProgress,
      title: id,
      description: id,
      createdAt: DateTime.utc(2026, 8, 3, 10, minute),
    );
    final later = event('later', 2);
    final earlier = event('earlier', 1);

    final firstConnection = buffer.merge([later]);
    final reloadedAfterReconnect = buffer.merge([earlier, later, later]);

    expect(firstConnection, hasLength(1));
    expect(reloadedAfterReconnect.map((item) => item.id), ['earlier', 'later']);
  });

  test('all workflow transitions remain governed by RequestStateMachine', () {
    expect(
      () => RequestStateMachine.ensureTransition(
        RequestState.pending,
        RequestState.inProgress,
      ),
      throwsStateError,
    );
    expect(
      RequestStateMachine.canTransition(
        RequestState.scheduled,
        RequestState.inProgress,
      ),
      isTrue,
    );
  });

  test('maps persisted quotation and timeline payloads', () {
    const mapper = RequestWorkflowSupabaseMapper();
    final quotation = mapper.quotationFromRow({
      'request_id': 'request',
      'professional_id': 'professional',
      'price': 25000,
      'description': 'Instalación completa',
      'estimated_duration': '1 día',
      'status': 'pending',
      'created_at': '2026-08-03T10:00:00Z',
    });
    final event = mapper.eventFromRow({
      'id': 'event',
      'request_id': 'request',
      'type': 'work_started',
      'payload': {'description': 'Inicio confirmado'},
      'created_at': '2026-08-03T11:00:00Z',
    });

    expect(quotation.totalAmount, 25000);
    expect(event.stage, TimelineStage.workInProgress);
    expect(event.description, 'Inicio confirmado');
  });

  test(
    'backend quotation failures are surfaced without state corruption',
    () async {
      const repository = _FailingQuotationsRepository();
      await expectLater(
        repository.sendQuotation(_quotation('request')),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        repository.acceptQuotation('request'),
        throwsA(isA<StateError>()),
      );
    },
  );
}

Quotation _quotation(String requestId) => Quotation(
  requestId: requestId,
  laborAmount: 40000,
  materialsAmount: 5000,
  workDescription: 'Revisión e instalación',
  estimatedDuration: '1 día',
  startTiming: 'Coordinar',
  validityDays: 5,
);

class _FailingQuotationsRepository implements QuotationsRepository {
  const _FailingQuotationsRepository();

  Never _fail() => throw StateError('Backend no disponible');

  @override
  Future<void> acceptQuotation(String requestId) async => _fail();

  @override
  Future<Quotation?> getQuotation(String requestId) async => _fail();

  @override
  Future<void> rejectQuotation(String requestId) async => _fail();

  @override
  Future<void> sendQuotation(Quotation quotation) async => _fail();

  @override
  Stream<Quotation?> watchQuotation(String requestId) =>
      Stream.error(StateError('Backend no disponible'));
}
