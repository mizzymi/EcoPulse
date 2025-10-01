import 'package:flutter/material.dart';

class T {
  static const cPrimary = Color.fromARGB(255, 52, 121, 86);
  static const cSecondary = Color.fromARGB(255, 98, 202, 188);
  static const cBg = Color(0xFFEFF8FF);
  static const cText = Color(0xFF0D1B2A);

  static const header = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cPrimary, cSecondary],
  );

  static BoxDecoration glass({double r = 20}) => BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(.35),
            Colors.white.withOpacity(.15)
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(.35)),
      );
}

class AppTheme {
  static final light = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: T.cBg,
    colorScheme: ColorScheme.fromSeed(seedColor: T.cPrimary),
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
          borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 0,
      ),
    ),
  );
}
