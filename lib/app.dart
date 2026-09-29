import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'core/widgets/splash_screen.dart';
import 'features/datasets/datasets_home_page.dart';

/// Root widget that restores and applies the user's preferred theme.
class ReadCsvApp extends StatefulWidget {
  const ReadCsvApp({super.key});

  @override
  State<ReadCsvApp> createState() => _ReadCsvAppState();
}

class _ReadCsvAppState extends State<ReadCsvApp> {
  static const String _themeModeKey = 'selected_theme_mode';

  ThemeMode _themeMode = ThemeMode.system;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
    _hideSplashAfterDelay();
  }

  Future<void> _hideSplashAfterDelay() async {
    await Future<void>.delayed(const Duration(seconds: 3));
    if (!mounted) {
      return;
    }
    setState(() {
      _showSplash = false;
    });
  }

  /// Restores the persisted theme, defaulting to the system setting.
  Future<void> _loadThemeMode() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? storedValue = prefs.getString(_themeModeKey);

    if (!mounted) {
      return;
    }

    setState(() {
      _themeMode = _parseThemeMode(storedValue);
    });
  }

  /// Persists and immediately applies a new theme selection.
  Future<void> _setThemeMode(ThemeMode themeMode) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, themeMode.name);

    if (!mounted) {
      return;
    }

    setState(() {
      _themeMode = themeMode;
    });
  }

  /// Converts the stored preference into a supported [ThemeMode].
  ThemeMode _parseThemeMode(String? storedValue) {
    switch (storedValue) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      case 'system':
      case null:
      default:
        return ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      home: _showSplash
          ? const SplashScreen()
          : DatasetsHomePage(
              themeMode: _themeMode,
              onThemeModeChanged: _setThemeMode,
            ),
    );
  }
}
