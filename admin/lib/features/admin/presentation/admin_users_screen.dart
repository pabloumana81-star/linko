import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linko/features/admin/domain/admin_user.dart';
import 'package:linko_admin/features/admin/presentation/admin_users_providers.dart';

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(adminUserQueryProvider);
    final users = ref.watch(adminUsersProvider);
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
                  'Usuarios',
                  key: const ValueKey('admin-section-users'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Gestión de cuentas y acceso a LinkO.'),
                const SizedBox(height: 24),
                TextField(
                  key: const ValueKey('admin-user-search'),
                  decoration: const InputDecoration(
                    labelText: 'Buscar por nombre, correo o ID',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: ref.read(adminUserQueryProvider.notifier).search,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Activos'),
                      selected: query.status == AdminAccountStatus.active,
                      onSelected: (selected) => ref
                          .read(adminUserQueryProvider.notifier)
                          .status(selected ? AdminAccountStatus.active : null),
                    ),
                    FilterChip(
                      label: const Text('Suspendidos'),
                      selected: query.status == AdminAccountStatus.suspended,
                      onSelected: (selected) => ref
                          .read(adminUserQueryProvider.notifier)
                          .status(
                            selected ? AdminAccountStatus.suspended : null,
                          ),
                    ),
                    for (final type in AdminAccountType.values)
                      FilterChip(
                        label: Text(type.label),
                        selected: query.accountType == type,
                        onSelected: (selected) => ref
                            .read(adminUserQueryProvider.notifier)
                            .accountType(selected ? type : null),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                users.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (_, _) => const Center(
                    child: Text('No pudimos cargar los usuarios.'),
                  ),
                  data: (items) => items.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: Text('No se encontraron usuarios.'),
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) =>
                              constraints.maxWidth >= 900
                              ? _UsersTable(users: items)
                              : _UsersCards(users: items),
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

class _UsersTable extends StatelessWidget {
  const _UsersTable({required this.users});

  final List<AdminUser> users;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Usuario')),
            DataColumn(label: Text('Correo')),
            DataColumn(label: Text('Tipo de cuenta')),
            DataColumn(label: Text('Estado')),
            DataColumn(label: Text('Registro')),
            DataColumn(label: Text('Último acceso')),
          ],
          rows: [
            for (final user in users)
              DataRow(
                key: ValueKey('admin-user-${user.id}'),
                onSelectChanged: (_) => context.go('/users/${user.id}'),
                cells: [
                  DataCell(
                    Row(
                      children: [
                        _UserAvatar(user: user),
                        const SizedBox(width: 10),
                        Text(user.name),
                      ],
                    ),
                  ),
                  DataCell(Text(user.email ?? 'Sin correo')),
                  DataCell(Text(user.accountType.label)),
                  DataCell(_StatusBadge(status: user.status)),
                  DataCell(Text(_date(user.registeredAt))),
                  DataCell(
                    Text(
                      user.lastLoginAt == null
                          ? 'Sin acceso registrado'
                          : _date(user.lastLoginAt!),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _UsersCards extends StatelessWidget {
  const _UsersCards({required this.users});

  final List<AdminUser> users;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final user in users)
        Card(
          key: ValueKey('admin-user-${user.id}'),
          child: ListTile(
            leading: _UserAvatar(user: user),
            title: Text(user.name),
            subtitle: Text(
              '${user.email ?? 'Sin correo'} · ${user.accountType.label}',
            ),
            trailing: _StatusBadge(status: user.status),
            onTap: () => context.go('/users/${user.id}'),
          ),
        ),
    ],
  );
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.user});

  final AdminUser user;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    backgroundImage: user.avatarUrl == null
        ? null
        : NetworkImage(user.avatarUrl!),
    child: user.avatarUrl == null ? Text(_initials(user.name)) : null,
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final AdminAccountStatus status;

  @override
  Widget build(BuildContext context) => Chip(
    label: Text(status.label),
    avatar: Icon(
      status == AdminAccountStatus.active ? Icons.check_circle : Icons.block,
      size: 16,
    ),
  );
}

String _initials(String name) =>
    name.trim().split(RegExp(r'\s+')).take(2).map((part) => part[0]).join();

String _date(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';
