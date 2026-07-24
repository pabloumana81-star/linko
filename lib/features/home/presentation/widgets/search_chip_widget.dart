import 'package:flutter/material.dart';

class SearchChipWidget extends StatelessWidget {
  const SearchChipWidget({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: const Icon(Icons.search_rounded, size: 18),
      label: Text(label),
      onPressed: onPressed,
    );
  }
}
