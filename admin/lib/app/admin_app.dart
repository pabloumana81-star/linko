import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:linko/core/theme/linko_theme.dart';
import 'package:linko_admin/app/admin_router.dart';

class LinkoAdminApp extends StatelessWidget {
  const LinkoAdminApp({this.router, super.key});

  final RouterConfig<Object>? router;

  @override
  Widget build(BuildContext context) {
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
      routerConfig: router ?? adminRouter,
    );
  }
}
