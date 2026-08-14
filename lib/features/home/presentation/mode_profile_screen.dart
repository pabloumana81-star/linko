import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko/app/app_mode.dart';
import 'package:linko/features/auth/domain/models/app_user_profile.dart';
import 'package:linko/features/auth/presentation/auth_controller.dart';
import 'package:linko/features/home/presentation/providers/customer_profile_provider.dart';
import 'package:linko/features/home/presentation/widgets/bottom_navigation_widget.dart';
import 'package:linko/features/home/presentation/widgets/professional_bottom_navigation_widget.dart';
import 'package:linko/features/home/presentation/professional_profile_editor.dart';

class ModeProfileScreen extends ConsumerStatefulWidget {
  const ModeProfileScreen({
    required this.mode,
    required this.onChangeMode,
    required this.onHomeSelected,
    required this.onRequestsSelected,
    this.onSearchSelected,
    this.onSignOut,
    this.profileSnapshot,
    super.key,
  });

  final AppMode mode;
  final VoidCallback onChangeMode;
  final VoidCallback onHomeSelected;
  final VoidCallback onRequestsSelected;
  final VoidCallback? onSearchSelected;
  final VoidCallback? onSignOut;
  final AppUserProfile? profileSnapshot;

  @override
  ConsumerState<ModeProfileScreen> createState() => _ModeProfileScreenState();
}

class _ModeProfileScreenState extends ConsumerState<ModeProfileScreen>
    with WidgetsBindingObserver {
  AppUserProfile? _lastProfile;

  @override
  void initState() {
    super.initState();
    _lastProfile = widget.profileSnapshot;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.mode == AppMode.customer) {
      ref.invalidate(customerProfileProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCustomer = widget.mode == AppMode.customer;
    final authProfile =
        widget.profileSnapshot ?? ref.watch(authControllerProvider).user;
    if (authProfile != null && _lastProfile?.id != authProfile.id) {
      _lastProfile = authProfile;
    }
    AppUserProfile? profile = _lastProfile ?? authProfile;
    if (isCustomer && authProfile != null) {
      final profileState = ref.watch(customerProfileProvider);
      if (profileState.hasError) {
        return _CustomerProfileStateScreen(
          message: 'No pudimos cargar tu perfil.',
          actionLabel: 'Reintentar',
          onAction: () => ref.invalidate(customerProfileProvider),
          onNavigate: widget.onHomeSelected,
        );
      }
      if (profileState.hasValue) {
        profile = profileState.value;
        if (profile == null) {
          return _CustomerProfileStateScreen(
            message: 'No encontramos tu perfil de cliente.',
            onNavigate: widget.onHomeSelected,
          );
        }
        _lastProfile = profile;
      } else if (profile == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
    }
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
                        onPressed: widget.onChangeMode,
                        child: Text(
                          isCustomer
                              ? 'Cambiar a profesional'
                              : 'Cambiar a cliente',
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isCustomer) ...[
                  const SizedBox(height: 28),
                  const ProfessionalProfileEditor(),
                ],
                if (widget.onSignOut != null) ...[
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    key: const ValueKey('auth-sign-out'),
                    onPressed: widget.onSignOut,
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
                  widget.onHomeSelected();
                } else if (index == 1) {
                  widget.onSearchSelected?.call();
                } else if (index == 2) {
                  widget.onRequestsSelected();
                }
              },
            )
          : ProfessionalBottomNavigationWidget(
              selectedIndex: 3,
              onDestinationSelected: (index) {
                if (index == 0) {
                  widget.onHomeSelected();
                } else if (index == 1) {
                  widget.onRequestsSelected();
                }
              },
            ),
    );
  }
}

class _CustomerProfileStateScreen extends StatelessWidget {
  const _CustomerProfileStateScreen({
    required this.message,
    required this.onNavigate,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Perfil')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
            const SizedBox(height: 8),
            TextButton(
              onPressed: onNavigate,
              child: const Text('Volver al inicio'),
            ),
          ],
        ),
      ),
    ),
  );
}
