import 'package:flutter/material.dart';

/// Dropdown control for changing the application theme mode.
class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({
    super.key,
    required this.themeMode,
    required this.onChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ThemeMode>(
          value: themeMode,
          isDense: true,
          icon: const Icon(Icons.expand_more),
          hint: const Text('Mode'),
          style: Theme.of(context).textTheme.labelLarge,
          borderRadius: BorderRadius.circular(8),
          items: const <DropdownMenuItem<ThemeMode>>[
            DropdownMenuItem<ThemeMode>(
              value: ThemeMode.system,
              child: Row(
                children: [
                  Icon(Icons.brightness_auto),
                  SizedBox(width: 8),
                  Text('System'),
                ],
              ),
            ),
            DropdownMenuItem<ThemeMode>(
              value: ThemeMode.dark,
              child: Row(
                children: [
                  Icon(Icons.dark_mode),
                  SizedBox(width: 8),
                  Text('Dark'),
                ],
              ),
            ),
            DropdownMenuItem<ThemeMode>(
              value: ThemeMode.light,
              child: Row(
                children: [
                  Icon(Icons.light_mode),
                  SizedBox(width: 8),
                  Text('Light'),
                ],
              ),
            ),
          ],
          onChanged: (ThemeMode? newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
        ),
      ),
    );
  }
}
