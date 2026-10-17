import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const cream = Color(0xFFFFFDF7);
  static const green = Color(0xFF23764B);
  static const greenSoft = Color(0xFFE6F3E9);
  static const orange = Color(0xFFFF8A3D);
  static const orangeSoft = Color(0xFFFFF0E4);
  static const ink = Color(0xFF20291F);
  static const mutedInk = Color(0xFF687267);
  static const border = Color(0xFFE7EADF);

  static const space8 = 8.0;
  static const space12 = 12.0;
  static const space16 = 16.0;
  static const space20 = 20.0;
  static const space24 = 24.0;
  static const space32 = 32.0;

  static const radius16 = 16.0;
  static const radius22 = 22.0;
  static const radius24 = 24.0;

  static ThemeData deckListTheme(ThemeData base) {
    final colors = ColorScheme.fromSeed(
      seedColor: green,
      brightness: Brightness.light,
      surface: cream,
    ).copyWith(
      primary: green,
      onPrimary: Colors.white,
      secondary: orange,
      onSurface: ink,
      onSurfaceVariant: mutedInk,
      outline: border,
      primaryContainer: greenSoft,
      onPrimaryContainer: green,
      secondaryContainer: orangeSoft,
      onSecondaryContainer: ink,
    );

    return base.copyWith(
      colorScheme: colors,
      scaffoldBackgroundColor: cream,
      appBarTheme: const AppBarTheme(
        backgroundColor: cream,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius16),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius16),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius16),
          borderSide: const BorderSide(color: green, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius16),
          borderSide: const BorderSide(color: Color(0xFFB3261E)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius16),
          borderSide: const BorderSide(color: Color(0xFFB3261E), width: 1.5),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cream,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius24),
        ),
      ),
      textTheme: base.textTheme.copyWith(
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          color: ink,
          fontSize: 30,
          fontWeight: FontWeight.w800,
          height: 1.2,
        ),
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          color: ink,
          fontWeight: FontWeight.w800,
          height: 1.2,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          color: ink,
          fontWeight: FontWeight.w800,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          color: ink,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(
          color: mutedInk,
          height: 1.45,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          color: mutedInk,
          height: 1.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius22),
          side: const BorderSide(color: border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: green,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: space16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: green,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: green,
          minimumSize: const Size(48, 48),
        ),
      ),
    );
  }
}
