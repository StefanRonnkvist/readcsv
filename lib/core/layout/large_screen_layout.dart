import 'package:flutter/material.dart';

import 'app_shell.dart';

/// Shared body used by the tablet and desktop layout tiers.
class LargeScreenLayout extends StatelessWidget {
  const LargeScreenLayout({
    super.key,
    required this.title,
    required this.dataTitle,
    required this.dataSubtitle,
    required this.contentPadding,
    required this.showAppBar,
    required this.csvTabsSection,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final String title;
  final String dataTitle;
  final String dataSubtitle;
  final EdgeInsets contentPadding;
  final bool showAppBar;
  final Widget csvTabsSection;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  Widget build(BuildContext context) {
    final Widget body = SafeArea(
      child: Padding(
        padding: contentPadding,
        child: ListView(
          key: const ValueKey<String>('large-screen-data'),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: buildThemeCard(
                themeMode: themeMode,
                onThemeModeChanged: onThemeModeChanged,
              ),
            ),
            csvTabsSection,
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: showAppBar ? AppBar(title: Text(title)) : null,
      body: body,
    );
  }
}
