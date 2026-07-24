import 'package:flutter/material.dart';

class ServiceChip extends StatelessWidget {
  const ServiceChip({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        Icons.check_rounded,
        size: 18,
        color: Theme.of(context).colorScheme.primary,
      ),
      label: Text(label),
    );
  }
}
