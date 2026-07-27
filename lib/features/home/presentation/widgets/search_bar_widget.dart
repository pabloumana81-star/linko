import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({
    this.hintText = 'Buscar un servicio...',
    this.autofocus = false,
    this.readOnly = false,
    this.onTap,
    super.key,
  });

  final String hintText;
  final bool autofocus;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: TextField(
        autofocus: autofocus,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: Icon(Icons.search_rounded),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 60),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainer,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
