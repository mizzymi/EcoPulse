import 'package:flutter/material.dart';

/// EcoPulse Theme (45 / 45 / 10)
/// - 90% grayscale: surfaces, text, outlines, containers
/// - 10% teal: primary actions, focus, selection, small highlights
///
/// Tips:
/// - Use teal only for: CTAs, FAB, active states, toggles, focused inputs.
/// - Keep cards/sheets neutral; let content + spacing do the work.
class T {
  // =========================
  // 45% LIGHT NEUTRALS
  // =========================
  static const n0 = Color(0xFFFAFAFA); // near-white
  static const n50 = Color(0xFFF4F4F5); // app background
  static const n100 = Color(0xFFEFEFF1); // surface
  static const n150 = Color(0xFFE7E7EA); // surface variant
  static const n200 = Color(0xFFDADAE0); // subtle borders/dividers

  // =========================
  // 45% DARK NEUTRALS
  // =========================
  static const n700 = Color(0xFF3F3F46); // secondary text
  static const n800 = Color(0xFF27272A); // main text
  static const n900 = Color(0xFF18181B); // strongest text/icons

  // =========================
  // 10% TEAL ACCENT (Brand)
  // =========================
  static const teal700 = Color(0xFF15727E); // primary action
  static const teal600 = Color(0xFF24878E); // pressed/hover
  static const teal200 = Color(0xFFBFE7E3); // subtle tint background (rare)
  static const teal100 = Color(0xFFE6F5F3); // very subtle tint (rare)

  // Quick aliases
  static const cPrimary = teal700;
  static const cBg = n50;
  static const cSurface = n100;
  static const cText = n900;

  /// Very subtle brand gradient (keep it rare: headers only).
  /// Note: This stays grayscale-dominant by using a neutral-to-teal fade.
  static const header = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [n100, teal100, teal200],
    stops: [0.0, 0.6, 1.0],
  );

  /// Neutral "glass" surface: grayscale first, teal only as a thin focus outline when needed.
  static BoxDecoration glass({double r = 20}) => BoxDecoration(
        color: n100,
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: n200, width: 1),
      );
}

class AppTheme {
  static final light = (() {
    // Start from a neutral seed so Material defaults don't flood teal everywhere.
    final base = ColorScheme.fromSeed(
      seedColor: T.n700,
      brightness: Brightness.light,
    );

    // Then explicitly place teal only where it should live: primary + a few accents.
    final scheme = base.copyWith(
      // Brand (10%)
      primary: T.teal700,
      onPrimary: Colors.white,
      primaryContainer: T.teal600,
      onPrimaryContainer: Colors.white,

      // Secondary stays neutral to respect 45/45/10
      secondary: T.n800,
      onSecondary: Colors.white,
      secondaryContainer: T.n150,
      onSecondaryContainer: T.n900,

      // Tertiary kept neutral-ish; avoid extra “color category”
      tertiary: T.n700,
      onTertiary: Colors.white,
      tertiaryContainer: T.n150,
      onTertiaryContainer: T.n900,

      // Surfaces (grayscale 90%)
      background: T.n50,
      onBackground: T.n900,

      surface: T.n100,
      onSurface: T.n900,

      surfaceVariant: T.n150,
      onSurfaceVariant: T.n800,

      // Outlines/dividers (neutral)
      outline: T.n200,
      outlineVariant: T.n150,

      // Error can remain default red; it’s functional, not “brand color usage”
      error: base.error,
      onError: base.onError,
      errorContainer: base.errorContainer,
      onErrorContainer: base.onErrorContainer,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: T.n50,

      // Fonts
      fontFamily: 'Lucida Sans Unicode',
      textTheme: const TextTheme(
        // Headlines in Impact
        displayLarge: TextStyle(fontFamily: 'Impact', height: .94),
        displayMedium:
            TextStyle(fontFamily: 'Impact', height: .95, letterSpacing: .2),
        displaySmall:
            TextStyle(fontFamily: 'Impact', height: .96, letterSpacing: .2),
        headlineLarge:
            TextStyle(fontFamily: 'Impact', height: .95, letterSpacing: .2),
        headlineMedium:
            TextStyle(fontFamily: 'Impact', height: .96, letterSpacing: .2),
        headlineSmall:
            TextStyle(fontFamily: 'Impact', height: .98, letterSpacing: .2),

        // Body/UI in Lucida
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
        bodyColor: T.n900,
        displayColor: T.n900,
      ),

      iconTheme: IconThemeData(color: scheme.onSurface),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: T.n900,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: T.n900),
        titleTextStyle: const TextStyle(
          fontFamily: 'Impact',
          color: T.n900,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          height: .96,
        ),
        surfaceTintColor: Colors.transparent,
      ),

      // Inputs: neutral surface, teal only on focus
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: T.n100,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: T.n200, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: T.teal700, width: 1.6),
        ),
      ),

      // Buttons: teal for primary action, neutrals elsewhere
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.disabled)) return T.n200;
            if (states.contains(MaterialState.pressed) ||
                states.contains(MaterialState.hovered)) {
              return T.teal600;
            }
            return T.teal700;
          }),
          foregroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.disabled)) return T.n700;
            return Colors.white;
          }),
          padding: MaterialStateProperty.all(
              const EdgeInsets.symmetric(vertical: 14, horizontal: 18)),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          elevation: MaterialStateProperty.all(0),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: T.teal700,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),

      // Text buttons: teal for “link/action” is ok (still within 10% if used carefully)
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: T.teal700,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: T.teal700),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: T.teal700,
        foregroundColor: Colors.white,
        extendedTextStyle:
            TextStyle(fontFamily: 'Impact', fontWeight: FontWeight.w700),
      ),

      listTileTheme: ListTileThemeData(
        textColor: scheme.onSurface,
        iconColor: scheme.onSurface,
      ),

      expansionTileTheme: const ExpansionTileThemeData(
        textColor: T.n900,
        iconColor: T.teal700,
        collapsedTextColor: T.n900,
        collapsedIconColor: T.teal700,
      ),

      popupMenuTheme: PopupMenuThemeData(
        textStyle:
            TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 6,
      ),

      // Chips: default neutral; use teal only for "selected" or "status"
      chipTheme: ChipThemeData(
        backgroundColor: T.n150,
        selectedColor: T.teal200, // subtle teal tint when selected
        labelStyle: const TextStyle(color: T.n900, fontWeight: FontWeight.w600),
        side: const BorderSide(color: T.n200),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Keep surfaces crisp (no Material tinting)
      cardTheme: const CardThemeData(
        surfaceTintColor: Colors.transparent,
        color: T.n100,
      ),
      dialogTheme: const DialogThemeData(surfaceTintColor: Colors.transparent),
      bottomSheetTheme: const BottomSheetThemeData(
        surfaceTintColor: Colors.transparent,
        backgroundColor: T.n100,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // Dividers and separators: neutral
      dividerTheme: const DividerThemeData(
        color: T.n200,
        thickness: 1,
        space: 24,
      ),
    );
  })();
}
