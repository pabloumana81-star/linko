import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko/core/backend/backend_config.dart';
import 'package:linko/core/backend/backend_providers.dart';
import 'package:linko/features/auth/domain/models/app_user_profile.dart';
import 'package:linko/features/auth/presentation/auth_controller.dart';
import 'package:linko_admin/features/admin/presentation/admin_repositories_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final adminDatabaseReachableProvider = FutureProvider<bool>((ref) async {
  final config = ref.watch(backendConfigProvider);
  if (config.mode == BackendMode.mock) return true;
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return false;
  try {
    await client.from('profiles').select('id').limit(1);
    return true;
  } catch (_) {
    return false;
  }
});

final adminRealtimeConnectedProvider = StreamProvider.autoDispose<bool>((ref) {
  final config = ref.watch(backendConfigProvider);
  if (config.mode == BackendMode.mock) return Stream.value(false);
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return Stream.value(false);

  final controller = StreamController<bool>();
  final channel = client.channel('admin-diagnostics-connection');
  channel.subscribe((status, _) {
    if (!controller.isClosed) {
      controller.add(status == RealtimeSubscribeStatus.subscribed);
    }
  });
  ref.onDispose(() {
    unawaited(client.removeChannel(channel));
    unawaited(controller.close());
  });
  return controller.stream;
});

class AdminDiagnosticsScreen extends ConsumerWidget {
  const AdminDiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(backendConfigProvider);
    final repositories = ref.watch(adminRepositoriesProvider);
    final auth = ref.watch(authControllerProvider);
    final database = ref.watch(adminDatabaseReachableProvider);
    final realtime = ref.watch(adminRealtimeConnectedProvider);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Diagnóstico del Admin')),
      body: SafeArea(
        child: SingleChildScrollView(
          key: const ValueKey('admin-diagnostics-page'),
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              _DiagnosticValue(
                label: 'Modo de backend',
                value: repositories.mode == BackendMode.supabase
                    ? 'SUPABASE'
                    : 'MOCK',
              ),
              _DiagnosticValue(
                label: 'URL de Supabase',
                value: _maskedUrl(config),
              ),
              _DiagnosticValue(
                label: 'Dashboard',
                value: repositories.dashboard.runtimeType.toString(),
              ),
              _DiagnosticValue(
                label: 'Usuarios',
                value: repositories.users.runtimeType.toString(),
              ),
              _DiagnosticValue(
                label: 'Profesionales',
                value: repositories.professionals.runtimeType.toString(),
              ),
              _DiagnosticValue(
                label: 'Solicitudes',
                value: repositories.requests.runtimeType.toString(),
              ),
              _DiagnosticValue(
                label: 'Reportes',
                value: repositories.reports.runtimeType.toString(),
              ),
              _DiagnosticValue(
                label: 'Realtime conectado',
                value: config.mode == BackendMode.mock
                    ? 'No aplica'
                    : realtime.when(
                        data: (connected) => connected ? 'Sí' : 'No',
                        loading: () => 'Comprobando',
                        error: (_, _) => 'No',
                      ),
              ),
              _DiagnosticValue(
                label: 'Usuario autenticado',
                value: user == null
                    ? 'Ninguno'
                    : '${user.displayName} (${user.id})',
              ),
              _DiagnosticValue(
                label: 'Rol actual',
                value: user?.role == UserRole.admin
                    ? 'Administrador'
                    : 'Usuario',
              ),
              _DiagnosticValue(
                label: 'Base de datos accesible',
                value: database.when(
                  data: (reachable) => reachable ? 'Sí' : 'No',
                  loading: () => 'Comprobando',
                  error: (_, _) => 'No',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiagnosticValue extends StatelessWidget {
  const _DiagnosticValue({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(title: Text(label), subtitle: SelectableText(value)),
  );
}

String _maskedUrl(BackendConfig config) {
  if (config.mode == BackendMode.mock) return 'No aplica';
  final uri = Uri.tryParse(config.supabaseUrl);
  if (uri == null || uri.host.isEmpty) return 'Configurada (oculta)';
  final parts = uri.host.split('.');
  final suffix = parts.length > 1 ? '.${parts.skip(1).join('.')}' : '';
  return '${uri.scheme}://••••$suffix';
}
