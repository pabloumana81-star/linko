import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linko_admin/features/admin/domain/admin_professional.dart';
import 'package:linko_admin/features/admin/domain/admin_user.dart';
import 'package:linko_admin/features/admin/presentation/admin_professionals_providers.dart';

class AdminProfessionalsScreen extends ConsumerWidget {
  const AdminProfessionalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final professionals = ref.watch(adminProfessionalsProvider);
    final query = ref.watch(adminProfessionalQueryProvider);
    final controller = ref.read(adminProfessionalQueryProvider.notifier);
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
                  'Profesionales',
                  key: const ValueKey('admin-section-professionals'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Verificación y operación de profesionales.'),
                const SizedBox(height: 24),
                TextField(
                  key: const ValueKey('admin-professional-search'),
                  decoration: const InputDecoration(
                    labelText: 'Buscar por nombre, correo o ID',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: controller.search,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Filter(
                      label: 'Pendientes',
                      selected:
                          query.verification ==
                          ProfessionalVerificationStatus.pending,
                      onSelected: (value) => controller.verification(
                        value ? ProfessionalVerificationStatus.pending : null,
                      ),
                    ),
                    _Filter(
                      label: 'Verificados',
                      selected:
                          query.verification ==
                          ProfessionalVerificationStatus.verified,
                      onSelected: (value) => controller.verification(
                        value ? ProfessionalVerificationStatus.verified : null,
                      ),
                    ),
                    _Filter(
                      label: 'Rechazados',
                      selected:
                          query.verification ==
                          ProfessionalVerificationStatus.rejected,
                      onSelected: (value) => controller.verification(
                        value ? ProfessionalVerificationStatus.rejected : null,
                      ),
                    ),
                    _Filter(
                      label: 'Suspendidos',
                      selected:
                          query.accountStatus == AdminAccountStatus.suspended,
                      onSelected: (value) => controller.accountStatus(
                        value ? AdminAccountStatus.suspended : null,
                      ),
                    ),
                    _Filter(
                      label: 'Activos',
                      selected:
                          query.accountStatus == AdminAccountStatus.active,
                      onSelected: (value) => controller.accountStatus(
                        value ? AdminAccountStatus.active : null,
                      ),
                    ),
                    _Filter(
                      label: 'Mejor calificados',
                      selected:
                          query.rating == ProfessionalRatingFilter.topRated,
                      onSelected: (value) => controller.rating(
                        value ? ProfessionalRatingFilter.topRated : null,
                      ),
                    ),
                    _Filter(
                      label: 'Baja calificación',
                      selected:
                          query.rating == ProfessionalRatingFilter.lowRated,
                      onSelected: (value) => controller.rating(
                        value ? ProfessionalRatingFilter.lowRated : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                professionals.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (_, _) => const Center(
                    child: Text('No pudimos cargar los profesionales.'),
                  ),
                  data: (items) => items.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: Text('No se encontraron profesionales.'),
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) =>
                              constraints.maxWidth >= 920
                              ? _ProfessionalsTable(items: items)
                              : _ProfessionalCards(items: items),
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

class _Filter extends StatelessWidget {
  const _Filter({
    required this.label,
    required this.selected,
    required this.onSelected,
  });
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  @override
  Widget build(BuildContext context) => FilterChip(
    label: Text(label),
    selected: selected,
    onSelected: onSelected,
  );
}

class _ProfessionalsTable extends StatelessWidget {
  const _ProfessionalsTable({required this.items});
  final List<AdminProfessional> items;

  @override
  Widget build(BuildContext context) => Card(
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Profesional')),
          DataColumn(label: Text('Correo')),
          DataColumn(label: Text('Categorías')),
          DataColumn(label: Text('Verificación')),
          DataColumn(label: Text('Calificación')),
          DataColumn(label: Text('Completados')),
          DataColumn(label: Text('Activos')),
          DataColumn(label: Text('Registro')),
          DataColumn(label: Text('Cuenta')),
        ],
        rows: [
          for (final item in items)
            DataRow(
              onSelectChanged: (_) => context.go('/professionals/${item.id}'),
              cells: [
                DataCell(
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: item.photoUrl == null
                            ? null
                            : NetworkImage(item.photoUrl!),
                        child: item.photoUrl == null
                            ? Text(item.name.substring(0, 1))
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Text(item.name),
                    ],
                  ),
                ),
                DataCell(Text(item.email ?? 'Sin correo')),
                DataCell(Text(item.categories.join(', '))),
                DataCell(_VerificationBadge(status: item.verification)),
                DataCell(Text(item.averageRating.toStringAsFixed(1))),
                DataCell(Text('${item.completedJobs}')),
                DataCell(Text('${item.activeJobs}')),
                DataCell(Text(_date(item.registeredAt))),
                DataCell(Text(item.accountStatus.label)),
              ],
            ),
        ],
      ),
    ),
  );
}

class _ProfessionalCards extends StatelessWidget {
  const _ProfessionalCards({required this.items});
  final List<AdminProfessional> items;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final item in items)
        Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: item.photoUrl == null
                  ? null
                  : NetworkImage(item.photoUrl!),
              child: item.photoUrl == null
                  ? Text(item.name.substring(0, 1))
                  : null,
            ),
            title: Text(item.name),
            subtitle: Text(
              '${item.email ?? 'Sin correo'}\n'
              '${item.categories.join(', ')}\n'
              '${item.accountStatus.label} · '
              '${item.averageRating.toStringAsFixed(1)} · '
              '${item.completedJobs} completados · ${item.activeJobs} activos\n'
              'Registro: ${_date(item.registeredAt)}',
            ),
            trailing: _VerificationBadge(status: item.verification),
            onTap: () => context.go('/professionals/${item.id}'),
          ),
        ),
    ],
  );
}

class _VerificationBadge extends StatelessWidget {
  const _VerificationBadge({required this.status});
  final ProfessionalVerificationStatus status;

  @override
  Widget build(BuildContext context) => Chip(
    avatar: Icon(switch (status) {
      ProfessionalVerificationStatus.pending => Icons.schedule,
      ProfessionalVerificationStatus.verified => Icons.verified,
      ProfessionalVerificationStatus.rejected => Icons.cancel,
    }, size: 16),
    label: Text(status.label),
  );
}

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/'
    '${value.month.toString().padLeft(2, '0')}/${value.year}';
