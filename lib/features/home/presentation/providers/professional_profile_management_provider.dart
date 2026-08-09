import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko/core/backend/backend_providers.dart';
import 'package:linko/core/backend/repositories/professionals_repository.dart';
import 'package:linko/features/requests/domain/models/professional_profile.dart';

final ownProfessionalProfileProvider = FutureProvider<ProfessionalProfile?>(
  (ref) =>
      ref.watch(professionalsRepositoryProvider).getOwnProfessionalProfile(),
);

final ownVerificationDocumentsProvider =
    FutureProvider<List<ProfessionalVerificationDocument>>(
      (ref) => ref
          .watch(professionalsRepositoryProvider)
          .getOwnVerificationDocuments(),
    );

final professionalProfileManagementProvider =
    Provider<ProfessionalProfileManagementController>(
      ProfessionalProfileManagementController.new,
    );

class ProfessionalProfileManagementController {
  ProfessionalProfileManagementController(this._ref);

  final Ref _ref;

  Future<void> save(ProfessionalProfileUpdate update) async {
    await _ref
        .read(professionalsRepositoryProvider)
        .updateOwnProfessionalProfile(update);
    _ref.invalidate(ownProfessionalProfileProvider);
    _ref.invalidate(availableProfessionalsProvider);
  }

  Future<void> uploadPortfolio(ProfessionalUploadFile file) async {
    await _ref
        .read(professionalsRepositoryProvider)
        .uploadOwnPortfolioImage(file);
    _refreshProfile();
  }

  Future<void> deletePortfolio(String imageUrl) async {
    await _ref
        .read(professionalsRepositoryProvider)
        .deleteOwnPortfolioImage(imageUrl);
    _refreshProfile();
  }

  Future<void> uploadVerification(ProfessionalUploadFile file) async {
    await _ref
        .read(professionalsRepositoryProvider)
        .uploadOwnVerificationDocument(file);
    _ref.invalidate(ownVerificationDocumentsProvider);
  }

  Future<void> deleteVerification(String objectPath) async {
    await _ref
        .read(professionalsRepositoryProvider)
        .deleteOwnVerificationDocument(objectPath);
    _ref.invalidate(ownVerificationDocumentsProvider);
  }

  void _refreshProfile() {
    _ref.invalidate(ownProfessionalProfileProvider);
    _ref.invalidate(availableProfessionalsProvider);
  }
}
