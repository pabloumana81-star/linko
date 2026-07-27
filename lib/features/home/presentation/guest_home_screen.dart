import 'package:flutter/material.dart';
import 'package:linko/features/home/presentation/data/placeholder_professionals.dart';
import 'package:linko/features/home/presentation/models/professional_profile_data.dart';
import 'package:linko/features/home/presentation/widgets/bottom_navigation_widget.dart';
import 'package:linko/features/home/presentation/widgets/category_card.dart';
import 'package:linko/features/home/presentation/widgets/professional_card.dart';
import 'package:linko/features/home/presentation/widgets/search_bar_widget.dart';

class GuestHomeScreen extends StatelessWidget {
  const GuestHomeScreen({
    required this.onCategorySelected,
    required this.onCreateRequest,
    required this.onSearchRequested,
    required this.onSearchTabSelected,
    required this.onRequestsSelected,
    required this.onProfessionalSelected,
    super.key,
  });

  final ValueChanged<String> onCategorySelected;
  final VoidCallback onCreateRequest;
  final VoidCallback onSearchRequested;
  final VoidCallback onSearchTabSelected;
  final VoidCallback onRequestsSelected;
  final ValueChanged<ProfessionalProfileData> onProfessionalSelected;

  static const _categories = [
    _CategoryData(
      name: 'Electricista',
      icon: Icons.electrical_services_rounded,
    ),
    _CategoryData(name: 'Plomería', icon: Icons.plumbing_rounded),
    _CategoryData(name: 'Limpieza', icon: Icons.cleaning_services_rounded),
    _CategoryData(name: 'Jardinería', icon: Icons.yard_rounded),
    _CategoryData(name: 'Pintura', icon: Icons.format_paint_rounded),
    _CategoryData(name: 'Aire acondicionado', icon: Icons.ac_unit_rounded),
    _CategoryData(name: 'Carpintería', icon: Icons.carpenter_rounded),
    _CategoryData(name: 'Más servicios', icon: Icons.grid_view_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'LinkO',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3),
        ),
        centerTitle: false,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth >= 720 ? 40.0 : 20.0;
          final categoryColumns = switch (constraints.maxWidth) {
            >= 1100 => 8,
            >= 720 => 4,
            _ => 2,
          };
          final professionalColumns = constraints.maxWidth >= 900 ? 3 : 1;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              28,
              horizontalPadding,
              48,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '¿Qué servicio necesitas hoy?',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Encuentra profesionales de confianza cerca de ti.',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SearchBarWidget(readOnly: true, onTap: onSearchRequested),
                    const SizedBox(height: 40),
                    const _SectionTitle(label: 'Categorías'),
                    const SizedBox(height: 18),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _categories.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: categoryColumns,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: categoryColumns == 2 ? 1.3 : 1.15,
                      ),
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        return CategoryCard(
                          icon: category.icon,
                          name: category.name,
                          onTap: () => onCategorySelected(category.name),
                        );
                      },
                    ),
                    const SizedBox(height: 44),
                    const _SectionTitle(label: 'Profesionales destacados'),
                    const SizedBox(height: 18),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 3,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: professionalColumns,
                        crossAxisSpacing: 18,
                        mainAxisSpacing: 18,
                        mainAxisExtent: 252,
                      ),
                      itemBuilder: (context, index) {
                        final professional = placeholderProfessionals[index];
                        return ProfessionalCard(
                          name: professional.name,
                          rating: professional.rating,
                          profession: professional.profession,
                          location: professional.location,
                          onViewProfile: () {
                            onProfessionalSelected(professional);
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationWidget(
        onDestinationSelected: (index) {
          if (index == 1) {
            onSearchTabSelected();
          } else if (index == 2) {
            onRequestsSelected();
          }
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});

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

class _CategoryData {
  const _CategoryData({required this.name, required this.icon});

  final String name;
  final IconData icon;
}
