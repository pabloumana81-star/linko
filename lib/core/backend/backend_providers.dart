import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko/core/backend/backend_config.dart';
import 'package:linko/core/backend/backend_initializer.dart';
import 'package:linko/core/backend/backend_repository_factory.dart';
import 'package:linko/core/backend/repositories/authentication_repository.dart';
import 'package:linko/core/backend/repositories/conversations_repository.dart';
import 'package:linko/core/backend/repositories/professionals_repository.dart';
import 'package:linko/core/backend/repositories/profile_repository.dart';
import 'package:linko/core/backend/repositories/quotations_repository.dart';
import 'package:linko/core/backend/repositories/ratings_repository.dart';
import 'package:linko/core/backend/repositories/reports_repository.dart';
import 'package:linko/core/backend/repositories/service_requests_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final backendConfigProvider = Provider<BackendConfig>(
  (ref) => BackendConfig.fromEnvironment(),
);

final backendInitializationProvider = Provider<BackendInitializationResult>(
  (ref) => BackendInitializationResult.ready(ref.watch(backendConfigProvider)),
);

final supabaseClientProvider = Provider<SupabaseClient?>((ref) => null);

final backendRepositoryFactoryProvider = Provider<BackendRepositoryFactory>(
  (ref) => const BackendRepositoryFactory(),
);

final backendRepositoriesProvider = Provider<BackendRepositories>((ref) {
  return ref
      .watch(backendRepositoryFactoryProvider)
      .create(
        config: ref.watch(backendConfigProvider),
        supabaseClient: ref.watch(supabaseClientProvider),
      );
});

final authenticationRepositoryProvider = Provider<AuthenticationRepository>(
  (ref) => ref.watch(backendRepositoriesProvider).authentication,
);

final professionalsRepositoryProvider = Provider<ProfessionalsRepository>(
  (ref) => ref.watch(backendRepositoriesProvider).professionals,
);

final availableProfessionalsProvider = StreamProvider(
  (ref) => ref.watch(professionalsRepositoryProvider).watchProfessionals(),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ref.watch(backendRepositoriesProvider).profile,
);

final serviceRequestsRepositoryProvider = Provider<ServiceRequestsRepository>(
  (ref) => ref.watch(backendRepositoriesProvider).serviceRequests,
);

final conversationsRepositoryProvider = Provider<ConversationsRepository>(
  (ref) => ref.watch(backendRepositoriesProvider).conversations,
);

final quotationsRepositoryProvider = Provider<QuotationsRepository>(
  (ref) => ref.watch(backendRepositoriesProvider).quotations,
);

final ratingsRepositoryProvider = Provider<RatingsRepository>(
  (ref) => ref.watch(backendRepositoriesProvider).ratings,
);

final reportsRepositoryProvider = Provider<ReportsRepository>(
  (ref) => ref.watch(backendRepositoriesProvider).reports,
);
