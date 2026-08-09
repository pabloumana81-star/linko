import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko/features/admin/domain/admin_request.dart';
import 'package:linko_admin/features/admin/presentation/admin_requests_providers.dart';

class AdminRequestsScreen extends ConsumerWidget {
  const AdminRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      _AdminDataSection<AdminRequest>(
        title: 'Solicitudes',
        description: 'Seguimiento del flujo de solicitudes.',
        sectionKey: 'admin-section-requests',
        value: ref.watch(adminRequestsProvider),
        emptyMessage: 'No hay solicitudes registradas.',
        errorMessage: 'No pudimos cargar las solicitudes.',
        builder: (items) => Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Solicitud')),
                DataColumn(label: Text('Categoría')),
                DataColumn(label: Text('Cliente')),
                DataColumn(label: Text('Profesional')),
                DataColumn(label: Text('Estado')),
                DataColumn(label: Text('Actualización')),
                DataColumn(label: Text('Acciones')),
              ],
              rows: [
                for (final item in items)
                  DataRow(
                    cells: [
                      DataCell(
                        Text(item.title),
                        onTap: () => _showRequestDetails(context, item),
                      ),
                      DataCell(Text(item.category)),
                      DataCell(Text(item.customerName)),
                      DataCell(Text(item.professionalName)),
                      DataCell(Chip(label: Text(_requestStatus(item.status)))),
                      DataCell(Text(_date(item.updatedAt))),
                      DataCell(
                        PopupMenuButton<AdminRequestAction>(
                          tooltip: 'Acciones de la solicitud',
                          onSelected: (action) =>
                              _runRequestAction(context, ref, item, action),
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: AdminRequestAction.flagForReview,
                              child: Text('Marcar para revisión'),
                            ),
                            const PopupMenuItem(
                              value: AdminRequestAction.addInterventionNote,
                              child: Text('Agregar nota'),
                            ),
                            if (!{
                              'pending_customer_confirmation',
                              'pendingCustomerConfirmation',
                              'completed',
                              'reviewed',
                              'cancelled',
                            }.contains(item.status))
                              const PopupMenuItem(
                                value: AdminRequestAction.cancel,
                                child: Text('Cancelar solicitud'),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      );
}

class _AdminDataSection<T> extends StatelessWidget {
  const _AdminDataSection({
    required this.title,
    required this.description,
    required this.sectionKey,
    required this.value,
    required this.emptyMessage,
    required this.errorMessage,
    required this.builder,
  });

  final String title;
  final String description;
  final String sectionKey;
  final AsyncValue<List<T>> value;
  final String emptyMessage;
  final String errorMessage;
  final Widget Function(List<T>) builder;

  @override
  Widget build(BuildContext context) => SafeArea(
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
                title,
                key: ValueKey(sectionKey),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(description),
              const SizedBox(height: 24),
              value.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (_, _) => Center(child: Text(errorMessage)),
                data: (items) => items.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Text(emptyMessage),
                        ),
                      )
                    : builder(items),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

String _requestStatus(String value) => switch (value) {
  'pending' => 'Pendiente',
  'under_review' || 'underReview' => 'En revisión',
  'quoted' => 'Cotizada',
  'accepted' => 'Aceptada',
  'scheduled' => 'Programada',
  'in_progress' || 'inProgress' => 'En progreso',
  'pending_customer_confirmation' ||
  'pendingCustomerConfirmation' => 'Pendiente de confirmación',
  'completed' => 'Completada',
  'reviewed' => 'Calificada',
  'cancelled' => 'Cancelada',
  _ => value,
};

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/'
    '${value.month.toString().padLeft(2, '0')}/${value.year}';

Future<void> _runRequestAction(
  BuildContext context,
  WidgetRef ref,
  AdminRequest request,
  AdminRequestAction action,
) async {
  final controller = TextEditingController();
  final note = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
        action == AdminRequestAction.cancel
            ? 'Confirmar cancelación'
            : 'Registrar intervención',
      ),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: 'Motivo o nota obligatoria',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Volver'),
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
  if (note == null || !context.mounted) return;
  try {
    await ref
        .read(adminRequestOperationsProvider)
        .perform(request.id, action, note);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud actualizada correctamente.')),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No pudimos actualizar la solicitud. Intenta nuevamente.',
          ),
        ),
      );
    }
  }
}

Future<void> _showRequestDetails(BuildContext context, AdminRequest request) =>
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(request.title),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  request.description.isEmpty
                      ? 'Sin descripción.'
                      : request.description,
                ),
                const SizedBox(height: 12),
                Text('Cliente: ${request.customerName}'),
                Text('Profesional: ${request.professionalName}'),
                Text('Categoría: ${request.category}'),
                Text('Estado: ${_requestStatus(request.status)}'),
                Text('Creada: ${_date(request.createdAt)}'),
                Text('Actualizada: ${_date(request.updatedAt)}'),
                Text(
                  request.scheduledAt == null
                      ? 'Sin fecha programada'
                      : 'Programada: ${_date(request.scheduledAt!)}',
                ),
                Text(
                  request.adminReviewFlag
                      ? 'Marcada para revisión administrativa'
                      : 'Sin marca de revisión',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Historial administrativo',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (request.auditHistory.isEmpty)
                  const Text('No hay intervenciones registradas.'),
                for (final audit in request.auditHistory)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(audit.note),
                    subtitle: Text(
                      '${audit.action} · ${_date(audit.createdAt)}',
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
