import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko/core/backend/backend_config.dart';
import 'package:linko/core/backend/backend_providers.dart';
import 'package:linko/features/home/presentation/models/professional_profile_data.dart';
import 'package:linko/features/home/presentation/providers/professional_discovery_provider.dart';
import 'package:linko/features/home/presentation/widgets/filter_chip_widget.dart';
import 'package:linko/features/home/presentation/widgets/professional_card_compact.dart';
import 'package:linko/features/home/presentation/widgets/search_bar_widget.dart';

class ProfessionalsResultsScreen extends ConsumerWidget {
  const ProfessionalsResultsScreen({
    required this.selectedService,
    required this.onProfessionalSelected,
    super.key,
  });

  final String selectedService;
  final ValueChanged<ProfessionalProfileData> onProfessionalSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final professionals = ref.watch(professionalDiscoveryProvider);
    final isMock =
        ref.watch(backendRepositoriesProvider).mode == BackendMode.mock;
    final filters = [
      selectedService,
      'Cerca de mí',
      'Mejor calificados',
      'Verificados',
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text('Resultados'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth >= 720 ? 40.0 : 20.0;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  20,
                  horizontalPadding,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SearchBarWidget(
                      hintText: 'Buscar un servicio...',
                      autofocus: false,
                    ),
                    const SizedBox(height: 20),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (var index = 0; index < filters.length; index++)
                            Padding(
                              padding: EdgeInsets.only(
                                right: index == filters.length - 1 ? 0 : 8,
                              ),
                              child: FilterChipWidget(
                                label: filters[index],
                                onPressed: () {},
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: professionals.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (_, _) => const Center(
                          child: Text('No pudimos cargar los profesionales.'),
                        ),
                        data: (items) {
                          final visible = isMock
                              ? items
                              : items
                                    .where(
                                      (item) => item.profession
                                          .toLowerCase()
                                          .contains(
                                            selectedService.toLowerCase(),
                                          ),
                                    )
                                    .toList();
                          return ListView.separated(
                            padding: const EdgeInsets.only(bottom: 32),
                            itemCount: visible.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final professional = isMock
                                  ? visible[index].copyWith(
                                      profession: selectedService,
                                    )
                                  : visible[index];
                              return ProfessionalCardCompact(
                                name: professional.name,
                                profession: professional.profession,
                                rating: professional.rating,
                                reviewCount: professional.reviewCount,
                                location: professional.location,
                                onViewProfile: () =>
                                    onProfessionalSelected(professional),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
