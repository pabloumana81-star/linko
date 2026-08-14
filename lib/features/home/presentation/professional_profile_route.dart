import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko/core/backend/backend_config.dart';
import 'package:linko/core/backend/backend_providers.dart';
import 'package:linko/features/home/presentation/models/professional_profile_data.dart';
import 'package:linko/features/home/presentation/professional_profile_screen.dart';
import 'package:linko/features/home/presentation/providers/professional_discovery_provider.dart';
import 'package:linko/features/home/presentation/widgets/labeled_loading_indicator.dart';
import 'package:linko/features/requests/presentation/providers/request_providers.dart';

class ProfessionalProfileRoute extends ConsumerStatefulWidget {
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
  ConsumerState<ProfessionalProfileRoute> createState() =>
      _ProfessionalProfileRouteState();
}

class _ProfessionalProfileRouteState
    extends ConsumerState<ProfessionalProfileRoute> {
  ProfessionalProfileData? _retained;

  @override
  void initState() {
    super.initState();
    if (widget.initialProfessional?.id == widget.professionalId) {
      _retained = widget.initialProfessional;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMock =
        ref.watch(backendRepositoriesProvider).mode == BackendMode.mock;
    final profile = isMock && _retained != null
        ? AsyncData<ProfessionalProfileData?>(_retained)
        : ref.watch(professionalProfileByIdProvider(widget.professionalId));
    final refreshed = profile.value;
    if (refreshed != null) _retained = refreshed;
    final professional = refreshed ?? _retained;

    if (profile.hasError) {
      return _ProfessionalProfileState(
        key: const ValueKey('professional-profile-error'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'No pudimos cargar el perfil profesional. Intenta nuevamente.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => ref.invalidate(
                professionalProfileByIdProvider(widget.professionalId),
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    if (professional == null && profile.isLoading) {
      return const _ProfessionalProfileState(
        key: ValueKey('professional-profile-loading'),
        child: LabeledLoadingIndicator(label: 'Cargando perfil profesional…'),
      );
    }
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
        onRequestService: () => widget.onRequestService(professional),
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
      onRequestService: () => widget.onRequestService(currentProfessional),
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
