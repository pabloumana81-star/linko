import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:linko_admin/features/admin/domain/admin_section.dart';
import 'package:linko_admin/features/admin/presentation/admin_access_gate.dart';
import 'package:linko_admin/features/admin/presentation/admin_professional_detail_screen.dart';
import 'package:linko_admin/features/admin/presentation/admin_shell_screen.dart';
import 'package:linko_admin/features/admin/presentation/admin_user_detail_screen.dart';
import 'package:linko_admin/features/admin/presentation/admin_diagnostics_screen.dart';

abstract final class AdminRoutes {
  static const dashboard = '/';
  static const users = '/users';
  static const userDetail = '/users/:userId';
  static const professionals = '/professionals';
  static const professionalDetail = '/professionals/:professionalId';
  static const requests = '/requests';
  static const reports = '/reports';
  static const settings = '/settings';
  static const diagnostics = '/diagnostics';
}

GoRoute _sectionRoute(String path, AdminSection section) => GoRoute(
  path: path,
  builder: (_, _) => AdminAccessGate(child: AdminShellScreen(section: section)),
);

GoRouter createAdminRouter({String initialLocation = AdminRoutes.dashboard}) =>
    GoRouter(
      initialLocation: initialLocation,
      routes: [
        _sectionRoute(AdminRoutes.dashboard, AdminSection.dashboard),
        _sectionRoute(AdminRoutes.users, AdminSection.users),
        GoRoute(
          path: AdminRoutes.userDetail,
          builder: (_, state) => AdminAccessGate(
            child: AdminShellScreen(
              section: AdminSection.users,
              content: AdminUserDetailScreen(
                userId: state.pathParameters['userId']!,
              ),
            ),
          ),
        ),
        _sectionRoute(AdminRoutes.professionals, AdminSection.professionals),
        GoRoute(
          path: AdminRoutes.professionalDetail,
          builder: (_, state) => AdminAccessGate(
            child: AdminShellScreen(
              section: AdminSection.professionals,
              content: AdminProfessionalDetailScreen(
                professionalId: state.pathParameters['professionalId']!,
              ),
            ),
          ),
        ),
        _sectionRoute(AdminRoutes.requests, AdminSection.requests),
        _sectionRoute(AdminRoutes.reports, AdminSection.reports),
        _sectionRoute(AdminRoutes.settings, AdminSection.settings),
        if (kDebugMode)
          GoRoute(
            path: AdminRoutes.diagnostics,
            builder: (_, _) =>
                const AdminAccessGate(child: AdminDiagnosticsScreen()),
          ),
      ],
      errorBuilder: (_, _) => const Scaffold(
        body: Center(child: Text('Página administrativa no encontrada.')),
      ),
    );

final adminRouter = createAdminRouter();
