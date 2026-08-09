import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko/core/backend/backend_config.dart';
import 'package:linko/core/backend/backend_providers.dart';
import 'package:linko/features/home/presentation/data/placeholder_professionals.dart';
import 'package:linko/features/home/presentation/models/professional_profile_data.dart';
import 'package:linko/features/requests/domain/models/professional_profile.dart';

final professionalDiscoveryProvider =
    Provider<AsyncValue<List<ProfessionalProfileData>>>((ref) {
      if (ref.watch(backendRepositoriesProvider).mode == BackendMode.mock) {
        return const AsyncData(placeholderProfessionals);
      }
      return ref
          .watch(availableProfessionalsProvider)
          .whenData(
            (profiles) => profiles
                .map(professionalProfileDataFromDomain)
                .toList(growable: false),
          );
    });

final professionalProfileByIdProvider =
    FutureProvider.family<ProfessionalProfileData?, String>((ref, id) async {
      final profile = await ref
          .watch(professionalsRepositoryProvider)
          .getProfessionalById(id);
      return profile == null
          ? null
          : professionalProfileDataFromDomain(profile);
    });

ProfessionalProfileData professionalProfileDataFromDomain(
  ProfessionalProfile profile,
) => ProfessionalProfileData(
  id: profile.user.id,
  name: profile.user.name,
  profession: profile.profession,
  rating: profile.rating,
  reviewCount: profile.reviewCount,
  location: profile.location,
  avatarUrl: profile.avatarUrl,
  biography: profile.biography,
  services: profile.services,
  experienceYears: profile.experienceYears,
  experienceDescription: profile.experienceDescription,
  portfolio: profile.portfolio,
  completedJobsCount: profile.completedJobsCount,
  reviews: profile.reviews
      .map(
        (review) => ProfessionalReviewData(
          stars: review.stars,
          comment: review.comment,
          createdAt: review.createdAt,
        ),
      )
      .toList(growable: false),
  coverageArea: profile.coverageArea,
  isVerified: profile.isVerified,
);
