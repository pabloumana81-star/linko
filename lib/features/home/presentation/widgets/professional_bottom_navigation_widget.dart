import 'package:flutter/material.dart';

class ProfessionalBottomNavigationWidget extends StatelessWidget {
  const ProfessionalBottomNavigationWidget({
    required this.selectedIndex,
    required this.onDestinationSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Inicio',
        ),
        NavigationDestination(
          icon: Icon(Icons.inbox_outlined),
          selectedIcon: Icon(Icons.inbox_rounded),
          label: 'Solicitudes',
        ),
        NavigationDestination(
          icon: Icon(Icons.home_repair_service_outlined),
          selectedIcon: Icon(Icons.home_repair_service_rounded),
          label: 'Servicios',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Perfil',
        ),
      ],
    );
  }
}
