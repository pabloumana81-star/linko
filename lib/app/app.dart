import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko/app/app_mode.dart';
import 'package:linko/app/app_mode_provider.dart';
import 'package:linko/app/router.dart';
import 'package:linko/core/backend/backend_config.dart';
import 'package:linko/core/backend/backend_providers.dart';
import 'package:linko/core/diagnostics/debug_diagnostics_overlay.dart';
import 'package:linko/core/theme/linko_theme.dart';
import 'package:linko/features/auth/presentation/auth_controller.dart';

class LinkoApp extends ConsumerWidget {
  const LinkoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authControllerProvider, (previous, next) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final location = appRouter.routeInformationProvider.value.uri.path;
        if (next.status == AuthStatus.unauthenticated &&
            (ref.read(backendRepositoriesProvider).mode ==
                    BackendMode.supabase ||
                previous?.status == AuthStatus.authenticated ||
                previous?.status == AuthStatus.suspended) &&
            location != AppRoutes.splash &&
            location != AppRoutes.welcome) {
          appRouter.go(AppRoutes.welcome);
          return;
        }
        if (next.status != AuthStatus.authenticated) return;
        if (next.user?.onboardingCompleted == false) {
          if (location != AppRoutes.userType) appRouter.go(AppRoutes.userType);
          return;
        }
        if (location == AppRoutes.welcome || location == AppRoutes.userType) {
          final mode = next.user?.activeMode ?? AppMode.customer;
          ref.read(appModeProvider.notifier).select(mode);
          appRouter.go(
            mode == AppMode.customer
                ? AppRoutes.guestHome
                : AppRoutes.professionalHome,
          );
        }
      });
    });
    return MaterialApp.router(
      title: 'LinkO',
      debugShowCheckedModeBanner: false,
      theme: LinkoTheme.light,
      locale: const Locale('es', 'CR'),
      supportedLocales: const [Locale('es', 'CR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: appRouter,
      builder: (context, child) =>
          DebugDiagnosticsOverlay(child: child ?? const SizedBox.shrink()),
    );
  }
}
