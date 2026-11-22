import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider managing active ThemeMode (light, dark, system).
final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void setThemeMode(ThemeMode mode) {
    state = mode;
  }

  void toggleTheme() {
    if (state == ThemeMode.light) {
      state = ThemeMode.dark;
    } else if (state == ThemeMode.dark) {
      state = ThemeMode.system;
    } else {
      state = ThemeMode.light;
    }
  }
}

/// Compact, elegant theme mode switcher control for app bars and navigation headers.
class ThemeModeSelector extends ConsumerWidget {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);

    return PopupMenuButton<ThemeMode>(
      tooltip: 'Select Theme Mode',
      icon: Icon(
        mode == ThemeMode.dark
            ? Icons.dark_mode_outlined
            : (mode == ThemeMode.light
                ? Icons.light_mode_outlined
                : Icons.brightness_auto_outlined),
        size: 20,
      ),
      initialValue: mode,
      onSelected: (newMode) =>
          ref.read(themeModeProvider.notifier).setThemeMode(newMode),
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: ThemeMode.system,
          child: Row(
            children: [
              Icon(Icons.brightness_auto_outlined, size: 18),
              SizedBox(width: 10),
              Text('System Preference'),
            ],
          ),
        ),
        PopupMenuItem(
          value: ThemeMode.light,
          child: Row(
            children: [
              Icon(Icons.light_mode_outlined, size: 18),
              SizedBox(width: 10),
              Text('Light Theme'),
            ],
          ),
        ),
        PopupMenuItem(
          value: ThemeMode.dark,
          child: Row(
            children: [
              Icon(Icons.dark_mode_outlined, size: 18),
              SizedBox(width: 10),
              Text('Dark Theme'),
            ],
          ),
        ),
      ],
    );
  }
}
