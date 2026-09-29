import 'package:flutter/material.dart';

import 'app_shell.dart';

/// Phone layout for the CSV workspace.
class PhoneLayout extends StatelessWidget {
  const PhoneLayout({
    super.key,
    required this.csvTabsSection,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final Widget csvTabsSection;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: '',
      themeMode: themeMode,
      onThemeModeChanged: onThemeModeChanged,
      content: ListView(
        key: const ValueKey<String>('phone-data'),
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: buildThemeCard(
              themeMode: themeMode,
              onThemeModeChanged: onThemeModeChanged,
            ),
          ),
          csvTabsSection,
        ],
      ),
    );
  }
}
