import 'package:animated_emoji/animated_emoji.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/utils/colors.dart';
import 'theme_provider.dart';

class AppThemes {
  // Light Theme
  static ThemeData lightTheme = ThemeData(
    colorScheme: ColorScheme.light(
      primary: AppColors.lightPrimary,
      secondary: AppColors.lightSecondary,
      background: AppColors.lightBackground,
      surface: AppColors.lightCard,
      onPrimary: Colors.white,
      onSurface: AppColors.lightText,
    ),
    scaffoldBackgroundColor: AppColors.lightBackground,
    cardColor: AppColors.lightCard,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.lightPrimary,
      foregroundColor: Colors.white,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(
        color: AppColors.lightText,
      ),
      titleMedium: TextStyle(
        color: AppColors.lightText,
        fontWeight: FontWeight.w600,
      ),
    ),
    useMaterial3: true,
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    colorScheme: ColorScheme.dark(
      primary: AppColors.darkPrimary,
      secondary: AppColors.darkSecondary,
      background: AppColors.darkBackground,
      surface: AppColors.darkCard,
      onPrimary: Colors.white,
      onSurface: AppColors.darkText,
    ),
    scaffoldBackgroundColor: AppColors.darkBackground,
    cardColor: AppColors.darkCard,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.darkPrimary,
      foregroundColor: Colors.white,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(
        color: AppColors.darkText,
      ),
      titleMedium: TextStyle(
        color: AppColors.darkText,
        fontWeight: FontWeight.w600,
      ),
    ),
    useMaterial3: true,
  );
}

class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final notifier = ref.read(themeModeProvider.notifier);

    return IconButton(
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: themeMode == ThemeMode.dark
            ? const AnimatedEmoji(
              AnimatedEmojis.moonFaceFirstQuarter,
              size: 28,
              key: ValueKey('dark'),
              )
            : const AnimatedEmoji(
                AnimatedEmojis.sunWithFace,
                size: 30,
                key: ValueKey('light'),
              )
      ),
      tooltip: "Switch theme",
      onPressed: () => notifier.toggleTheme(),
    );
  }
}
