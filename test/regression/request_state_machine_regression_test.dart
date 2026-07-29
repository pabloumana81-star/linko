import 'package:flutter_test/flutter_test.dart';
import 'package:linko/features/requests/domain/models/request_state.dart';
import 'package:linko/features/requests/domain/services/request_state_machine.dart';

void main() {
  const workflow = <RequestState>[
    RequestState.pending,
    RequestState.quoted,
    RequestState.accepted,
    RequestState.scheduled,
    RequestState.inProgress,
    RequestState.pendingCustomerConfirmation,
    RequestState.completed,
    RequestState.reviewed,
  ];

  const validTransitions = <(RequestState, RequestState)>{
    (RequestState.pending, RequestState.quoted),
    (RequestState.quoted, RequestState.accepted),
    (RequestState.accepted, RequestState.scheduled),
    (RequestState.scheduled, RequestState.inProgress),
    (RequestState.inProgress, RequestState.pendingCustomerConfirmation),
    (RequestState.pendingCustomerConfirmation, RequestState.completed),
    (RequestState.completed, RequestState.reviewed),
  };

  test('acepta cada transición consecutiva del flujo principal', () {
    for (final transition in validTransitions) {
      expect(
        RequestStateMachine.canTransition(transition.$1, transition.$2),
        isTrue,
        reason: '${transition.$1.name} -> ${transition.$2.name}',
      );
      expect(
        () =>
            RequestStateMachine.ensureTransition(transition.$1, transition.$2),
        returnsNormally,
      );
    }
  });

  test(
    'rechaza todas las transiciones no consecutivas del flujo principal',
    () {
      for (final from in workflow) {
        for (final to in workflow) {
          if (validTransitions.contains((from, to))) {
            continue;
          }
          expect(
            RequestStateMachine.canTransition(from, to),
            isFalse,
            reason: '${from.name} -> ${to.name}',
          );
          expect(
            () => RequestStateMachine.ensureTransition(from, to),
            throwsStateError,
            reason: '${from.name} -> ${to.name}',
          );
        }
      }
    },
  );
}
