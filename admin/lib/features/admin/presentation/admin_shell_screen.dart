import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:linko_admin/features/admin/domain/admin_section.dart';
import 'package:linko_admin/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:linko_admin/features/admin/presentation/admin_users_screen.dart';
import 'package:linko_admin/features/admin/presentation/admin_professionals_screen.dart';
import 'package:linko_admin/features/admin/presentation/admin_reports_screen.dart';
import 'package:linko_admin/features/admin/presentation/admin_requests_screen.dart';

class AdminShellScreen extends StatelessWidget {
  const AdminShellScreen({required this.section, this.content, super.key});

  final AdminSection section;
  final Widget? content;

  static const _desktopBreakpoint = 900.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= _desktopBreakpoint;
        return Scaffold(
          appBar: desktop
              ? null
              : AppBar(title: Text('LinkO Admin · ${section.label}')),
          drawer: desktop ? null : _AdminDrawer(section: section),
          body: Row(
            children: [
              if (desktop) _AdminNavigationRail(section: section),
              Expanded(
                child:
                    content ??
                    (section == AdminSection.dashboard
                        ? const AdminDashboardScreen()
                        : section == AdminSection.users
                        ? const AdminUsersScreen()
                        : section == AdminSection.professionals
                        ? const AdminProfessionalsScreen()
                        : section == AdminSection.requests
                        ? const AdminRequestsScreen()
                        : section == AdminSection.reports
                        ? const AdminReportsScreen()
                        : _AdminSectionContent(section: section)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AdminNavigationRail extends StatelessWidget {
  const _AdminNavigationRail({required this.section});

  final AdminSection section;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      key: const ValueKey('admin-navigation-rail'),
      extended: MediaQuery.sizeOf(context).width >= 1180,
      selectedIndex: AdminSection.values.indexOf(section),
      onDestinationSelected: (index) =>
          context.go(AdminSection.values[index].path),
      leading: const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text(
          'LinkO Admin',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      destinations: [
        for (final item in AdminSection.values)
          NavigationRailDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.selectedIcon),
            label: Text(item.label),
          ),
      ],
    );
  }
}

class _AdminDrawer extends StatelessWidget {
  const _AdminDrawer({required this.section});

  final AdminSection section;

  @override
  Widget build(BuildContext context) {
    return NavigationDrawer(
      key: const ValueKey('admin-navigation-drawer'),
      selectedIndex: AdminSection.values.indexOf(section),
      onDestinationSelected: (index) {
        Navigator.of(context).pop();
        context.go(AdminSection.values[index].path);
      },
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(28, 24, 16, 12),
          child: Text(
            'LinkO Admin',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ),
        for (final item in AdminSection.values)
          NavigationDrawerDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.selectedIcon),
            label: Text(item.label),
          ),
      ],
    );
  }
}

class _AdminSectionContent extends StatelessWidget {
  const _AdminSectionContent({required this.section});

  final AdminSection section;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.label,
                  key: ValueKey('admin-section-${section.name}'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  section.description,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 28),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Icon(section.selectedIcon, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Módulo ${section.label.toLowerCase()} listo para '
                            'integrar datos administrativos.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
