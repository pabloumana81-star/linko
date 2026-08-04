import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:linko/core/backend/data/mock_backend_repositories.dart';
import 'package:linko/core/backend/data/professional_availability_store.dart';
import 'package:linko/features/requests/data/mock_request_repository.dart';
import 'package:linko_admin/features/admin/data/mock_admin_professionals_repository.dart';
import 'package:linko_admin/features/admin/data/mock_admin_state.dart';

void main() {
  test(
    'admin suspension refreshes main discovery and blocks the professional',
    () async {
      final requests = MockRequestRepository();
      final availability = ProfessionalAvailabilityStore();
      final mainRepository = MockProfessionalsRepository(
        requests,
        availability,
      );
      final adminRepository = MockAdminProfessionalsRepository(
        requests,
        MockAdminState(availability: availability),
      );
      final updates = StreamIterator(mainRepository.watchProfessionals());

      expect(await updates.moveNext(), isTrue);
      const professionalId = 'professional-carlos';
      expect(
        updates.current.any((item) => item.user.id == professionalId),
        isTrue,
      );

      final nextUpdate = updates.moveNext();
      await Future<void>.delayed(Duration.zero);
      await adminRepository.suspendProfessional(professionalId);

      expect(await nextUpdate, isTrue);
      expect(
        updates.current.any((item) => item.user.id == professionalId),
        isFalse,
      );
      expect(await mainRepository.getProfessionalById(professionalId), isNull);
      await updates.cancel();
    },
  );

  test('Supabase availability uses shared tables and realtime publication', () {
    final migration = File(
      '../supabase/migrations/202608030009_sync_professional_availability.sql',
    ).readAsStringSync();

    expect(migration, contains('public.professional_profiles'));
    expect(migration, contains('public.profiles'));
    expect(migration, contains("verification_status = 'verified'"));
    expect(migration, contains("account_status = 'active'"));
    expect(migration, contains('supabase_realtime'));
    expect(migration.toLowerCase(), isNot(contains('service_role')));
  });
}
