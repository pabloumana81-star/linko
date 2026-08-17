import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko/core/backend/backend_providers.dart';
import 'package:linko/features/home/presentation/models/professional_profile_data.dart';
import 'package:linko/features/home/presentation/providers/professional_discovery_provider.dart';
import 'package:linko/features/home/presentation/widgets/bottom_navigation_widget.dart';
import 'package:linko/features/home/presentation/widgets/category_card.dart';
import 'package:linko/features/home/presentation/widgets/professional_card.dart';
import 'package:linko/features/home/presentation/widgets/labeled_loading_indicator.dart';
import 'package:linko/features/home/presentation/widgets/professional_discovery_state.dart';
import 'package:linko/features/home/presentation/widgets/search_bar_widget.dart';
import 'package:linko/features/home/presentation/widgets/search_chip_widget.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({
    required this.showBackButton,
    required this.onHomeSelected,
    required this.onProfessionalSelected,
    required this.onResultsRequested,
    required this.onRequestsSelected,
    required this.onProfileSelected,
    super.key,
  });

  final bool showBackButton;
  final VoidCallback onHomeSelected;
  final ValueChanged<ProfessionalProfileData> onProfessionalSelected;
  final ValueChanged<String> onResultsRequested;
  final VoidCallback onRequestsSelected;
  final VoidCallback onProfileSelected;

  static const _frequentSearches = [
    'Electricista',
    'Plomería',
    'Limpieza',
    'Jardinería',
    'Pintura',
  ];

  static const _categories = [
    _SearchCategory(
      name: 'Electricista',
      icon: Icons.electrical_services_rounded,
    ),
    _SearchCategory(name: 'Plomería', icon: Icons.plumbing_rounded),
    _SearchCategory(name: 'Limpieza', icon: Icons.cleaning_services_rounded),
    _SearchCategory(name: 'Jardinería', icon: Icons.yard_rounded),
    _SearchCategory(name: 'Pintura', icon: Icons.format_paint_rounded),
    _SearchCategory(name: 'Aire acondicionado', icon: Icons.ac_unit_rounded),
    _SearchCategory(name: 'Carpintería', icon: Icons.carpenter_rounded),
    _SearchCategory(name: 'Más servicios', icon: Icons.grid_view_rounded),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final professionals = ref.watch(professionalDiscoveryProvider);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: showBackButton,
        toolbarHeight: 88,
        titleSpacing: showBackButton ? 0 : 20,
        title: const SearchBarWidget(
          hintText: '¿Qué servicio necesitas?',
          autofocus: false,
        ),
        actions: const [SizedBox(width: 20)],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth >= 720 ? 40.0 : 20.0;
          final categoryColumns = switch (constraints.maxWidth) {
            >= 1100 => 8,
            >= 720 => 4,
            _ => 2,
          };
          final resultColumns = switch (constraints.maxWidth) {
            >= 1100 => 3,
            >= 720 => 2,
            _ => 1,
          };
          final textScaler = MediaQuery.textScalerOf(context);

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              24,
              horizontalPadding,
              48,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _SearchSectionTitle(label: 'Servicios populares'),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final search in _frequentSearches)
                          SearchChipWidget(
                            label: search,
                            onPressed: () => onResultsRequested(search),
                          ),
                      ],
                    ),
                    const SizedBox(height: 36),
                    const _SearchSectionTitle(label: 'Categorías'),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _categories.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: categoryColumns,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        mainAxisExtent: textScaler.scale(112),
                      ),
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        return CategoryCard(
                          icon: category.icon,
                          name: category.name,
                          onTap: () => onResultsRequested(category.name),
                        );
                      },
                    ),
                    const SizedBox(height: 40),
                    const _SearchSectionTitle(label: 'Resultados'),
                    const SizedBox(height: 16),
                    professionals.when(
                      loading: () => const LabeledLoadingIndicator(
                        label: 'Buscando profesionales…',
                      ),
                      error: (_, _) => ProfessionalDiscoveryState.error(
                        onPrimaryAction: () {
                          ref.invalidate(availableProfessionalsProvider);
                          ref.invalidate(professionalDiscoveryProvider);
                        },
                        onHome: onHomeSelected,
                      ),
                      data: (items) => items.isEmpty
                          ? ProfessionalDiscoveryState.empty(
                              onPrimaryAction: () {
                                Scrollable.ensureVisible(
                                  context,
                                  alignment: 0,
                                  duration: const Duration(milliseconds: 250),
                                );
                              },
                              onHome: onHomeSelected,
                            )
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: items.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: resultColumns,
                                    crossAxisSpacing: 18,
                                    mainAxisSpacing: 18,
                                    mainAxisExtent: textScaler.scale(300),
                                  ),
                              itemBuilder: (context, index) {
                                final professional = items[index];
                                return ProfessionalCard(
                                  name: professional.name,
                                  rating: professional.rating,
                                  profession: professional.profession,
                                  location: professional.location,
                                  onViewProfile: () =>
                                      onProfessionalSelected(professional),
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
      bottomNavigationBar: BottomNavigationWidget(
        selectedIndex: 1,
        onDestinationSelected: (index) {
          if (index == 0) {
            onHomeSelected();
          } else if (index == 2) {
            onRequestsSelected();
          } else if (index == 3) {
            onProfileSelected();
          }
        },
      ),
    );
  }
}

class _SearchSectionTitle extends StatelessWidget {
  const _SearchSectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _SearchCategory {
  const _SearchCategory({required this.name, required this.icon});

  final String name;
  final IconData icon;
}
