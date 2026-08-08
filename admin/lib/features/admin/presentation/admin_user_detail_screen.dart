import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko/core/diagnostics/diagnostics_service.dart';
import 'package:linko/features/admin/domain/admin_user.dart';
import 'package:linko_admin/features/admin/presentation/admin_users_providers.dart';

class AdminUserDetailScreen extends ConsumerWidget {
  const AdminUserDetailScreen({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: ref
          .watch(adminUserDetailProvider(userId))
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Center(
              child: Text('No pudimos cargar el detalle del usuario.'),
            ),
            data: (detail) => detail == null
                ? const Center(child: Text('No se encontró el usuario.'))
                : _DetailContent(detail: detail),
          ),
    );
  }
}

class _DetailContent extends ConsumerWidget {
  const _DetailContent({required this.detail});

  final AdminUserDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = detail.user;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                key: const ValueKey('admin-user-detail'),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () => _showProfile(context, user),
                    icon: const Icon(Icons.person_outline),
                    label: const Text('Ver perfil'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => _showRequests(context, detail),
                    icon: const Icon(Icons.assignment_outlined),
                    label: const Text('Ver solicitudes'),
                  ),
                  if (user.status == AdminAccountStatus.active)
                    FilledButton.icon(
                      key: const ValueKey('suspend-user'),
                      onPressed: () => _confirmSuspension(context, ref, user),
                      icon: const Icon(Icons.block),
                      label: const Text('Suspender cuenta'),
                    )
                  else
                    FilledButton.icon(
                      key: const ValueKey('reactivate-user'),
                      onPressed: () => _action(
                        context,
                        ref,
                        () => ref
                            .read(adminUserActionsProvider)
                            .reactivate(user.id),
                        successMessage: 'La cuenta fue reactivada.',
                      ),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Reactivar cuenta'),
                    ),
                  OutlinedButton.icon(
                    key: const ValueKey('reset-onboarding'),
                    onPressed: () => _action(
                      context,
                      ref,
                      () => ref
                          .read(adminUserActionsProvider)
                          .resetOnboarding(user.id),
                      successMessage: 'El onboarding fue reiniciado.',
                    ),
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Reiniciar onboarding'),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _ProfileCard(detail: detail),
              const SizedBox(height: 24),
              Text(
                'Historial de la cuenta',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              if (detail.history.isEmpty)
                const Text('No hay acciones administrativas registradas.')
              else
                Card(
                  child: Column(
                    children: [
                      for (final entry in detail.history)
                        ListTile(
                          leading: const Icon(Icons.history),
                          title: Text(entry.action.label),
                          subtitle: Text(
                            '${entry.timestamp.day}/${entry.timestamp.month}/'
                            '${entry.timestamp.year}',
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _action(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() action, {
    required String successMessage,
  }) async {
    try {
      await action();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMessage)));
      }
    } catch (error, stackTrace) {
      ref
          .read(diagnosticsServiceProvider)
          .unexpectedError(error, stackTrace, context: 'admin_user_action');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No pudimos actualizar la cuenta.')),
        );
      }
    }
  }

  Future<void> _confirmSuspension(
    BuildContext context,
    WidgetRef ref,
    AdminUser user,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Suspender cuenta'),
        content: Text(
          '¿Deseas suspender la cuenta de ${user.name}? El usuario perderá el acceso hasta que sea reactivado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const ValueKey('confirm-suspend-user'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Suspender'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await _action(
      context,
      ref,
      () => ref.read(adminUserActionsProvider).suspend(user.id),
      successMessage: 'La cuenta fue suspendida.',
    );
  }

  void _showProfile(BuildContext context, AdminUser user) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Perfil del usuario'),
        content: Text(
          '${user.name}\n${user.email ?? 'Sin correo'}\n${user.id}\n'
          '${user.accountType.label}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showRequests(BuildContext context, AdminUserDetail detail) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Solicitudes del usuario'),
        content: Text(
          'Activas: ${detail.activeRequests}\n'
          'Completadas: ${detail.completedRequests}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.detail});

  final AdminUserDetail detail;

  @override
  Widget build(BuildContext context) {
    final user = detail.user;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Wrap(
          spacing: 32,
          runSpacing: 20,
          children: [
            _Value(label: 'Correo', value: user.email ?? 'Sin correo'),
            _Value(label: 'Tipo de cuenta', value: user.accountType.label),
            _Value(label: 'Estado', value: user.status.label),
            _Value(
              label: 'Solicitudes activas',
              value: '${detail.activeRequests}',
            ),
            _Value(
              label: 'Solicitudes completadas',
              value: '${detail.completedRequests}',
            ),
            _Value(label: 'Calificaciones', value: '${detail.ratings}'),
            _Value(label: 'Reportes', value: '${detail.reports}'),
            _Value(
              label: 'Onboarding',
              value: detail.onboardingCompleted ? 'Completado' : 'Pendiente',
            ),
          ],
        ),
      ),
    );
  }
}

class _Value extends StatelessWidget {
  const _Value({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 210,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(value),
      ],
    ),
  );
}
