import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String migration;
  setUpAll(() async {
    migration = await File(
      '../supabase/migrations/202608030008_create_admin_professional_management.sql',
    ).readAsString();
  });

  test('professional actions are admin-only and fully audited', () {
    expect(migration, contains("profile.role = 'admin'"));
    expect(migration, contains('admin_id, professional_id, action'));
    expect(migration, contains('previous_value, new_value'));
    expect(migration, contains('perform_admin_professional_action'));
  });

  test('dashboard count uses only verified active professionals', () {
    expect(migration, contains('count_active_admin_professionals'));
    expect(migration, contains("verification_status = 'verified'"));
    expect(migration, contains("account_status = 'active'"));
    expect(migration.toLowerCase(), isNot(contains('delete from')));
    expect(migration.toLowerCase(), isNot(contains('service_role')));
  });
}
