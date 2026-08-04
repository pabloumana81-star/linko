import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko/core/backend/backend_config.dart';
import 'package:linko/core/backend/backend_providers.dart';
import 'package:linko/core/diagnostics/diagnostics_service.dart';
import 'package:linko/features/auth/presentation/auth_controller.dart';

class DebugDiagnosticsOverlay extends ConsumerWidget {
  const DebugDiagnosticsOverlay({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    if (auth.status == AuthStatus.suspended) {
      return const _SuspendedAccountView();
    }
    if (!kDebugMode) return child;
    final diagnostics = ref.watch(diagnosticsServiceProvider);
    final repositories = ref.watch(backendRepositoriesProvider);
    final initialization = ref.watch(backendInitializationProvider);
    return ListenableBuilder(
      listenable: diagnostics,
      builder: (context, _) {
        final event = diagnostics.lastWorkflowEvent;
        final connection = repositories.mode == BackendMode.mock
            ? 'No configurado'
            : initialization.isReady
            ? 'Conectado'
            : 'Error';
        return Stack(
          children: [
            child,
            Positioned(
              left: 8,
              bottom: 8,
              child: IgnorePointer(
                child: Semantics(
                  container: true,
                  label: 'Diagnóstico de desarrollo',
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: DefaultTextStyle(
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          height: 1.25,
                        ),
                        child: Text(
                          'Usuario: ${auth.user?.id ?? auth.status.name}\n'
                          'Solicitud: ${event?.requestId ?? '—'}\n'
                          'Estado: ${event?.newState.name ?? '—'}\n'
                          'Repositorio: ${repositories.mode.name}\n'
                          'Supabase: $connection',
                          key: const ValueKey('debug-diagnostics-overlay'),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SuspendedAccountView extends ConsumerWidget {
  const _SuspendedAccountView();

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.block, size: 56),
              const SizedBox(height: 20),
              Text(
                'Cuenta suspendida',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text(
                'Tu cuenta está suspendida. Contacta al equipo de soporte de LinkO para recibir ayuda.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).signOut(),
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
