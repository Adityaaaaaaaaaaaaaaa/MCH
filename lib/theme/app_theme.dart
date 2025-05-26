import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme_provider.dart';

class AppThemes {
  // Light theme (already beautiful!)
  static ThemeData lightTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF0B8FAC)),
    scaffoldBackgroundColor: Color(0xFFE5F1FA),
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF0B8FAC),
      foregroundColor: Colors.white,
    ),
    useMaterial3: true,
  );

  // Smooth, modern dark theme (not harsh black)
  static ThemeData darkTheme = ThemeData(
    colorScheme: ColorScheme.dark(
      primary: Color(0xFF189AB4),      // Bright blue for highlights
      secondary: Color(0xFF05445E),    // Navy blue
      background: Color(0xFF102B3F),   // Deep blue-gray for backgrounds
      surface: Color(0xFF243B53),      // Slightly lighter for cards
      onPrimary: Colors.white,
      onSurface: Colors.white,
    ),
    scaffoldBackgroundColor: Color(0xFF102B3F),
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF05445E),
      foregroundColor: Colors.white,
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
        duration: Duration(milliseconds: 300),
        child: themeMode == ThemeMode.dark
            ? Icon(Icons.nights_stay, color: Colors.amber, key: ValueKey('dark'))
            : Icon(Icons.wb_sunny, color: Colors.blueAccent, key: ValueKey('light')),
      ),
      tooltip: "Switch theme",
      onPressed: () => notifier.toggleTheme(),
    );
  }
}
