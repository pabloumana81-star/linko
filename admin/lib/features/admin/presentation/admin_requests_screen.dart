import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko_admin/features/admin/domain/admin_request.dart';
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
              ],
              rows: [
                for (final item in items)
                  DataRow(
                    cells: [
                      DataCell(Text(item.title)),
                      DataCell(Text(item.category)),
                      DataCell(Text(item.customerName)),
                      DataCell(Text(item.professionalName)),
                      DataCell(Chip(label: Text(_requestStatus(item.status)))),
                      DataCell(Text(_date(item.updatedAt))),
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
