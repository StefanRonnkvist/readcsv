import 'package:flutter/material.dart';

import '../widgets/theme_mode_selector.dart';

/// Widths at which the workspace switches between layout tiers.
const double kPhoneMaxWidth = 600;
const double kTabletMaxWidth = 1024;

/// Shared scaffold used by compact layouts.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.title,
    required this.content,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final String title;
  final Widget content;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 140,
        leading: ThemeModeSelector(
          themeMode: themeMode,
          onChanged: onThemeModeChanged,
        ),
        title: Text(title),
      ),
      body: SafeArea(child: content),
    );
  }
}

/// Builds the shared theme card shown above the workspace content.
Widget buildThemeCard({
  required ThemeMode themeMode,
  required ValueChanged<ThemeMode> onThemeModeChanged,
}) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.palette_outlined),
          const SizedBox(width: 8),
          const Text('Theme'),
          const Spacer(),
          ThemeModeSelector(
            themeMode: themeMode,
            onChanged: onThemeModeChanged,
          ),
        ],
      ),
    ),
  );
}
