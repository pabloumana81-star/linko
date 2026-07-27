import 'package:flutter/material.dart';

class FilterChipWidget extends StatelessWidget {
  const FilterChipWidget({
    required this.label,
    required this.onPressed,
    this.selected = false,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onPressed(),
    );
  }
}
