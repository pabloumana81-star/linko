import 'package:flutter_test/flutter_test.dart';
import 'package:linko/features/requests/domain/models/request_state.dart';
import 'package:linko/features/requests/domain/models/timeline_event.dart';
import 'package:linko/features/requests/domain/services/request_state_machine.dart';

void main() {
  test('defines the valid request lifecycle transitions', () {
    expect(
      RequestStateMachine.canTransition(
        RequestState.quoted,
        RequestState.accepted,
      ),
      isTrue,
    );
    expect(
      RequestStateMachine.canTransition(
        RequestState.accepted,
        RequestState.scheduled,
      ),
      isTrue,
    );
    expect(
      RequestStateMachine.canTransition(
        RequestState.quoted,
        RequestState.scheduled,
      ),
      isFalse,
    );
    expect(
      () => RequestStateMachine.ensureTransition(
        RequestState.completed,
        RequestState.inProgress,
      ),
      throwsStateError,
    );
    expect(
      RequestStateMachine.canTransition(
        RequestState.completed,
        RequestState.reviewed,
      ),
      isTrue,
    );
    expect(
      RequestStateMachine.canTransition(
        RequestState.inProgress,
        RequestState.reviewed,
      ),
      isFalse,
    );
    expect(
      RequestStateMachine.canTransition(
        RequestState.pendingCustomerConfirmation,
        RequestState.reviewed,
      ),
      isFalse,
    );
    expect(
      RequestStateMachine.canTransition(
        RequestState.reviewed,
        RequestState.reviewed,
      ),
      isFalse,
    );
  });

  test('removes obsolete actions as the request advances', () {
    expect(
      RequestState.quoted.definition.customerActions,
      contains(RequestAction.viewQuotation),
    );
    expect(
      RequestState.quoted.definition.customerPrimaryAction,
      RequestAction.viewQuotation,
    );
    expect(
      RequestState.quoted.definition.customerActions,
      contains(RequestAction.acceptQuotation),
    );
    expect(
      RequestState.accepted.definition.customerActions,
      isNot(contains(RequestAction.viewQuotation)),
    );
    expect(
      RequestState.accepted.definition.professionalActions,
      contains(RequestAction.proposeSchedule),
    );
    expect(
      RequestState.accepted.definition.professionalPrimaryAction,
      RequestAction.proposeSchedule,
    );
    expect(
      RequestState.scheduled.definition.professionalActions,
      isNot(contains(RequestAction.proposeSchedule)),
    );
    expect(
      RequestState.scheduled.definition.professionalActions,
      contains(RequestAction.startJob),
    );
    expect(
      RequestState.inProgress.definition.professionalActions,
      isNot(contains(RequestAction.startJob)),
    );
    expect(
      RequestState.inProgress.definition.professionalPrimaryAction,
      RequestAction.markJobCompleted,
    );
    expect(
      RequestState.pendingCustomerConfirmation.definition.customerActions,
      containsAll([RequestAction.confirmJob, RequestAction.reportProblem]),
    );
    expect(
      RequestState.pendingCustomerConfirmation.definition.professionalActions,
      isNot(contains(RequestAction.markJobCompleted)),
    );
    expect(
      RequestState.completed.definition.customerActions,
      contains(RequestAction.rateService),
    );
    expect(
      RequestState.completed.definition.professionalActions,
      isNot(contains(RequestAction.rateService)),
    );
    expect(
      RequestState.reviewed.definition.customerActions,
      isNot(contains(RequestAction.rateService)),
    );
  });

  test('centralizes badges, headers, next step, and timeline stage', () {
    final scheduled = RequestState.scheduled.definition;

    expect(scheduled.customerLabel, 'Trabajo programado');
    expect(scheduled.professionalLabel, 'Trabajo programado');
    expect(scheduled.conversationLabel, 'Trabajo programado');
    expect(scheduled.timelineStage, TimelineStage.workScheduled);
    expect(scheduled.nextStep, 'Esperar que el profesional inicie el trabajo.');
  });
}
