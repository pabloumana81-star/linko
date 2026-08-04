import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko/core/backend/backend_config.dart';
import 'package:linko/core/backend/backend_providers.dart';
import 'package:linko/features/home/presentation/data/placeholder_professionals.dart';
import 'package:linko/features/home/presentation/models/professional_profile_data.dart';

final professionalDiscoveryProvider =
    Provider<AsyncValue<List<ProfessionalProfileData>>>((ref) {
      if (ref.watch(backendRepositoriesProvider).mode == BackendMode.mock) {
        return const AsyncData(placeholderProfessionals);
      }
      return ref
          .watch(availableProfessionalsProvider)
          .whenData(
            (profiles) => profiles
                .map(
                  (profile) => ProfessionalProfileData(
                    id: profile.id,
                    name: profile.user.name,
                    profession: profile.profession,
                    rating: profile.rating,
                    reviewCount: profile.reviewCount,
                    location: profile.location,
                  ),
                )
                .toList(growable: false),
          );
    });
