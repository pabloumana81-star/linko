import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linko/core/backend/backend_config.dart';
import 'package:linko/core/backend/backend_providers.dart';
import 'package:linko/core/theme/linko_theme.dart';
import 'package:linko_admin/app/admin_router.dart';
import 'package:go_router/go_router.dart';

class LinkoAdminApp extends StatelessWidget {
  const LinkoAdminApp({this.router, super.key});

  final RouterConfig<Object>? router;

  @override
  Widget build(BuildContext context) {
    final effectiveRouter = router ?? adminRouter;
    return MaterialApp.router(
      title: 'LinkO Admin',
      debugShowCheckedModeBanner: false,
      theme: LinkoTheme.light,
      locale: const Locale('es', 'CR'),
      supportedLocales: const [Locale('es', 'CR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: effectiveRouter,
      builder: (context, child) => kDebugMode
          ? Consumer(
              builder: (context, ref, _) => Stack(
                children: [
                  child ?? const SizedBox.shrink(),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _BackendBadge(
                      mode: ref.watch(backendConfigProvider).mode,
                      onTap: () {
                        if (effectiveRouter is GoRouter) {
                          effectiveRouter.go(AdminRoutes.diagnostics);
                        }
                      },
                    ),
                  ),
                ],
              ),
            )
          : child ?? const SizedBox.shrink(),
    );
  }
}

class _BackendBadge extends StatelessWidget {
  const _BackendBadge({required this.mode, required this.onTap});

  final BackendMode mode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    key: const ValueKey('admin-backend-indicator'),
    color: mode == BackendMode.supabase
        ? Colors.green.shade800
        : Colors.orange.shade900,
    borderRadius: BorderRadius.circular(8),
    elevation: 3,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          'Backend\n${mode == BackendMode.supabase ? 'SUPABASE' : 'MOCK'}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ),
  );
}
