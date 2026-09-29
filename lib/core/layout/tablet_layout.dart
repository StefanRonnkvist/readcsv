import 'package:flutter/material.dart';

import 'large_screen_layout.dart';

/// Tablet layout for the CSV workspace.
class TabletLayout extends StatelessWidget {
  const TabletLayout({
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
      title: '',
      dataTitle: 'Tablet Data',
      dataSubtitle: 'Browse, filter, and export uploaded CSV datasets',
      contentPadding: const EdgeInsets.all(20),
      showAppBar: false,
      csvTabsSection: csvTabsSection,
      themeMode: themeMode,
      onThemeModeChanged: onThemeModeChanged,
    );
  }
}
