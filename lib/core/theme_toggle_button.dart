import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme_provider.dart';

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
