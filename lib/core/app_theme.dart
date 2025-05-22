import 'package:flutter/material.dart';

class AppThemes {
  // Your default (light) theme with custom blue accents
  static ThemeData lightTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF0B8FAC)), // Blue
    primaryColor: Color(0xFF0B8FAC),
    scaffoldBackgroundColor: Color(0xFFE5F1FA),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0B8FAC),
      foregroundColor: Colors.white,
    ),
    // You can add more: buttonTheme, textTheme, etc.
    useMaterial3: true,
  );

  // (Optional for later) Add a darkTheme as well
  static ThemeData darkTheme = ThemeData(
    colorScheme: ColorScheme.dark(
      primary: Color(0xFF0B8FAC),
      secondary: Color(0xFF7BC1B7),
    ),
    scaffoldBackgroundColor: Color(0xFF181D23),
    useMaterial3: true,
  );
}
