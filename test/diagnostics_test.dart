import 'package:flutter_test/flutter_test.dart';
import 'package:linko/core/diagnostics/diagnostics_service.dart';
import 'package:linko/features/requests/domain/models/request_state.dart';

void main() {
  group('diagnósticos de producción', () {
    test('cada evento de flujo genera un registro estructurado completo', () {
      final sink = _MemorySink();
      final timestamp = DateTime.utc(2026, 8, 3, 12, 30);
      final diagnostics = DiagnosticsService(
        sink: sink,
        clock: () => timestamp,
      );

      for (final type in WorkflowEventType.values) {
        diagnostics.workflow(
          type: type,
          requestId: 'request-123',
          customerId: 'customer-456',
          professionalId: 'professional-789',
          previousState: RequestState.accepted,
          newState: RequestState.scheduled,
        );
      }

      expect(sink.records, hasLength(WorkflowEventType.values.length));
      expect(
        sink.records.map((record) => record['event']),
        WorkflowEventType.values.map((type) => type.name),
      );
      for (final record in sink.records) {
        expect(record, {
          'kind': 'workflow',
          'event': isA<String>(),
          'requestId': 'request-123',
          'customerId': 'customer-456',
          'professionalId': 'professional-789',
          'timestamp': '2026-08-03T12:30:00.000Z',
          'previousState': 'accepted',
          'newState': 'scheduled',
        });
      }
      expect(
        diagnostics.lastWorkflowEvent?.type,
        WorkflowEventType.ratingSubmitted,
      );
    });

    test('request creation supports a null previous state', () {
      final sink = _MemorySink();
      final diagnostics = DiagnosticsService(sink: sink);

      diagnostics.workflow(
        type: WorkflowEventType.requestCreated,
        requestId: 'request-new',
        customerId: 'customer-current',
        professionalId: 'professional-carlos',
        previousState: null,
        newState: RequestState.pending,
      );

      expect(sink.records.single['previousState'], isNull);
      expect(sink.records.single['newState'], 'pending');
    });

    test(
      'async failures include context, error and full stack trace',
      () async {
        final sink = _MemorySink();
        final diagnostics = DiagnosticsService(sink: sink);

        await expectLater(
          diagnostics.guard<void>('test_operation', () async {
            throw StateError('fallo esperado');
          }),
          throwsStateError,
        );

        final record = sink.records.single;
        expect(record['kind'], 'unexpected_error');
        expect(record['context'], 'test_operation');
        expect(record['error'], contains('fallo esperado'));
        expect(record['stackTrace'], contains('diagnostics_test.dart'));
        expect(record['timestamp'], isA<String>());
      },
    );

    test('backend startup diagnostics never include secrets', () {
      final sink = _MemorySink();
      final diagnostics = DiagnosticsService(sink: sink);

      diagnostics.backendStartup(
        backendMode: 'supabase',
        hasSupabaseUrl: true,
        hasSupabaseAnonKey: true,
        repositoryImplementation: 'Supabase',
      );

      final record = sink.records.single;
      expect(record['kind'], 'backend_startup');
      expect(record['backendMode'], 'supabase');
      expect(record['hasSupabaseUrl'], isTrue);
      expect(record['hasSupabaseAnonKey'], isTrue);
      expect(record['repositoryImplementation'], 'Supabase');
      expect(record.containsKey('supabaseUrl'), isFalse);
      expect(record.containsKey('supabaseAnonKey'), isFalse);
    });

    test('authentication tokens are redacted from errors and stack traces', () {
      final sink = _MemorySink();
      final diagnostics = DiagnosticsService(sink: sink);

      diagnostics.unexpectedError(
        StateError(
          'access_token=token-visible refresh_token: refresh-visible '
          'Authorization: Bearer bearer-visible',
        ),
        StackTrace.fromString('id_token="identity-visible"'),
        context: 'auth_callback',
      );

      final serialized = sink.records.single.toString();
      expect(serialized, isNot(contains('token-visible')));
      expect(serialized, isNot(contains('refresh-visible')));
      expect(serialized, isNot(contains('bearer-visible')));
      expect(serialized, isNot(contains('identity-visible')));
      expect(serialized, contains('[REDACTED]'));
    });

    test('signed URLs, Magic Links and standalone JWTs are redacted', () {
      final sink = _MemorySink();
      final diagnostics = DiagnosticsService(sink: sink);
      const jwt =
          'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1c2VyLXByaXZhdGUifQ.signaturePrivate';

      diagnostics.unexpectedError(
        StateError(
          'https://project.supabase.co/storage/v1/object/sign/private/file.pdf'
          '?token=signed-private&code=oauth-private&token_hash=magic-private '
          '$jwt',
        ),
        StackTrace.fromString('signature=storage-private'),
        context: 'secure_url',
      );

      final serialized = sink.records.single.toString();
      for (final secret in [
        'signed-private',
        'oauth-private',
        'magic-private',
        'storage-private',
        jwt,
      ]) {
        expect(serialized, isNot(contains(secret)));
      }
      expect(serialized, contains('[REDACTED]'));
    });
  });
}

class _MemorySink implements DiagnosticsSink {
  final records = <Map<String, Object?>>[];

  @override
  void write(Map<String, Object?> record) => records.add(record);
}
