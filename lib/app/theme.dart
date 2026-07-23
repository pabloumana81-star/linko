import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData get light {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
      scaffoldBackgroundColor: Colors.white,
      useMaterial3: true,
    );
  }
}
