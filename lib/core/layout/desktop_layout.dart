import 'package:flutter/material.dart';

import 'large_screen_layout.dart';

/// Desktop layout for the CSV workspace.
class DesktopLayout extends StatelessWidget {
  const DesktopLayout({
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
    return LargeScreenLayout(
      title: 'Desktop Workspace',
      dataTitle: 'Desktop Data',
      dataSubtitle: 'Manage uploaded CSV tabs and inspect data quickly',
      contentPadding: const EdgeInsets.all(24),
      showAppBar: false,
      csvTabsSection: csvTabsSection,
      themeMode: themeMode,
      onThemeModeChanged: onThemeModeChanged,
    );
  }
}
