import 'package:flutter/foundation.dart';
import 'package:linko/core/backend/backend_config.dart';
import 'package:linko/core/backend/data/mock_backend_repositories.dart';
import 'package:linko/core/backend/data/account_status_store.dart';
import 'package:linko/core/backend/data/professional_availability_store.dart';
import 'package:linko/core/backend/data/supabase_backend_repositories.dart';
import 'package:linko/core/backend/repositories/authentication_repository.dart';
import 'package:linko/core/backend/repositories/conversations_repository.dart';
import 'package:linko/core/backend/repositories/professionals_repository.dart';
import 'package:linko/core/backend/repositories/profile_repository.dart';
import 'package:linko/core/backend/repositories/quotations_repository.dart';
import 'package:linko/core/backend/repositories/ratings_repository.dart';
import 'package:linko/core/backend/repositories/reports_repository.dart';
import 'package:linko/core/backend/repositories/service_requests_repository.dart';
import 'package:linko/features/requests/data/mock_request_repository.dart';
import 'package:linko/features/requests/domain/repositories/request_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BackendRepositories {
  const BackendRepositories({
    required this.mode,
    required this.authentication,
    required this.professionals,
    required this.profile,
    required this.serviceRequests,
    required this.conversations,
    required this.quotations,
    required this.ratings,
    required this.reports,
    required this.mvpCompatibilityRequests,
    this.professionalAvailability,
    this.accountStatuses,
  });

  final BackendMode mode;
  final AuthenticationRepository authentication;
  final ProfessionalsRepository professionals;
  final ProfileRepository profile;
  final ServiceRequestsRepository serviceRequests;
  final ConversationsRepository conversations;
  final QuotationsRepository quotations;
  final RatingsRepository ratings;
  final ReportsRepository reports;

  /// Temporary synchronous bridge for screens not migrated during Phase 1.
  final RequestRepository mvpCompatibilityRequests;
  final ProfessionalAvailabilityStore? professionalAvailability;
  final AccountStatusStore? accountStatuses;
}

class BackendRepositoryFactory {
  const BackendRepositoryFactory();

  BackendRepositories create({
    required BackendConfig config,
    SupabaseClient? supabaseClient,
  }) {
    config.validate();
    final compatibility = MockRequestRepository();
    if (config.mode == BackendMode.mock) {
      final availability = ProfessionalAvailabilityStore();
      final accountStatuses = AccountStatusStore();
      return BackendRepositories(
        mode: BackendMode.mock,
        authentication: MockAuthenticationRepository(),
        professionals: MockProfessionalsRepository(compatibility, availability),
        profile: MockProfileRepository(accountStatuses),
        serviceRequests: MockServiceRequestsRepository(compatibility),
        conversations: MockConversationsRepository(compatibility),
        quotations: MockQuotationsRepository(compatibility),
        ratings: MockRatingsRepository(compatibility),
        reports: MockReportsRepository(compatibility),
        mvpCompatibilityRequests: compatibility,
        professionalAvailability: availability,
        accountStatuses: accountStatuses,
      );
    }
    if (supabaseClient == null) {
      throw StateError(
        'Supabase debe estar inicializado antes de crear sus repositorios.',
      );
    }
    return BackendRepositories(
      mode: BackendMode.supabase,
      authentication: SupabaseAuthenticationRepository(
        supabaseClient,
        redirectTo: kIsWeb ? Uri.base.origin : config.authRedirectUrl,
      ),
      professionals: SupabaseProfessionalsRepository(supabaseClient),
      profile: ProfileRepositorySupabase(supabaseClient),
      serviceRequests: ServiceRequestsRepositorySupabase(supabaseClient),
      conversations: ConversationsRepositorySupabase(supabaseClient),
      quotations: QuotationsRepositorySupabase(supabaseClient),
      ratings: SupabaseRatingsRepository(supabaseClient),
      reports: SupabaseReportsRepository(supabaseClient),
      mvpCompatibilityRequests: compatibility,
    );
  }
}
