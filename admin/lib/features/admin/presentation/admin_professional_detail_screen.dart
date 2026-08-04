import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko/core/diagnostics/diagnostics_service.dart';
import 'package:linko_admin/features/admin/domain/admin_professional.dart';
import 'package:linko_admin/features/admin/domain/admin_user.dart';
import 'package:linko_admin/features/admin/presentation/admin_professionals_providers.dart';

class AdminProfessionalDetailScreen extends ConsumerWidget {
  const AdminProfessionalDetailScreen({
    required this.professionalId,
    super.key,
  });
  final String professionalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => SafeArea(
    child: ref
        .watch(adminProfessionalDetailProvider(professionalId))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Center(
            child: Text('No pudimos cargar el detalle profesional.'),
          ),
          data: (detail) => detail == null
              ? const Center(child: Text('No se encontró el profesional.'))
              : _Content(detail: detail),
        ),
  );
}

class _Content extends ConsumerWidget {
  const _Content({required this.detail});
  final AdminProfessionalDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = detail.professional;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.name,
              key: const ValueKey('admin-professional-detail'),
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (item.verification !=
                    ProfessionalVerificationStatus.verified)
                  FilledButton.icon(
                    key: const ValueKey('approve-professional'),
                    onPressed: () => _run(
                      context,
                      ref,
                      () => ref
                          .read(adminProfessionalActionsProvider)
                          .approve(item.id),
                      successMessage: 'La verificación fue aprobada.',
                    ),
                    icon: const Icon(Icons.verified_outlined),
                    label: const Text('Aprobar verificación'),
                  ),
                if (item.verification !=
                    ProfessionalVerificationStatus.rejected)
                  OutlinedButton.icon(
                    key: const ValueKey('reject-professional'),
                    onPressed: () => _reasonAction(
                      context,
                      ref,
                      title: 'Rechazar verificación',
                      actionLabel: 'Rechazar',
                      successMessage: 'La verificación fue rechazada.',
                      action: (reason) => ref
                          .read(adminProfessionalActionsProvider)
                          .reject(item.id, reason),
                    ),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Rechazar verificación'),
                  ),
                OutlinedButton.icon(
                  key: const ValueKey('request-professional-information'),
                  onPressed: () => _reasonAction(
                    context,
                    ref,
                    title: 'Solicitar información adicional',
                    actionLabel: 'Solicitar',
                    successMessage: 'Se solicitó información adicional.',
                    action: (reason) => ref
                        .read(adminProfessionalActionsProvider)
                        .requestInformation(item.id, reason),
                  ),
                  icon: const Icon(Icons.contact_support_outlined),
                  label: const Text('Solicitar información'),
                ),
                if (item.accountStatus == AdminAccountStatus.active)
                  FilledButton.tonalIcon(
                    key: const ValueKey('suspend-professional'),
                    onPressed: () => _confirmAction(
                      context,
                      ref,
                      title: 'Suspender cuenta',
                      message:
                          'El profesional dejará de aparecer en el descubrimiento. Su historial permanecerá disponible.',
                      actionLabel: 'Suspender',
                      successMessage: 'La cuenta fue suspendida.',
                      action: () => ref
                          .read(adminProfessionalActionsProvider)
                          .suspend(item.id),
                    ),
                    icon: const Icon(Icons.block),
                    label: const Text('Suspender cuenta'),
                  )
                else
                  FilledButton.tonalIcon(
                    onPressed: () => _run(
                      context,
                      ref,
                      () => ref
                          .read(adminProfessionalActionsProvider)
                          .reactivate(item.id),
                      successMessage: 'La cuenta fue reactivada.',
                    ),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Reactivar cuenta'),
                  ),
                OutlinedButton(
                  onPressed: () => _dialog(
                    context,
                    'Solicitudes',
                    detail.currentRequests.isEmpty
                        ? 'No hay solicitudes activas.'
                        : detail.currentRequests.join('\n'),
                  ),
                  child: const Text('Ver todas las solicitudes'),
                ),
                OutlinedButton(
                  onPressed: () => _dialog(
                    context,
                    'Conversaciones',
                    '${detail.conversationCount} conversaciones registradas.',
                  ),
                  child: const Text('Ver historial de conversaciones'),
                ),
                OutlinedButton(
                  onPressed: () => _dialog(
                    context,
                    'Calificaciones',
                    detail.reviews.isEmpty
                        ? 'No hay reseñas.'
                        : detail.reviews.join('\n'),
                  ),
                  child: const Text('Ver calificaciones'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Wrap(
                  spacing: 32,
                  runSpacing: 20,
                  children: [
                    _Value('Profesión', detail.profession),
                    _Value('Ubicación', detail.location),
                    _Value('Área de cobertura', detail.coverageArea),
                    _Value('Experiencia', '${detail.experienceYears} años'),
                    _Value('Verificación', item.verification.label),
                    _Value('Estado', item.accountStatus.label),
                    _Value(
                      'Calificación',
                      item.averageRating.toStringAsFixed(1),
                    ),
                    _Value('Reseñas', '${detail.reviewCount}'),
                    _Value('Trabajos completados', '${item.completedJobs}'),
                    _Value('Trabajos activos', '${item.activeJobs}'),
                    _Value('Trabajos cancelados', '${detail.cancelledJobs}'),
                    _Value(
                      'Habilidades / categorías',
                      detail.skills.isEmpty
                          ? 'Sin registrar'
                          : detail.skills.join(', '),
                    ),
                    _Value(
                      'Portafolio',
                      detail.portfolio.isEmpty
                          ? 'Sin elementos'
                          : '${detail.portfolio.length} elementos',
                    ),
                    _Value(
                      'Documentos de verificación',
                      detail.verificationDocuments.isEmpty
                          ? 'Sin documentos'
                          : '${detail.verificationDocuments.length} documentos',
                    ),
                  ],
                ),
              ),
            ),
            if (detail.portfolio.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Portafolio',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Card(
                child: Column(
                  children: [
                    for (final item in detail.portfolio)
                      ListTile(
                        leading: const Icon(Icons.photo_library_outlined),
                        title: Text(item),
                        trailing: const Icon(Icons.visibility_outlined),
                        onTap: () => _dialog(
                          context,
                          'Vista previa del portafolio',
                          item,
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (detail.verificationDocuments.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Documentos de verificación',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Card(
                child: Column(
                  children: [
                    for (final document in detail.verificationDocuments)
                      ListTile(
                        leading: const Icon(Icons.description_outlined),
                        title: Text(document),
                        trailing: const Icon(Icons.visibility_outlined),
                        onTap: () => _dialog(
                          context,
                          'Vista previa del documento',
                          document,
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Actividad de la cuenta',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            if (detail.timeline.isEmpty)
              const Text('No hay acciones administrativas registradas.')
            else
              Card(
                child: Column(
                  children: [
                    for (final entry in detail.timeline)
                      ListTile(
                        leading: const Icon(Icons.history),
                        title: Text(entry.action.label),
                        subtitle: Text(
                          '${entry.previousValue} → ${entry.newValue}',
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _run(
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
          .unexpectedError(
            error,
            stackTrace,
            context: 'admin_professional_action',
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No pudimos actualizar la cuenta.')),
        );
      }
    }
  }

  Future<void> _confirmAction(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String message,
    required String actionLabel,
    required String successMessage,
    required Future<void> Function() action,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const ValueKey('confirm-professional-destructive-action'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await _run(context, ref, action, successMessage: successMessage);
    }
  }

  Future<void> _reasonAction(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String actionLabel,
    required String successMessage,
    required Future<void> Function(String reason) action,
  }) async {
    final formKey = GlobalKey<FormState>();
    var reasonText = '';
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Form(
          key: formKey,
          child: TextFormField(
            key: const ValueKey('professional-action-reason'),
            autofocus: true,
            maxLines: 3,
            onChanged: (value) => reasonText = value,
            decoration: const InputDecoration(
              labelText: 'Motivo',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Debes indicar un motivo.'
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const ValueKey('confirm-professional-reason-action'),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(dialogContext).pop(reasonText.trim());
              }
            },
            child: Text(actionLabel),
          ),
        ],
      ),
    );
    if (reason != null && context.mounted) {
      await _run(
        context,
        ref,
        () => action(reason),
        successMessage: successMessage,
      );
    }
  }

  void _dialog(BuildContext context, String title, String body) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(body),
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

class _Value extends StatelessWidget {
  const _Value(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 220,
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
