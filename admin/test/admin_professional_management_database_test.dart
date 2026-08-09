import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String migration;
  late String productionMigration;
  late String privacyMigration;
  setUpAll(() async {
    migration = await File(
      '../supabase/migrations/202608030008_create_admin_professional_management.sql',
    ).readAsString();
    productionMigration = await File(
      '../supabase/migrations/202608040002_harden_admin_professionals.sql',
    ).readAsString();
    privacyMigration = await File(
      '../supabase/migrations/202608090001_harden_professional_verification_privacy.sql',
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

  test('production workflow requires reasons and writes global audit', () {
    expect(productionMigration, contains('additionalInformationRequested'));
    expect(productionMigration, contains("coalesce(trim(p_reason), '') = ''"));
    expect(productionMigration, contains('public.admin_audit_logs'));
    expect(productionMigration, contains("profile.role = 'admin'"));
    expect(productionMigration.toLowerCase(), isNot(contains('service_role')));
  });

  test('production profile exposes operational and verification data', () {
    for (final field in [
      'categories',
      'coverage_area',
      'experience_years',
      'verification_documents',
      'portfolio',
    ]) {
      expect(productionMigration, contains(field));
    }
  });

  test('Admin verification reads the protected submission table', () {
    expect(
      privacyMigration,
      contains('left join public.professional_verification_submissions'),
    );
    expect(privacyMigration, contains("profile.role = 'admin'"));
    expect(privacyMigration, contains('coalesce(submission.documents'));
    expect(privacyMigration, contains('drop column verification_documents'));
    expect(privacyMigration.toLowerCase(), isNot(contains('service_role')));
  });
}
