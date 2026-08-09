import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko/core/backend/backend_providers.dart';
import 'package:linko/features/requests/domain/models/professional_profile.dart';

final ownProfessionalProfileProvider = FutureProvider<ProfessionalProfile?>(
  (ref) =>
      ref.watch(professionalsRepositoryProvider).getOwnProfessionalProfile(),
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
}
