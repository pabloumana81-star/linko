import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String privacyMigration;
  late String publicProfileMigration;

  setUpAll(() async {
    privacyMigration = await File(
      'supabase/migrations/202608090001_harden_professional_verification_privacy.sql',
    ).readAsString();
    publicProfileMigration = await File(
      'supabase/migrations/202608080005_production_professional_profiles.sql',
    ).readAsString();
  });

  test(
    'private verification data is copied and checked before source removal',
    () {
      final copy = privacyMigration.indexOf(
        'select professional.id, professional.verification_documents',
      );
      final verification = privacyMigration.indexOf(
        'submission.documents is distinct from professional.verification_documents',
      );
      final removal = privacyMigration.indexOf(
        'drop column verification_documents',
      );
      expect(copy, greaterThanOrEqualTo(0));
      expect(verification, greaterThan(copy));
      expect(removal, greaterThan(verification));
      expect(privacyMigration, contains('on delete cascade'));
    },
  );

  test('RLS limits reads to owner and Admin and writes to owner', () {
    expect(privacyMigration, contains('enable row level security'));
    expect(privacyMigration, contains('(select auth.uid()) = professional_id'));
    expect(privacyMigration, contains("profile.role = 'admin'"));
    expect(privacyMigration, contains('for insert to authenticated'));
    expect(privacyMigration, contains('for update to authenticated'));
    expect(privacyMigration, isNot(contains('Admins can update')));
    expect(privacyMigration, contains('from public, anon, authenticated'));
  });

  test(
    'public discovery contains status but no private verification fields',
    () {
      expect(publicProfileMigration, contains('verification_status text'));
      expect(publicProfileMigration, isNot(contains('verification_documents')));
      expect(publicProfileMigration, isNot(contains('submission_metadata')));
      expect(
        privacyMigration,
        contains('left join public.professional_verification_submissions'),
      );
    },
  );

  test('owner RPCs have no target professional parameter', () {
    expect(privacyMigration, contains('get_own_professional_verification()'));
    expect(privacyMigration, contains('submit_own_professional_verification('));
    expect(privacyMigration, contains('(select auth.uid())'));
    expect(
      privacyMigration,
      isNot(contains('p_professional_id uuid,\n  p_documents')),
    );
  });
}
