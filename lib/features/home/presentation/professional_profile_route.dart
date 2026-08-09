import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko/core/backend/backend_config.dart';
import 'package:linko/core/backend/backend_providers.dart';
import 'package:linko/features/home/presentation/models/professional_profile_data.dart';
import 'package:linko/features/home/presentation/professional_profile_screen.dart';
import 'package:linko/features/home/presentation/providers/professional_discovery_provider.dart';
import 'package:linko/features/requests/presentation/providers/request_providers.dart';

class ProfessionalProfileRoute extends ConsumerWidget {
  const ProfessionalProfileRoute({
    required this.professionalId,
    required this.onRequestService,
    this.initialProfessional,
    super.key,
  });

  final String professionalId;
  final ProfessionalProfileData? initialProfessional;
  final ValueChanged<ProfessionalProfileData> onRequestService;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMock =
        ref.watch(backendRepositoriesProvider).mode == BackendMode.mock;
    final cached = isMock && initialProfessional?.id == professionalId
        ? initialProfessional
        : null;
    final profile = cached == null
        ? ref.watch(professionalProfileByIdProvider(professionalId))
        : AsyncData<ProfessionalProfileData?>(cached);

    return profile.when(
      loading: () => const _ProfessionalProfileState(
        key: ValueKey('professional-profile-loading'),
        child: CircularProgressIndicator(),
      ),
      error: (_, _) => const _ProfessionalProfileState(
        key: ValueKey('professional-profile-error'),
        child: Text(
          'No pudimos cargar el perfil profesional. Intenta nuevamente.',
          textAlign: TextAlign.center,
        ),
      ),
      data: (professional) {
        if (professional == null) {
          return const _ProfessionalProfileState(
            key: ValueKey('professional-profile-not-found'),
            child: Text(
              'No encontramos este perfil profesional.',
              textAlign: TextAlign.center,
            ),
          );
        }

        if (!isMock) {
          return ProfessionalProfileScreen(
            professional: professional,
            completedJobsCount: professional.completedJobsCount,
            showMockDetails: false,
            onRequestService: () => onRequestService(professional),
          );
        }

        final summary = ref.watch(
          professionalRatingSummaryProvider(professional.id),
        );
        final currentProfessional = professional.copyWith(
          rating: summary.averageRating == 0
              ? professional.rating
              : summary.averageRating,
          reviewCount: summary.reviewCount == 0
              ? professional.reviewCount
              : summary.reviewCount,
        );
        return ProfessionalProfileScreen(
          professional: currentProfessional,
          completedJobsCount: summary.completedJobsCount,
          showMockDetails: true,
          onRequestService: () => onRequestService(currentProfessional),
        );
      },
    );
  }
}

class _ProfessionalProfileState extends StatelessWidget {
  const _ProfessionalProfileState({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      automaticallyImplyLeading: true,
      title: const Text('Perfil profesional'),
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(padding: const EdgeInsets.all(32), child: child),
      ),
    ),
  );
}
