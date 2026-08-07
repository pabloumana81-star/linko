import 'package:flutter/material.dart';
import 'package:linko/core/backend/backend_config.dart';
import 'package:linko/core/theme/linko_theme.dart';

class BackendFailureApp extends StatelessWidget {
  const BackendFailureApp({super.key, this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: LinkoTheme.light,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'No fue posible iniciar la conexión con el backend.\n'
                    'Revisa la configuración del entorno e intenta nuevamente.',
                    textAlign: TextAlign.center,
                  ),
                  if (error case BackendConfigurationException(:final message))
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(message, textAlign: TextAlign.center),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
