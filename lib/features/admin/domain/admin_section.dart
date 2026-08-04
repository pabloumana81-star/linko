import 'package:flutter/material.dart';

enum AdminSection {
  dashboard(
    label: 'Dashboard',
    path: '/admin',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
    description: 'Resumen operativo de LinkO.',
  ),
  users(
    label: 'Usuarios',
    path: '/admin/users',
    icon: Icons.people_outline,
    selectedIcon: Icons.people,
    description: 'Gestión de cuentas de clientes.',
  ),
  professionals(
    label: 'Profesionales',
    path: '/admin/professionals',
    icon: Icons.engineering_outlined,
    selectedIcon: Icons.engineering,
    description: 'Revisión y gestión de profesionales.',
  ),
  requests(
    label: 'Solicitudes',
    path: '/admin/requests',
    icon: Icons.assignment_outlined,
    selectedIcon: Icons.assignment,
    description: 'Seguimiento del flujo de solicitudes.',
  ),
  reports(
    label: 'Reportes',
    path: '/admin/reports',
    icon: Icons.flag_outlined,
    selectedIcon: Icons.flag,
    description: 'Incidentes y reportes que requieren atención.',
  ),
  settings(
    label: 'Configuración',
    path: '/admin/settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    description: 'Configuración operativa del backoffice.',
  );

  const AdminSection({
    required this.label,
    required this.path,
    required this.icon,
    required this.selectedIcon,
    required this.description,
  });

  final String label;
  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final String description;
}
