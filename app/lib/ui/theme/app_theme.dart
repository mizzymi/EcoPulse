import 'package:flutter/material.dart';

class T {
  // === Reimii Palette ===
  static const deepTeal = Color(0xFF0A4358); // Text & structural base
  static const teal700  = Color(0xFF15727E); // Primary action
  static const teal600  = Color(0xFF24878E); // Pressed / hover
  static const teal500  = Color(0xFF309A9E); // Bridges / hierarchy
  static const aqua400  = Color(0xFF35B8B2); // Highlights / positive
  static const ice100   = Color(0xFFC1E4EE); // Light surface

  static const cPrimary   = teal700;
  static const cSecondary = teal600;
  static const cBg        = ice100;
  static const cText      = deepTeal;

  // Gradiente de marca (wordmark): Aqua → Teal500 → DeepTeal
  static const header = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [aqua400, teal500, deepTeal],
    stops: [0.0, 0.55, 1.0],
  );

  // Panel “glass” alineado a la guía: superficies Ice con trazo Deep Teal
  static BoxDecoration glass({double r = 20}) => BoxDecoration(
    color: ice100,
    borderRadius: BorderRadius.circular(r),
    border: Border.all(color: deepTeal, width: 1.5),
  );
}

class AppTheme {
  static final light = (() {
    final base = ColorScheme.fromSeed(
      seedColor: T.teal700,
      brightness: Brightness.light,
    );

    final scheme = base.copyWith(
      primary: T.teal700,
      onPrimary: Colors.white,
      primaryContainer: T.teal600,

      secondary: T.deepTeal,
      onSecondary: Colors.white,

      tertiary: T.aqua400,
      onTertiary: T.deepTeal,

      surface: T.ice100,
      onSurface: T.deepTeal,

      outline: T.deepTeal,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: T.cBg,

      // Tipografías de marca
      fontFamily: 'Lucida Sans Unicode',
      textTheme: const TextTheme(
        // Titulares Impact (compactos y decididos)
        displayLarge: TextStyle(fontFamily: 'Impact', height: .94),
        displayMedium: TextStyle(fontFamily: 'Impact', height: .95, letterSpacing: .2),
        displaySmall: TextStyle(fontFamily: 'Impact', height: .96, letterSpacing: .2),
        headlineLarge: TextStyle(fontFamily: 'Impact', height: .95, letterSpacing: .2),
        headlineMedium: TextStyle(fontFamily: 'Impact', height: .96, letterSpacing: .2),
        headlineSmall: TextStyle(fontFamily: 'Impact', height: .98, letterSpacing: .2),

        // Cuerpo y UI en Lucida Sans Unicode
        titleLarge: TextStyle(fontWeight: FontWeight.w700, letterSpacing: .2),
        titleMedium: TextStyle(fontWeight: FontWeight.w600),
        titleSmall: TextStyle(fontWeight: FontWeight.w600),

        bodyLarge: TextStyle(height: 1.5, letterSpacing: .15),
        bodyMedium: TextStyle(height: 1.5, letterSpacing: .15),
        bodySmall: TextStyle(height: 1.45, letterSpacing: .1),

        labelLarge: TextStyle(fontWeight: FontWeight.w600),
        labelMedium: TextStyle(fontWeight: FontWeight.w600),
        labelSmall: TextStyle(fontWeight: FontWeight.w600),
      ).apply(
        bodyColor: T.cText,
        displayColor: T.cText,
      ),

      iconTheme: IconThemeData(color: scheme.primary),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: T.deepTeal,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: T.deepTeal),
        titleTextStyle: const TextStyle(
          fontFamily: 'Impact',
          color: T.deepTeal,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          height: .96,
        ),
        surfaceTintColor: Colors.transparent,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: T.ice100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: T.deepTeal, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: T.teal700, width: 1.5),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.pressed) || states.contains(MaterialState.hovered)) {
              return scheme.primaryContainer; // Teal600 feedback
            }
            return scheme.primary; // Teal700 por defecto
          }),
          foregroundColor: MaterialStateProperty.all(scheme.onPrimary),
          padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 14, horizontal: 18)),
          shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
          elevation: MaterialStateProperty.all(0),
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
          foregroundColor: scheme.secondary, // DeepTeal
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: scheme.primary),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        extendedTextStyle: const TextStyle(fontFamily: 'Impact', fontWeight: FontWeight.w700),
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

      chipTheme: ChipThemeData(
        backgroundColor: T.aqua400, // success/info chips
        labelStyle: const TextStyle(color: T.deepTeal, fontWeight: FontWeight.w600),
        side: const BorderSide(color: Colors.transparent),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Superficies sin tintado para mantener el look nítido
      cardTheme: const CardThemeData(surfaceTintColor: Colors.transparent),
      dialogTheme: const DialogThemeData(surfaceTintColor: Colors.transparent),
      bottomSheetTheme: const BottomSheetThemeData(
        surfaceTintColor: Colors.transparent,
        backgroundColor: T.ice100,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  })();
}
