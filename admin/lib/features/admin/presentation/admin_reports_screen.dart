import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko_admin/features/admin/presentation/admin_reports_providers.dart';
import 'package:linko_admin/features/admin/domain/admin_report.dart';

class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(adminReportsProvider);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reportes',
                  key: const ValueKey('admin-section-reports'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Incidentes que requieren atención administrativa.'),
                const SizedBox(height: 24),
                reports.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (_, _) => const Center(
                    child: Text('No pudimos cargar los reportes.'),
                  ),
                  data: (items) => items.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: Text('No hay reportes registrados.'),
                          ),
                        )
                      : Card(
                          child: Column(
                            children: [
                              for (final item in items)
                                ListTile(
                                  leading: const Icon(Icons.flag_outlined),
                                  title: Text(item.reason),
                                  subtitle: Text(
                                    '${item.reporterName} · '
                                    '${item.requestTitle ?? 'Sin solicitud asociada'}'
                                    '${item.auditHistory.isEmpty ? '' : '\nÚltima acción: ${item.auditHistory.first.note}'}',
                                  ),
                                  onTap: () =>
                                      _showReportDetails(context, item),
                                  isThreeLine: item.auditHistory.isNotEmpty,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Chip(
                                        label: Text(_reportStatus(item.status)),
                                      ),
                                      if (item.status != 'resolved' &&
                                          item.status != 'dismissed')
                                        PopupMenuButton<AdminReportAction>(
                                          tooltip: 'Acciones del reporte',
                                          onSelected: (action) =>
                                              _runReportAction(
                                                context,
                                                ref,
                                                item,
                                                action,
                                              ),
                                          itemBuilder: (_) => const [
                                            PopupMenuItem(
                                              value: AdminReportAction.resolve,
                                              child: Text('Resolver'),
                                            ),
                                            PopupMenuItem(
                                              value: AdminReportAction.dismiss,
                                              child: Text('Descartar'),
                                            ),
                                            PopupMenuItem(
                                              value: AdminReportAction.escalate,
                                              child: Text('Escalar'),
                                            ),
                                          ],
                                        ),
                                    ],
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

String _reportStatus(String value) => switch (value) {
  'open' => 'Abierto',
  'in_review' => 'En revisión',
  'escalated' => 'Escalado',
  'resolved' => 'Resuelto',
  'dismissed' => 'Descartado',
  _ => value,
};

Future<void> _runReportAction(
  BuildContext context,
  WidgetRef ref,
  AdminReport report,
  AdminReportAction action,
) async {
  final label = switch (action) {
    AdminReportAction.resolve => 'resolver',
    AdminReportAction.dismiss => 'descartar',
    AdminReportAction.escalate => 'escalar',
  };
  final note = await _requiredNoteDialog(
    context,
    title: 'Confirmar acción',
    prompt: 'Indica el motivo para $label el reporte.',
  );
  if (note == null || !context.mounted) return;
  try {
    await ref
        .read(adminReportOperationsProvider)
        .perform(report.id, action, note);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reporte actualizado correctamente.')),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No pudimos actualizar el reporte. Intenta nuevamente.',
          ),
        ),
      );
    }
  }
}

Future<String?> _requiredNoteDialog(
  BuildContext context, {
  required String title,
  required String prompt,
}) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: 'Motivo obligatorio',
          helperText: prompt,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final value = controller.text.trim();
            if (value.isNotEmpty) Navigator.pop(dialogContext, value);
          },
          child: const Text('Confirmar'),
        ),
      ],
    ),
  );
}

Future<void> _showReportDetails(BuildContext context, AdminReport report) =>
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(report.reason),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Reportado por: ${report.reporterName}'),
                Text('Solicitud: ${report.requestTitle ?? 'No asociada'}'),
                Text('Estado: ${_reportStatus(report.status)}'),
                const SizedBox(height: 16),
                const Text(
                  'Historial administrativo',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (report.auditHistory.isEmpty)
                  const Text('No hay acciones registradas.'),
                for (final audit in report.auditHistory)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(audit.note),
                    subtitle: Text(
                      '${_reportStatus(audit.previousStatus)} → '
                      '${_reportStatus(audit.newStatus)}',
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
