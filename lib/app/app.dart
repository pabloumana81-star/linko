import 'package:flutter/material.dart';
import 'package:linko/app/router.dart';
import 'package:linko/app/theme.dart';

class LinkoApp extends StatelessWidget {
  const LinkoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Linko',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
