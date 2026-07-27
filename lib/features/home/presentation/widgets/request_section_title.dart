import 'package:flutter/material.dart';

class RequestSectionTitle extends StatelessWidget {
  const RequestSectionTitle({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}
