import 'package:flutter/material.dart';

class GuestHomeScreen extends StatelessWidget {
  const GuestHomeScreen({
    required this.onCategorySelected,
    required this.onCreateRequest,
    super.key,
  });

  final ValueChanged<String> onCategorySelected;
  final VoidCallback onCreateRequest;

  static const _categories = [
    _ServiceCategory(name: 'Plumber', icon: Icons.plumbing_rounded),
    _ServiceCategory(
      name: 'Electrician',
      icon: Icons.electrical_services_rounded,
    ),
    _ServiceCategory(name: 'Painter', icon: Icons.format_paint_rounded),
    _ServiceCategory(name: 'Cleaning', icon: Icons.cleaning_services_rounded),
    _ServiceCategory(name: 'Gardener', icon: Icons.yard_rounded),
    _ServiceCategory(name: 'Mechanic', icon: Icons.car_repair_rounded),
    _ServiceCategory(name: 'Computer Repair', icon: Icons.computer_rounded),
    _ServiceCategory(name: 'Appliance Repair', icon: Icons.kitchen_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'LINKO',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 3),
        ),
        centerTitle: false,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final columnCount = switch (constraints.maxWidth) {
            >= 1000 => 4,
            >= 680 => 3,
            _ => 2,
          };

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'What service do you need?',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: const Color(0xFFF4F7FB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Services',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _categories.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columnCount,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: columnCount == 2 ? 1.05 : 1.2,
                      ),
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        return _CategoryCard(
                          category: category,
                          onTap: () => onCategorySelected(category.name),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onCreateRequest,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Request Service'),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onTap});

  final _ServiceCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFDCE4EE)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(category.icon, size: 38, color: const Color(0xFF2F80ED)),
              const SizedBox(height: 12),
              Text(
                category.name,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceCategory {
  const _ServiceCategory({required this.name, required this.icon});

  final String name;
  final IconData icon;
}
