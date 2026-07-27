import 'package:flutter/material.dart';
import 'package:linko/features/home/presentation/widgets/bottom_navigation_widget.dart';

class CustomerRequestsScreen extends StatelessWidget {
  const CustomerRequestsScreen({
    required this.onHomeSelected,
    required this.onSearchSelected,
    super.key,
  });

  final VoidCallback onHomeSelected;
  final VoidCallback onSearchSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Solicitudes'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 52,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Tus solicitudes aparecerán aquí.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationWidget(
        selectedIndex: 2,
        onDestinationSelected: (index) {
          if (index == 0) {
            onHomeSelected();
          } else if (index == 1) {
            onSearchSelected();
          }
        },
      ),
    );
  }
}
