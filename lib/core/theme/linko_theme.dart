import 'package:flutter/material.dart';
import 'package:linko/core/theme/linko_colors.dart';

abstract final class LinkoTheme {
  static const _fontFamily = 'Inter';

  static const ColorScheme _colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: LinkoColors.primary,
    onPrimary: LinkoColors.surface,
    primaryContainer: LinkoColors.primaryLight,
    onPrimaryContainer: LinkoColors.primaryDark,
    secondary: LinkoColors.primaryDark,
    onSecondary: LinkoColors.surface,
    secondaryContainer: LinkoColors.primaryLight,
    onSecondaryContainer: LinkoColors.primaryDark,
    tertiary: LinkoColors.success,
    onTertiary: LinkoColors.surface,
    error: LinkoColors.error,
    onError: LinkoColors.surface,
    surface: LinkoColors.surface,
    onSurface: LinkoColors.textPrimary,
    surfaceContainerLowest: LinkoColors.surface,
    surfaceContainerLow: LinkoColors.background,
    surfaceContainer: LinkoColors.background,
    surfaceContainerHigh: LinkoColors.border,
    surfaceContainerHighest: LinkoColors.border,
    onSurfaceVariant: LinkoColors.textSecondary,
    outline: LinkoColors.border,
    outlineVariant: LinkoColors.border,
    shadow: LinkoColors.shadow,
    scrim: LinkoColors.textPrimary,
    inverseSurface: LinkoColors.textPrimary,
    onInverseSurface: LinkoColors.surface,
    inversePrimary: LinkoColors.primaryLight,
  );

  static TextStyle _textStyle({
    required double size,
    required FontWeight weight,
    required Color color,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: _fontFamily,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static final TextTheme _textTheme = TextTheme(
    displayLarge: _textStyle(
      size: 57,
      weight: FontWeight.w400,
      color: LinkoColors.textPrimary,
    ),
    displayMedium: _textStyle(
      size: 45,
      weight: FontWeight.w400,
      color: LinkoColors.textPrimary,
    ),
    displaySmall: _textStyle(
      size: 36,
      weight: FontWeight.w400,
      color: LinkoColors.textPrimary,
    ),
    headlineLarge: _textStyle(
      size: 32,
      weight: FontWeight.w600,
      color: LinkoColors.textPrimary,
    ),
    headlineMedium: _textStyle(
      size: 28,
      weight: FontWeight.w600,
      color: LinkoColors.textPrimary,
    ),
    headlineSmall: _textStyle(
      size: 24,
      weight: FontWeight.w600,
      color: LinkoColors.textPrimary,
    ),
    titleLarge: _textStyle(
      size: 22,
      weight: FontWeight.w600,
      color: LinkoColors.textPrimary,
    ),
    titleMedium: _textStyle(
      size: 16,
      weight: FontWeight.w500,
      color: LinkoColors.textPrimary,
    ),
    titleSmall: _textStyle(
      size: 14,
      weight: FontWeight.w500,
      color: LinkoColors.textPrimary,
    ),
    bodyLarge: _textStyle(
      size: 16,
      weight: FontWeight.w400,
      color: LinkoColors.textPrimary,
    ),
    bodyMedium: _textStyle(
      size: 14,
      weight: FontWeight.w400,
      color: LinkoColors.textPrimary,
    ),
    bodySmall: _textStyle(
      size: 12,
      weight: FontWeight.w400,
      color: LinkoColors.textSecondary,
    ),
    labelLarge: _textStyle(
      size: 14,
      weight: FontWeight.w600,
      color: LinkoColors.textPrimary,
    ),
    labelMedium: _textStyle(
      size: 12,
      weight: FontWeight.w600,
      color: LinkoColors.textPrimary,
    ),
    labelSmall: _textStyle(
      size: 11,
      weight: FontWeight.w600,
      color: LinkoColors.textSecondary,
    ),
  );

  static ThemeData get light {
    const buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    );
    const cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(20)),
      side: BorderSide(color: LinkoColors.border),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: _fontFamily,
      colorScheme: _colorScheme,
      scaffoldBackgroundColor: LinkoColors.background,
      textTheme: _textTheme,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 52),
          backgroundColor: LinkoColors.primary,
          foregroundColor: LinkoColors.surface,
          disabledBackgroundColor: LinkoColors.border,
          disabledForegroundColor: LinkoColors.textSecondary,
          elevation: 0,
          shape: buttonShape,
          textStyle: _textTheme.labelLarge,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          backgroundColor: LinkoColors.primary,
          foregroundColor: LinkoColors.surface,
          disabledBackgroundColor: LinkoColors.border,
          disabledForegroundColor: LinkoColors.textSecondary,
          shape: buttonShape,
          textStyle: _textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          foregroundColor: LinkoColors.primaryDark,
          side: const BorderSide(color: LinkoColors.border),
          shape: buttonShape,
          textStyle: _textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: LinkoColors.surface,
        contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: TextStyle(
          fontFamily: _fontFamily,
          color: LinkoColors.textSecondary,
        ),
        labelStyle: TextStyle(
          fontFamily: _fontFamily,
          color: LinkoColors.textSecondary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: LinkoColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: LinkoColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: LinkoColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: LinkoColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: LinkoColors.error, width: 1.5),
        ),
      ),
      cardTheme: const CardThemeData(
        color: LinkoColors.surface,
        surfaceTintColor: LinkoColors.transparent,
        elevation: 0,
        margin: EdgeInsets.all(4),
        shape: cardShape,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: LinkoColors.surface,
        selectedColor: LinkoColors.primaryLight,
        disabledColor: LinkoColors.background,
        side: const BorderSide(color: LinkoColors.border),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(999)),
        ),
        labelStyle: _textTheme.labelLarge!,
        secondaryLabelStyle: _textTheme.labelLarge!.copyWith(
          color: LinkoColors.primaryDark,
        ),
        iconTheme: const IconThemeData(color: LinkoColors.primaryDark),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: LinkoColors.surface,
        foregroundColor: LinkoColors.textPrimary,
        surfaceTintColor: LinkoColors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: _textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: LinkoColors.surface,
        selectedItemColor: LinkoColors.primary,
        unselectedItemColor: LinkoColors.textSecondary,
        selectedLabelStyle: _textTheme.labelMedium,
        unselectedLabelStyle: _textTheme.labelMedium,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: LinkoColors.surface,
        indicatorColor: LinkoColors.primaryLight.withValues(alpha: 0.55),
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? LinkoColors.primary
                : LinkoColors.textSecondary,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return _textTheme.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected)
                ? LinkoColors.primary
                : LinkoColors.textSecondary,
          );
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: LinkoColors.border,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
