import 'package:flutter/material.dart';

class AppColors {
  // Light Theme Colors
  static const Color lightBackground = Color(0xFFE5F1FA);
  static const Color lightCard = Colors.white;
  static const Color lightPrimary = Color(0xFF0B8FAC);
  static const Color lightSecondary = Color(0xFF7BC1B7);
  static const Color lightText = Colors.black;
  static const Color lightSubtleText = Color(0xFF858585);

  // Dark Theme Colors
  // static const Color darkBackground = Color.fromARGB(255, 31, 41, 48); //old colour
  static const Color darkBackground = Color(0xFF303537); //#303537
  static const Color darkCard = Color(0xFF232526);
  static const Color darkPrimary = Color(0xFF189AB4);
  static const Color darkSecondary = Color(0xFF05445E);
  static const Color darkText = Colors.white;
  static const Color darkSubtleText = Color(0xFFCCCCCC);

}

Color bgColor(BuildContext context, {Color? custom}) {
  return custom ?? Theme.of(context).scaffoldBackgroundColor;
}

Color cardColor(BuildContext context, {Color? custom}) {
  return custom ?? Theme.of(context).cardColor;
}

Color textColor(BuildContext context, {Color? custom}) {
  return custom ?? Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
}

Color subtleTextColor(BuildContext context, {Color? custom}) {
  final brightness = Theme.of(context).brightness;
  return custom ??
      (brightness == Brightness.light
          ? AppColors.lightSubtleText
          : AppColors.darkSubtleText);
}
