import 'package:flutter/material.dart';

class T {
  static const cPrimary = Colors.green;
  static const cSecondary = Colors.lightGreen;
  static const cBg = Color(0xFFEAF8E5);
  static const cText = Colors.black;

  static const header = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cPrimary, cSecondary],
  );

  static BoxDecoration glass({double r = 20}) => BoxDecoration(
    borderRadius: BorderRadius.circular(r),
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFEAF8E5), Color(0xFFEAF8E5)],
    ),
    border: Border.all(color: Colors.green),
  );
}

class AppTheme {
  static final light = (() {
    final base = ColorScheme.fromSeed(
      seedColor: T.cPrimary,
      brightness: Brightness.light,
    );

    final scheme = base.copyWith(
      primary: T.cPrimary,
      secondary: T.cSecondary,
      tertiary: T.cSecondary,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onTertiary: Colors.black,
      surface: Colors.green[50],
      onSurface: Colors.black, // Texto principal oscuro
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: T.cBg,

      // Colores fuertes en iconos por defecto
      iconTheme: IconThemeData(color: scheme.primary),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.green[900],
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.green[900]),
        titleTextStyle: TextStyle(
          color: Colors.green[900],
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        surfaceTintColor: Colors.transparent,
      ),

      textTheme: const TextTheme(
        titleLarge: TextStyle(fontWeight: FontWeight.w700, letterSpacing: .2),
        labelLarge: TextStyle(fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(letterSpacing: .15),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(.9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: scheme.primary),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        extendedTextStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),

      listTileTheme: ListTileThemeData(
        textColor: scheme.onSurface,
        iconColor: scheme.onSurface,
      ),

      expansionTileTheme: ExpansionTileThemeData(
        textColor: scheme.onSurface,
        iconColor: scheme.primary,
        collapsedTextColor: scheme.onSurface,
        collapsedIconColor: scheme.primary,
      ),

      popupMenuTheme: PopupMenuThemeData(
        textStyle: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 6,
      ),

      // Quita el tinte “material” en superficies para no apagar colores
      cardTheme: const CardThemeData(surfaceTintColor: Colors.transparent),
      dialogTheme: const DialogThemeData(surfaceTintColor: Colors.transparent),
      bottomSheetTheme: const BottomSheetThemeData(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  })();
}
