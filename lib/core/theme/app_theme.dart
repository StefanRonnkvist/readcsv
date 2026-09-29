import 'package:flutter/material.dart';

/// Seed colour shared by the light and dark themes.
const Color kAppSeedColor = Colors.teal;

/// Builds the light theme used across the application.
ThemeData buildLightTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: kAppSeedColor),
    useMaterial3: true,
  );
}

/// Builds the dark theme used across the application.
ThemeData buildDarkTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: kAppSeedColor,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
  );
}
