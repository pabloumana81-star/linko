import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mobile and desktop runners register the authentication callback', () {
    final android = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final ios = File('ios/Runner/Info.plist').readAsStringSync();
    final macos = File('macos/Runner/Info.plist').readAsStringSync();

    expect(android, contains('android:scheme="io.supabase.linko"'));
    expect(android, contains('android:host="login-callback"'));
    expect(ios, contains('<string>io.supabase.linko</string>'));
    expect(macos, contains('<string>io.supabase.linko</string>'));
  });

  test(
    'new Supabase profiles require onboarding without changing old rows',
    () {
      final migration = File(
        'supabase/migrations/202608080004_auth_onboarding_default.sql',
      ).readAsStringSync();

      expect(
        migration,
        contains('alter column onboarding_completed set default false'),
      );
      expect(
        migration.toLowerCase(),
        isNot(contains('update public.profiles')),
      );
    },
  );
}
