import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko_admin/features/admin/presentation/admin_reports_providers.dart';

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
                                    '${item.requestTitle ?? 'Sin solicitud asociada'}',
                                  ),
                                  trailing: Chip(
                                    label: Text(_reportStatus(item.status)),
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
  'resolved' => 'Resuelto',
  'dismissed' => 'Descartado',
  _ => value,
};
