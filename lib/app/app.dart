import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:linko/app/router.dart';
import 'package:linko/core/theme/linko_theme.dart';

class LinkoApp extends StatelessWidget {
  const LinkoApp({super.key});

  @override
  Widget build(BuildContext context) {
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
    );
  }
}
