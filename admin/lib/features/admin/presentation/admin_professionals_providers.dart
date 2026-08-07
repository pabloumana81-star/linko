import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko_admin/features/admin/domain/admin_professional.dart';
import 'package:linko_admin/features/admin/domain/admin_professionals_repository.dart';
import 'package:linko_admin/features/admin/domain/admin_user.dart';
import 'package:linko_admin/features/admin/presentation/admin_dashboard_providers.dart';
import 'package:linko_admin/features/admin/presentation/admin_repositories_provider.dart';

final adminProfessionalsRepositoryProvider =
    Provider<AdminProfessionalsRepository>((ref) {
      return ref.watch(adminRepositoriesProvider).professionals;
    });

final adminProfessionalQueryProvider =
    NotifierProvider<AdminProfessionalQueryController, AdminProfessionalQuery>(
      AdminProfessionalQueryController.new,
    );

class AdminProfessionalQueryController
    extends Notifier<AdminProfessionalQuery> {
  @override
  AdminProfessionalQuery build() => const AdminProfessionalQuery();

  void search(String value) {
    state = AdminProfessionalQuery(
      search: value,
      verification: state.verification,
      accountStatus: state.accountStatus,
      rating: state.rating,
    );
  }

  void verification(ProfessionalVerificationStatus? value) {
    state = AdminProfessionalQuery(
      search: state.search,
      verification: value,
      accountStatus: state.accountStatus,
      rating: state.rating,
    );
  }

  void accountStatus(AdminAccountStatus? value) {
    state = AdminProfessionalQuery(
      search: state.search,
      verification: state.verification,
      accountStatus: value,
      rating: state.rating,
    );
  }

  void rating(ProfessionalRatingFilter? value) {
    state = AdminProfessionalQuery(
      search: state.search,
      verification: state.verification,
      accountStatus: state.accountStatus,
      rating: value,
    );
  }
}

final adminProfessionalsProvider = FutureProvider<List<AdminProfessional>>((
  ref,
) {
  return ref
      .watch(adminProfessionalsRepositoryProvider)
      .listProfessionals(ref.watch(adminProfessionalQueryProvider));
});

final adminProfessionalDetailProvider =
    FutureProvider.family<AdminProfessionalDetail?, String>((ref, id) {
      return ref
          .watch(adminProfessionalsRepositoryProvider)
          .getProfessional(id);
    });

class AdminProfessionalActions {
  const AdminProfessionalActions(this.ref);
  final Ref ref;

  Future<void> approve(String id) => _run(
    id,
    () =>
        ref.read(adminProfessionalsRepositoryProvider).approveVerification(id),
  );
  Future<void> reject(String id, String reason) => _run(
    id,
    () => ref
        .read(adminProfessionalsRepositoryProvider)
        .rejectVerification(id, reason),
  );
  Future<void> requestInformation(String id, String reason) => _run(
    id,
    () => ref
        .read(adminProfessionalsRepositoryProvider)
        .requestAdditionalInformation(id, reason),
  );
  Future<void> suspend(String id) => _run(
    id,
    () =>
        ref.read(adminProfessionalsRepositoryProvider).suspendProfessional(id),
  );
  Future<void> reactivate(String id) => _run(
    id,
    () => ref
        .read(adminProfessionalsRepositoryProvider)
        .reactivateProfessional(id),
  );

  Future<void> _run(String id, Future<void> Function() action) async {
    await action();
    ref
      ..invalidate(adminProfessionalsProvider)
      ..invalidate(adminProfessionalDetailProvider(id))
      ..invalidate(adminDashboardProvider);
  }
}

final adminProfessionalActionsProvider = Provider<AdminProfessionalActions>(
  AdminProfessionalActions.new,
);
