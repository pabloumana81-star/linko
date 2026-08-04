import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linko/core/backend/backend_config.dart';
import 'package:linko/core/backend/backend_providers.dart';
import 'package:linko_admin/features/admin/data/mock_admin_dashboard_repository.dart';
import 'package:linko_admin/features/admin/data/mock_admin_professionals_repository.dart';
import 'package:linko_admin/features/admin/data/mock_admin_state.dart';
import 'package:linko_admin/features/admin/data/supabase_admin_professionals_repository.dart';
import 'package:linko_admin/features/admin/domain/admin_dashboard.dart';
import 'package:linko_admin/features/admin/domain/admin_professional.dart';
import 'package:linko_admin/features/admin/domain/admin_user.dart';
import 'package:linko_admin/features/admin/presentation/admin_professionals_providers.dart';
import 'package:linko/features/requests/data/mock_request_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late MockRequestRepository requests;
  late MockAdminState state;
  late MockAdminProfessionalsRepository repository;

  setUp(() {
    requests = MockRequestRepository();
    state = MockAdminState();
    repository = MockAdminProfessionalsRepository(
      requests,
      state,
      clock: () => DateTime.utc(2026, 8, 3, 12),
    );
  });

  test('search matches name, email and professional ID', () async {
    for (final search in [
      'Carlos Rodríguez',
      'professional-carlos@mock.linko',
      'professional-carlos',
    ]) {
      final result = await repository.listProfessionals(
        AdminProfessionalQuery(search: search),
      );
      expect(result.map((item) => item.id), ['professional-carlos']);
    }
  });

  test(
    'verification, account and rating filters return matching records',
    () async {
      await repository.approveVerification('professional-carlos');
      await repository.suspendProfessional('professional-maria');

      expect(
        (await repository.listProfessionals(
          const AdminProfessionalQuery(
            verification: ProfessionalVerificationStatus.verified,
          ),
        )).every(
          (item) =>
              item.verification == ProfessionalVerificationStatus.verified,
        ),
        isTrue,
      );
      expect(
        (await repository.listProfessionals(
          const AdminProfessionalQuery(
            accountStatus: AdminAccountStatus.suspended,
          ),
        )).map((item) => item.id),
        ['professional-maria'],
      );
      expect(
        await repository.listProfessionals(
          const AdminProfessionalQuery(
            rating: ProfessionalRatingFilter.topRated,
          ),
        ),
        isNotEmpty,
      );
      expect(
        await repository.listProfessionals(
          const AdminProfessionalQuery(
            rating: ProfessionalRatingFilter.lowRated,
          ),
        ),
        isNotEmpty,
      );
    },
  );

  test(
    'verification, suspension and reactivation write complete audit records',
    () async {
      const id = 'professional-carlos';
      await repository.approveVerification(id);
      await repository.suspendProfessional(id);
      await repository.reactivateProfessional(id);

      final detail = await repository.getProfessional(id);
      expect(
        detail?.professional.verification,
        ProfessionalVerificationStatus.verified,
      );
      expect(detail?.professional.accountStatus, AdminAccountStatus.active);
      expect(detail?.timeline.map((entry) => entry.action), [
        ProfessionalAuditAction.accountReactivated,
        ProfessionalAuditAction.accountSuspended,
        ProfessionalAuditAction.verificationApproved,
      ]);
      for (final entry in detail!.timeline) {
        expect(entry.adminId, 'admin-user');
        expect(entry.professionalId, id);
        expect(entry.previousValue, isNotEmpty);
        expect(entry.newValue, isNotEmpty);
        expect(entry.timestamp, DateTime.utc(2026, 8, 3, 12));
      }
    },
  );

  test(
    'dashboard count follows verification and account status changes',
    () async {
      final dashboard = MockAdminDashboardRepository(
        requests,
        state,
        clock: () => DateTime.utc(2026, 8, 3),
      );
      Future<int> count() async => (await dashboard.loadDashboard(
        AdminDashboardRange.last30Days,
      )).metrics.totalProfessionals;

      expect(await count(), 0);
      await repository.approveVerification('professional-carlos');
      expect(await count(), 1);
      await repository.suspendProfessional('professional-carlos');
      expect(await count(), 0);
      await repository.reactivateProfessional('professional-carlos');
      expect(await count(), 1);
    },
  );

  test('repository selection preserves mock and Supabase modes', () {
    final mockContainer = ProviderContainer();
    addTearDown(mockContainer.dispose);
    expect(
      mockContainer.read(adminProfessionalsRepositoryProvider),
      isA<MockAdminProfessionalsRepository>(),
    );

    final client = SupabaseClient('https://example.supabase.co', 'anon-key');
    final supabaseContainer = ProviderContainer(
      overrides: [
        backendConfigProvider.overrideWithValue(
          const BackendConfig(
            mode: BackendMode.supabase,
            supabaseUrl: 'https://example.supabase.co',
            supabaseAnonKey: 'anon-key',
          ),
        ),
        supabaseClientProvider.overrideWithValue(client),
      ],
    );
    addTearDown(supabaseContainer.dispose);
    addTearDown(client.dispose);
    expect(
      supabaseContainer.read(adminProfessionalsRepositoryProvider),
      isA<SupabaseAdminProfessionalsRepository>(),
    );
  });
}
