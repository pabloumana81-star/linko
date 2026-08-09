import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linko/core/backend/backend_config.dart';
import 'package:linko/core/backend/backend_providers.dart';
import 'package:linko/core/backend/data/mock_backend_repositories.dart';
import 'package:linko/core/backend/data/professional_availability_store.dart';
import 'package:linko/app/app_mode.dart';
import 'package:linko/features/auth/domain/models/app_user_profile.dart';
import 'package:linko_admin/app/admin_app.dart';
import 'package:linko_admin/app/admin_router.dart';
import 'package:linko_admin/features/admin/data/mock_admin_dashboard_repository.dart';
import 'package:linko_admin/features/admin/data/mock_admin_professionals_repository.dart';
import 'package:linko_admin/features/admin/data/mock_admin_state.dart';
import 'package:linko/features/admin/data/supabase_admin_professionals_repository.dart';
import 'package:linko/features/admin/domain/admin_dashboard.dart';
import 'package:linko/features/admin/domain/admin_professional.dart';
import 'package:linko/features/admin/domain/admin_user.dart';
import 'package:linko_admin/features/admin/presentation/admin_professionals_providers.dart';
import 'package:linko_admin/features/admin/presentation/admin_professionals_screen.dart';
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
      await repository.rejectVerification(
        'professional-maria',
        'Documento inválido',
      );
      await repository.suspendProfessional('professional-maria');

      expect(
        (await repository.listProfessionals(
          const AdminProfessionalQuery(
            verification: ProfessionalVerificationStatus.rejected,
          ),
        )).map((item) => item.id),
        ['professional-maria'],
      );
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
            authRedirectUrl: 'io.supabase.linko://login-callback/',
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

  test('Supabase mapping includes every production list field', () {
    final item = AdminProfessionalSupabaseMapper.professional({
      'id': 'professional-1',
      'name': 'Lucía Vargas',
      'email': 'lucia@linko.test',
      'photo_url': 'https://example.test/lucia.jpg',
      'categories': ['Electricidad', 'Iluminación'],
      'verification': 'verified',
      'average_rating': 4.9,
      'completed_jobs': 18,
      'active_jobs': 2,
      'registered_at': '2026-07-10T12:00:00Z',
      'account_status': 'active',
    });

    expect(item.name, 'Lucía Vargas');
    expect(item.categories, ['Electricidad', 'Iluminación']);
    expect(item.verification, ProfessionalVerificationStatus.verified);
    expect(item.averageRating, 4.9);
    expect(item.completedJobs, 18);
    expect(item.activeJobs, 2);
    expect(item.registeredAt.toUtc(), DateTime.utc(2026, 7, 10, 12));
  });

  test(
    'rejection requires a reason and request for information is audited',
    () async {
      const id = 'professional-carlos';
      await expectLater(
        repository.rejectVerification(id, '  '),
        throwsArgumentError,
      );
      await repository.rejectVerification(id, 'Documento vencido');
      await repository.requestAdditionalInformation(
        id,
        'Adjunta una identificación vigente',
      );

      final detail = await repository.getProfessional(id);
      expect(
        detail?.professional.verification,
        ProfessionalVerificationStatus.pending,
      );
      expect(detail?.timeline.map((entry) => entry.action), [
        ProfessionalAuditAction.additionalInformationRequested,
        ProfessionalAuditAction.verificationRejected,
      ]);
      expect(
        detail?.timeline.first.newValue,
        contains('Adjunta una identificación vigente'),
      );
    },
  );

  test(
    'verification and suspension synchronize discovery and badge state',
    () async {
      final availability = ProfessionalAvailabilityStore();
      final mainRepository = MockProfessionalsRepository(
        requests,
        availability,
      );
      final adminRepository = MockAdminProfessionalsRepository(
        requests,
        MockAdminState(availability: availability),
      );
      const id = 'professional-carlos';

      await adminRepository.approveVerification(id);
      var visible = await mainRepository.getProfessionalById(id);
      expect(visible, isNotNull);
      expect(visible?.isVerified, isTrue);

      await adminRepository.rejectVerification(id, 'Datos inconsistentes');
      expect(await mainRepository.getProfessionalById(id), isNull);

      await adminRepository.approveVerification(id);
      await adminRepository.suspendProfessional(id);
      expect(await mainRepository.getProfessionalById(id), isNull);

      await adminRepository.reactivateProfessional(id);
      visible = await mainRepository.getProfessionalById(id);
      expect(visible, isNotNull);
      expect(visible?.isVerified, isTrue);
      expect(requests.getProfessionalRequests(id), isNotEmpty);
    },
  );

  testWidgets('professionals screen renders loading, empty and error states', (
    tester,
  ) async {
    Future<void> pump(Future<List<AdminProfessional>> future) =>
        tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              adminProfessionalsProvider.overrideWith((ref) => future),
            ],
            child: const MaterialApp(
              home: Scaffold(body: AdminProfessionalsScreen()),
            ),
          ),
        );
    Future<List<AdminProfessional>> fail() async {
      await Future<void>.delayed(Duration.zero);
      throw StateError('fallo controlado');
    }

    await pump(Completer<List<AdminProfessional>>().future);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await pump(Future.value(const []));
    await tester.pumpAndSettle();
    expect(find.text('No se encontraron profesionales.'), findsOneWidget);
    await pump(fail());
    await tester.pumpAndSettle();
    expect(find.text('No pudimos cargar los profesionales.'), findsOneWidget);
  });

  testWidgets('destructive workflows require confirmation or a reason', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    adminRouter.go('/professionals/professional-carlos');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authenticationRepositoryProvider.overrideWithValue(
            MockAuthenticationRepository(initialUser: _admin),
          ),
          adminProfessionalsRepositoryProvider.overrideWithValue(repository),
        ],
        child: const LinkoAdminApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('reject-professional')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('confirm-professional-reason-action')),
    );
    await tester.pump();
    expect(find.text('Debes indicar un motivo.'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('professional-action-reason')),
      'Documento ilegible',
    );
    await tester.tap(
      find.byKey(const ValueKey('confirm-professional-reason-action')),
    );
    await tester.pumpAndSettle();
    expect(find.text('La verificación fue rechazada.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('suspend-professional')));
    await tester.pumpAndSettle();
    expect(
      (await repository.getProfessional(
        'professional-carlos',
      ))?.professional.accountStatus,
      AdminAccountStatus.active,
    );
    await tester.tap(
      find.byKey(const ValueKey('confirm-professional-destructive-action')),
    );
    await tester.pumpAndSettle();
    expect(
      (await repository.getProfessional(
        'professional-carlos',
      ))?.professional.accountStatus,
      AdminAccountStatus.suspended,
    );
  });
}

final _admin = AppUserProfile(
  id: 'admin-user',
  displayName: 'Administración LinkO',
  email: 'admin@linko.test',
  avatarUrl: null,
  activeMode: AppMode.customer,
  role: UserRole.admin,
  createdAt: DateTime.utc(2026),
);
