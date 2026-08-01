import 'package:flutter/material.dart';
import 'package:linko/core/theme/linko_theme.dart';

class BackendFailureApp extends StatelessWidget {
  const BackendFailureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: LinkoTheme.light,
      home: const Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No fue posible iniciar la conexión con el backend.\n'
                'Revisa la configuración del entorno e intenta nuevamente.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
