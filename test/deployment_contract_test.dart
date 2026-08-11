import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('contrato de despliegue web', () {
    test(
      'release wrapper validates production config without printing values',
      () {
        final script = File('scripts/build_web_release.sh').readAsStringSync();

        expect(script, contains('BACKEND_MODE debe ser supabase'));
        expect(script, contains('SUPABASE_URL debe ser una URL HTTPS'));
        expect(script, contains('SUPABASE_ANON_KEY es obligatoria'));
        expect(script, contains('io.supabase.linko://login-callback/'));
        expect(script, contains('--dart-define-from-file="\$env_file"'));
        expect(
          script,
          isNot(contains('printf \'%s\\n\' "\$supabase_anon_key"')),
        );
        expect(script, isNot(contains('set -x')));
      },
    );

    test('security-header contract contains the beta baseline', () {
      final headers = File(
        'deployment/security_headers.example',
      ).readAsStringSync().toLowerCase();

      for (final directive in const [
        'strict-transport-security:',
        'x-content-type-options: nosniff',
        'referrer-policy:',
        'permissions-policy:',
        'content-security-policy:',
        "frame-ancestors 'none'",
        "object-src 'none'",
        "worker-src 'self' blob:",
      ]) {
        expect(headers, contains(directive));
      }
      expect(headers, contains('<supabase_origin>'));
      expect(headers, isNot(contains("default-src *")));
    });

    test(
      'release wrapper rejects incomplete config before invoking Flutter',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'linko-release-contract-',
        );
        addTearDown(() => directory.delete(recursive: true));
        final invalidEnvironment = File('${directory.path}/invalid.env')
          ..writeAsStringSync('''
BACKEND_MODE=mock
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=private-value-that-must-not-be-printed
AUTH_REDIRECT_URL=io.supabase.linko://login-callback/
''');

        final result = await Process.run('sh', [
          'scripts/build_web_release.sh',
          invalidEnvironment.path,
        ]);

        expect(result.exitCode, isNot(0));
        expect(result.stderr, contains('BACKEND_MODE debe ser supabase'));
        expect(
          result.stdout,
          isNot(contains('private-value-that-must-not-be-printed')),
        );
        expect(
          result.stderr,
          isNot(contains('private-value-that-must-not-be-printed')),
        );
      },
    );

    test('SPA contract and health check cover reconstructed routes', () {
      final fallback = File(
        'deployment/spa_fallback.example',
      ).readAsStringSync();
      final healthCheck = File(
        'scripts/post_deploy_check.sh',
      ).readAsStringSync();
      final router = File('lib/app/router.dart').readAsStringSync();

      expect(fallback, contains('/*  /index.html  200'));
      expect(healthCheck, contains('check_route /welcome'));
      expect(healthCheck, contains('check_route /professional/health-check'));
      expect(router, contains("'/professional/:professionalId'"));
      expect(router, contains("'/customer-requests/:requestId'"));
      expect(router, contains("'/professional/requests/:requestId'"));
    });

    test('example environment and ignores cannot track production secrets', () {
      final example = File('.env.example').readAsStringSync();
      final ignore = File('.gitignore').readAsStringSync();
      final audit = File('scripts/audit_repository.sh').readAsStringSync();

      expect(example, contains('SUPABASE_ANON_KEY=your-public-anon-key'));
      expect(example, isNot(contains('SERVICE_ROLE')));
      expect(ignore, contains('.env'));
      expect(ignore, contains('/build/'));
      expect(ignore, contains('/supabase/.temp/'));
      expect(audit, contains('sb_secret_'));
      expect(audit, contains('token JWT incrustado'));
    });
  });
}
