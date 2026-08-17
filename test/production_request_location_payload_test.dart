import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linko/app/app.dart';
import 'package:linko/app/app_mode.dart';
import 'package:linko/app/router.dart';
import 'package:linko/core/backend/backend_config.dart';
import 'package:linko/core/backend/backend_providers.dart';
import 'package:linko/core/backend/backend_repository_factory.dart';
import 'package:linko/core/backend/data/mock_backend_repositories.dart';
import 'package:linko/core/backend/repositories/professionals_repository.dart';
import 'package:linko/core/backend/repositories/service_requests_repository.dart';
import 'package:linko/features/auth/domain/models/app_user_profile.dart';
import 'package:linko/features/home/presentation/models/professional_profile_data.dart';
import 'package:linko/features/requests/data/service_request_supabase_mapper.dart';
import 'package:linko/features/requests/domain/models/app_user.dart';
import 'package:linko/features/requests/domain/models/professional_profile.dart';
import 'package:linko/features/requests/domain/models/service_request.dart';

void main() {
  testWidgets(
    'production UI flow sends the form location in the Supabase payload',
    (tester) async {
      const customerId = '018f47a6-7200-4d31-8f6c-1bc183202222';
      const professionalId = '018f47a6-7200-4d31-8f6c-1bc183202333';
      const enteredLocation = 'San José, Escazú · pixel-payload-regression';
      const professional = ProfessionalProfile(
        id: professionalId,
        user: AppUser(id: professionalId, name: 'Profesional QA'),
        profession: 'Electricista',
        rating: 5,
        reviewCount: 1,
        location: 'Cartago',
      );
      const profileData = ProfessionalProfileData(
        id: professionalId,
        name: 'Profesional QA',
        profession: 'Electricista',
        rating: 5,
        reviewCount: 1,
        location: 'Cartago',
      );
      final auth = MockAuthenticationRepository(
        initialUser: AppUserProfile(
          id: customerId,
          displayName: 'Cliente QA',
          email: 'cliente@linko.test',
          avatarUrl: null,
          activeMode: AppMode.customer,
          onboardingCompleted: true,
          createdAt: DateTime.utc(2026),
        ),
      );
      final capture = _CapturingServiceRequestsRepository();
      final mock = const BackendRepositoryFactory().create(
        config: const BackendConfig(mode: BackendMode.mock),
      );
      final repositories = BackendRepositories(
        mode: BackendMode.supabase,
        authentication: auth,
        professionals: _SingleProfessionalRepository(professional),
        profile: mock.profile,
        serviceRequests: capture,
        conversations: mock.conversations,
        quotations: mock.quotations,
        ratings: mock.ratings,
        reports: mock.reports,
        mvpCompatibilityRequests: mock.mvpCompatibilityRequests,
      );

      appRouter.goNamed(
        AppRouteNames.professionalProfile,
        pathParameters: const {'professionalId': professionalId},
        queryParameters: const {'service': 'Instalación eléctrica'},
        extra: profileData,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            backendRepositoriesProvider.overrideWithValue(repositories),
          ],
          child: const LinkoApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Solicitar servicio'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('request-description')),
        'Revisar el tablero eléctrico.',
      );
      await tester.enterText(
        find.byKey(const ValueKey('request-location')),
        enteredLocation,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('request-timing-flexible')),
      );
      await tester.tap(find.byKey(const ValueKey('request-timing-flexible')));
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(find.text('Confirmar solicitud'), findsOneWidget);
      expect(find.text(enteredLocation), findsOneWidget);
      await tester.tap(find.text('Enviar solicitud'));
      await tester.pumpAndSettle();

      expect(capture.request?.location, enteredLocation);
      expect(capture.payload?['location'], enteredLocation);
    },
  );
}

class _CapturingServiceRequestsRepository implements ServiceRequestsRepository {
  ServiceRequest? request;
  Map<String, Object?>? payload;

  @override
  Future<void> createRequest(ServiceRequest value) async {
    request = value;
    payload = const ServiceRequestSupabaseMapper().toInsert(value);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SingleProfessionalRepository implements ProfessionalsRepository {
  _SingleProfessionalRepository(this.professional);

  final ProfessionalProfile professional;

  @override
  Future<ProfessionalProfile?> getProfessionalById(
    String professionalId,
  ) async {
    return professionalId == professional.id ? professional : null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
