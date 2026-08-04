import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko_admin/features/admin/domain/admin_dashboard.dart';
import 'package:linko_admin/features/admin/presentation/admin_dashboard_providers.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRange = ref.watch(adminDashboardRangeProvider);
    final dashboard = ref.watch(adminDashboardProvider);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard',
                  key: const ValueKey('admin-section-dashboard'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Resumen operativo de LinkO.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<AdminDashboardRange>(
                    key: const ValueKey('admin-dashboard-range-filter'),
                    segments: [
                      for (final range in AdminDashboardRange.values)
                        ButtonSegment(value: range, label: Text(range.label)),
                    ],
                    selected: {selectedRange},
                    onSelectionChanged: (selection) => ref
                        .read(adminDashboardRangeProvider.notifier)
                        .select(selection.single),
                  ),
                ),
                const SizedBox(height: 28),
                dashboard.when(
                  loading: () => const _DashboardLoading(),
                  error: (error, stackTrace) => _DashboardError(
                    onRetry: () => ref.invalidate(adminDashboardProvider),
                  ),
                  data: (snapshot) => snapshot.isEmpty
                      ? const _DashboardEmpty()
                      : _DashboardContent(snapshot: snapshot),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.snapshot});

  final AdminDashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final metrics = snapshot.metrics;
    final cards = [
      ('Total de usuarios', '${metrics.totalUsers}', Icons.people_outline),
      (
        'Total de profesionales',
        '${metrics.totalProfessionals}',
        Icons.engineering_outlined,
      ),
      (
        'Solicitudes activas',
        '${metrics.activeRequests}',
        Icons.assignment_outlined,
      ),
      ('Trabajos completados', '${metrics.completedJobs}', Icons.task_alt),
      (
        'Solicitudes canceladas',
        '${metrics.cancelledRequests}',
        Icons.cancel_outlined,
      ),
      (
        'Calificación promedio',
        metrics.averageRating.toStringAsFixed(1),
        Icons.star_outline,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 900
                ? 3
                : constraints.maxWidth >= 560
                ? 2
                : 1;
            final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final card in cards)
                  SizedBox(
                    width: width,
                    child: _MetricCard(
                      label: card.$1,
                      value: card.$2,
                      icon: card.$3,
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 32),
        Text(
          'Actividad reciente',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        if (snapshot.activities.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No hay actividad reciente en este período.'),
            ),
          )
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.activities.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) =>
                  _ActivityTile(activity: snapshot.activities[index]),
            ),
          ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, size: 30),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    key: ValueKey('admin-metric-$label'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
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
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity});

  final AdminActivity activity;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(_icon(activity.type)),
      title: Text(activity.title),
      subtitle: Text(_dateLabel(activity.timestamp)),
    );
  }

  IconData _icon(AdminActivityType type) => switch (type) {
    AdminActivityType.userRegistered => Icons.person_add_outlined,
    AdminActivityType.professionalCreated => Icons.engineering_outlined,
    AdminActivityType.requestCreated => Icons.assignment_add,
    AdminActivityType.quotationSent => Icons.request_quote_outlined,
    AdminActivityType.jobCompleted => Icons.task_alt,
    AdminActivityType.reportOpened => Icons.flag_outlined,
  };

  String _dateLabel(DateTime timestamp) {
    final local = timestamp.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year} · '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(48),
      child: CircularProgressIndicator(
        key: ValueKey('admin-dashboard-loading'),
      ),
    ),
  );
}

class _DashboardEmpty extends StatelessWidget {
  const _DashboardEmpty();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(48),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 48),
          SizedBox(height: 12),
          Text('No hay datos para este período.'),
        ],
      ),
    ),
  );
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          const Text('No pudimos cargar el dashboard.'),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    ),
  );
}
