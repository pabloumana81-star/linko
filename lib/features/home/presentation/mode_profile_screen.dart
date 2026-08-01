import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko/app/app_mode.dart';
import 'package:linko/features/auth/presentation/auth_controller.dart';
import 'package:linko/features/home/presentation/widgets/bottom_navigation_widget.dart';
import 'package:linko/features/home/presentation/widgets/professional_bottom_navigation_widget.dart';

class ModeProfileScreen extends ConsumerWidget {
  const ModeProfileScreen({
    required this.mode,
    required this.onChangeMode,
    required this.onHomeSelected,
    required this.onRequestsSelected,
    this.onSearchSelected,
    this.onSignOut,
    super.key,
  });

  final AppMode mode;
  final VoidCallback onChangeMode;
  final VoidCallback onHomeSelected;
  final VoidCallback onRequestsSelected;
  final VoidCallback? onSearchSelected;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCustomer = mode == AppMode.customer;
    final profile = ref.watch(authControllerProvider).user;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Perfil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: colors.primaryContainer,
                  foregroundColor: colors.onPrimaryContainer,
                  backgroundImage:
                      profile?.avatarUrl == null || profile!.avatarUrl!.isEmpty
                      ? null
                      : NetworkImage(profile.avatarUrl!),
                  child:
                      profile?.avatarUrl == null || profile!.avatarUrl!.isEmpty
                      ? const Icon(Icons.person_rounded, size: 44)
                      : null,
                ),
                const SizedBox(height: 18),
                Text(
                  profile?.displayName ??
                      (isCustomer
                          ? 'Perfil del cliente'
                          : 'Perfil profesional'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 36),
                Text(
                  'Modo de uso',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        isCustomer ? 'Cliente' : 'Profesional',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isCustomer
                            ? 'Encuentra y solicita servicios profesionales.'
                            : 'Gestiona solicitudes y servicios de clientes.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 18),
                      OutlinedButton(
                        key: ValueKey(
                          isCustomer
                              ? 'switch-to-professional'
                              : 'switch-to-customer',
                        ),
                        onPressed: onChangeMode,
                        child: Text(
                          isCustomer
                              ? 'Cambiar a profesional'
                              : 'Cambiar a cliente',
                        ),
                      ),
                    ],
                  ),
                ),
                if (onSignOut != null) ...[
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    key: const ValueKey('auth-sign-out'),
                    onPressed: onSignOut,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Cerrar sesión'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: isCustomer
          ? BottomNavigationWidget(
              selectedIndex: 3,
              onDestinationSelected: (index) {
                if (index == 0) {
                  onHomeSelected();
                } else if (index == 1) {
                  onSearchSelected?.call();
                } else if (index == 2) {
                  onRequestsSelected();
                }
              },
            )
          : ProfessionalBottomNavigationWidget(
              selectedIndex: 3,
              onDestinationSelected: (index) {
                if (index == 0) {
                  onHomeSelected();
                } else if (index == 1) {
                  onRequestsSelected();
                }
              },
            ),
    );
  }
}
