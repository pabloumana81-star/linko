import 'package:flutter_test/flutter_test.dart';
import 'package:linko/features/admin/domain/admin_request.dart';
import 'package:linko/features/requests/data/mock_request_repository.dart';
import 'package:linko_admin/features/admin/data/mock_admin_reports_repository.dart';
import 'package:linko_admin/features/admin/data/mock_admin_requests_repository.dart';
import 'package:linko_admin/features/admin/domain/admin_report.dart';

void main() {
  AdminReport report() {
    final now = DateTime(2026, 8, 9);
    return AdminReport(
      id: 'report-1',
      reporterName: 'Cliente QA',
      requestTitle: 'Solicitud QA',
      reason: 'Incidente QA',
      status: 'open',
      createdAt: now,
      updatedAt: now,
    );
  }

  for (final action in AdminReportAction.values) {
    test('mock admin can ${action.name} a report and creates audit', () async {
      final repository = MockAdminReportsRepository(seed: [report()]);
      await repository.performAction('report-1', action, 'Motivo verificable');
      final updated = (await repository.listReports()).single;
      expect(updated.status, switch (action) {
        AdminReportAction.resolve => 'resolved',
        AdminReportAction.dismiss => 'dismissed',
        AdminReportAction.escalate => 'escalated',
      });
      expect(updated.auditHistory.single.note, 'Motivo verificable');
    });
  }

  test(
    'report operations require a reason and reject repeated action',
    () async {
      final repository = MockAdminReportsRepository(seed: [report()]);
      await expectLater(
        repository.performAction('report-1', AdminReportAction.resolve, '  '),
        throwsArgumentError,
      );
      await repository.performAction(
        'report-1',
        AdminReportAction.escalate,
        'Revisión externa',
      );
      await expectLater(
        repository.performAction(
          'report-1',
          AdminReportAction.escalate,
          'Otra vez',
        ),
        throwsStateError,
      );
    },
  );

  test(
    'request review and intervention preserve workflow state and audit',
    () async {
      final repository = MockAdminRequestsRepository(MockRequestRepository());
      final initial = (await repository.listRequests()).first;
      await repository.performAction(
        initial.id,
        AdminRequestAction.flagForReview,
        'Revisar conversación',
      );
      await repository.performAction(
        initial.id,
        AdminRequestAction.addInterventionNote,
        'Seguimiento registrado',
      );
      final updated = (await repository.listRequests()).firstWhere(
        (item) => item.id == initial.id,
      );
      expect(updated.status, initial.status);
      expect(updated.adminReviewFlag, isTrue);
      expect(updated.auditHistory, hasLength(2));
    },
  );

  test('request action requires reason and duplicate flag is safe', () async {
    final repository = MockAdminRequestsRepository(MockRequestRepository());
    final request = (await repository.listRequests()).first;
    await expectLater(
      repository.performAction(
        request.id,
        AdminRequestAction.flagForReview,
        '',
      ),
      throwsArgumentError,
    );
    await repository.performAction(
      request.id,
      AdminRequestAction.flagForReview,
      'Primera revisión',
    );
    await expectLater(
      repository.performAction(
        request.id,
        AdminRequestAction.flagForReview,
        'Duplicada',
      ),
      throwsStateError,
    );
  });

  test(
    'request cancellation archives an active request but never reopens a final one',
    () async {
      final repository = MockAdminRequestsRepository(MockRequestRepository());
      final requests = await repository.listRequests();
      final active = requests.firstWhere(
        (item) => !{
          'pendingCustomerConfirmation',
          'completed',
          'reviewed',
          'cancelled',
        }.contains(item.status),
      );
      await repository.performAction(
        active.id,
        AdminRequestAction.cancel,
        'Cancelación operativa justificada',
      );
      final cancelled = (await repository.listRequests()).firstWhere(
        (item) => item.id == active.id,
      );
      expect(cancelled.status, 'cancelled');
      expect(cancelled.auditHistory.single.action, 'cancel');

      final finalRequest = requests
          .where(
            (item) => {
              'pendingCustomerConfirmation',
              'completed',
              'reviewed',
              'cancelled',
            }.contains(item.status),
          )
          .firstOrNull;
      if (finalRequest != null) {
        await expectLater(
          repository.performAction(
            finalRequest.id,
            AdminRequestAction.cancel,
            'Intento inválido',
          ),
          throwsStateError,
        );
      }
    },
  );
}
