import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String migration;

  setUpAll(() async {
    migration = await File(
      '../supabase/migrations/202608030007_create_admin_user_management.sql',
    ).readAsString();
  });

  test('all user mutations require admin and write an audit entry', () {
    expect(migration, contains("profile.role = 'admin'"));
    expect(migration, contains('perform_admin_user_action'));
    expect(migration, contains('insert into public.admin_audit_log'));
    expect(migration, contains('accountSuspended'));
    expect(migration, contains('accountReactivated'));
    expect(migration, contains('onboardingReset'));
  });

  test('user management exposes no delete operation', () {
    expect(
      migration.toLowerCase(),
      isNot(contains('delete from public.profiles')),
    );
    expect(migration, contains('No puedes suspender tu propia cuenta.'));
  });
}
