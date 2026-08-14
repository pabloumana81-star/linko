import 'package:flutter/material.dart';

class LabeledLoadingIndicator extends StatelessWidget {
  const LabeledLoadingIndicator({this.label = 'Cargando…', super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 12),
        Text(label, textAlign: TextAlign.center),
      ],
    ),
  );
}
