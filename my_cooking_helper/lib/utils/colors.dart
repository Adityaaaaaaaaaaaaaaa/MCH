import 'package:flutter/material.dart';

/// All project color constants.
class AppColors {
  // Light Theme Colors
  static const Color lightBackground = Color(0xFFE5F1FA);
  static const Color lightCard = Colors.white;
  static const Color lightPrimary = Color(0xFF0B8FAC);
  static const Color lightSecondary = Color(0xFF7BC1B7);
  static const Color lightText = Colors.black;
  static const Color lightSubtleText = Color(0xFF858585);

  // Dark Theme Colors
  static const Color darkBackground = Color.fromARGB(255, 31, 41, 48);
  static const Color darkCard = Color(0xFF232526);
  static const Color darkPrimary = Color(0xFF189AB4);
  static const Color darkSecondary = Color(0xFF05445E);
  static const Color darkText = Colors.white;
  static const Color darkSubtleText = Color(0xFFCCCCCC);

  // Accent and custom colors
  static const Color accentOrange = Color(0xFFFF785A);
  static const Color accentIndigo = Color(0xFF3A86FF);
  // ...add more as needed
}

/// Helper to get the correct background color
Color bgColor(BuildContext context, {Color? custom}) {
  return custom ?? Theme.of(context).scaffoldBackgroundColor;
}

/// Helper to get the correct card color
Color cardColor(BuildContext context, {Color? custom}) {
  return custom ?? Theme.of(context).cardColor;
}

/// Helper to get the correct primary text color
Color textColor(BuildContext context, {Color? custom}) {
  return custom ?? Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
}

/// Helper to get subtle (secondary) text color
Color subtleTextColor(BuildContext context, {Color? custom}) {
  final brightness = Theme.of(context).brightness;
  return custom ??
      (brightness == Brightness.light
          ? AppColors.lightSubtleText
          : AppColors.darkSubtleText);
}
