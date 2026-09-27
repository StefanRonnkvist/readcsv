import 'dart:convert';
import 'dart:math' as math;

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'contact/contact_page.dart';
import 'contact/submissions_csv_page.dart';
import 'data/csv_repository.dart';
import 'splash_screen.dart';

/// Starts the Flutter application.
void main() {
  runApp(const MainApp());
}

/// Root widget that restores and applies the user's preferred theme.
class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
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

    setState(() {
      _themeMode = _parseThemeMode(storedValue);
    });
  }

  /// Persists and immediately applies a new theme selection.
  Future<void> _setThemeMode(ThemeMode themeMode) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, themeMode.name);

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
    final ThemeData lightTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      useMaterial3: true,
    );
    final ThemeData darkTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.teal,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: lightTheme,
      darkTheme: darkTheme,
      home: _showSplash
          ? const SplashScreen()
          : ResponsiveHomePage(
              themeMode: _themeMode,
              onThemeModeChanged: _setThemeMode,
            ),
    );
  }
}

/// Owns imported datasets and selects a layout for the available width.
class ResponsiveHomePage extends StatefulWidget {
  const ResponsiveHomePage({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  static const double phoneMaxWidth = 600;
  static const double tabletMaxWidth = 1024;

  @override
  State<ResponsiveHomePage> createState() => _ResponsiveHomePageState();
}

class _ResponsiveHomePageState extends State<ResponsiveHomePage> {
  static const int _uploadTabIndex = 0;
  static const int _helpTabIndex = 1;
  static const int _informationTabIndex = 2;
  static const int _firstDatasetTabIndex = 3;

  final CsvRepository _repository = CsvRepository();

  List<CsvDataset> _datasets = <CsvDataset>[];
  final Map<int, List<Map<String, String>>> _datasetRows =
      <int, List<Map<String, String>>>{};

  bool _isLoadingFile = false;
  bool _isLoadingDatasets = true;
  bool _showWebDatabaseNotice = true;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadDatasets();
  }

  /// Refreshes dataset metadata and keeps the requested or current tab valid.
  ///
  /// Rows for the resulting active dataset are loaded lazily after the
  /// metadata has been applied.
  Future<void> _loadDatasets({int? selectDatasetId}) async {
    setState(() {
      _isLoadingDatasets = true;
    });

    final List<CsvDataset> datasets = await _repository.getDatasets();

    int nextIndex = _selectedTabIndex;
    if (selectDatasetId != null) {
      final int idx = datasets.indexWhere((d) => d.id == selectDatasetId);
      nextIndex = idx >= 0 ? idx + _firstDatasetTabIndex : _uploadTabIndex;
    } else if (datasets.isEmpty) {
      nextIndex = _helpTabIndex;
    } else {
      nextIndex = nextIndex.clamp(
        _uploadTabIndex,
        datasets.length + _informationTabIndex,
      );
    }

    setState(() {
      _datasets = datasets;
      _selectedTabIndex = nextIndex;
      _isLoadingDatasets = false;
    });

    final CsvDataset? activeDataset = _activeDataset();
    if (activeDataset != null) {
      await _ensureRowsLoaded(activeDataset.id);
    }
  }

  /// Loads and caches rows unless [datasetId] is already in memory.
  Future<void> _ensureRowsLoaded(int datasetId) async {
    if (_datasetRows.containsKey(datasetId)) {
      return;
    }

    final List<Map<String, String>> rows = await _repository.getRowsForDataset(
      datasetId,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _datasetRows[datasetId] = rows;
    });
  }

  /// Maps the selected tab index to a dataset, if a dataset tab is active.
  CsvDataset? _activeDataset() {
    if (_selectedTabIndex < _firstDatasetTabIndex || _datasets.isEmpty) {
      return null;
    }
    final int index = _selectedTabIndex - _firstDatasetTabIndex;
    if (index < 0 || index >= _datasets.length) {
      return null;
    }
    return _datasets[index];
  }

  /// Picks, parses, normalizes, and persists a supported local tabular file.
  Future<void> _pickLocalFile() async {
    setState(() {
      _isLoadingFile = true;
    });

    try {
      final bool isSupportedPlatform =
          defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.windows;
      if (kIsWeb || !isSupportedPlatform) {
        _showSnackBar(
          'CSV import is currently available on Android and Windows in this build.',
        );
        return;
      }

      final List<PlatformFile> result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: <String>['csv', 'tsv', 'txt'],
      );

      if (!mounted || result.isEmpty) {
        return;
      }

      final PlatformFile pickedFile = result.single;
      final Uint8List bytes = await pickedFile.readAsBytes();
      if (bytes.isEmpty) {
        _showSnackBar('Could not read file bytes. Please try another file.');
        return;
      }

      final String pickedName = pickedFile.name;

      final String csvText = utf8.decode(bytes, allowMalformed: true);
      final String delimiter = _detectDelimiter(csvText);
      final List<List<dynamic>> records = Csv(
        fieldDelimiter: delimiter,
        autoDetect: false,
      ).decode(csvText);

      if (records.isEmpty) {
        _showSnackBar('CSV is empty.');
        return;
      }

      final List<String> headers = _normalizeHeaders(records.first);

      final List<Map<String, String>> rows = <Map<String, String>>[];
      for (int i = 1; i < records.length; i++) {
        final List<dynamic> rawRow = records[i];
        final Map<String, String> row = <String, String>{};

        bool hasAnyValue = false;
        for (int c = 0; c < headers.length; c++) {
          final String key = headers[c];
          final String value = c < rawRow.length ? rawRow[c].toString() : '';
          if (value.trim().isNotEmpty) {
            hasAnyValue = true;
          }
          row[key] = value;
        }

        if (hasAnyValue) {
          rows.add(row);
        }
      }

      final String preview = utf8.decode(
        bytes.take(500).toList(),
        allowMalformed: true,
      );

      final String resolvedName = _resolveUniqueFileName(pickedName);

      final int datasetId = await _repository.createDataset(
        name: resolvedName,
        size: bytes.length,
        preview: preview,
        headers: headers,
        rows: rows,
      );

      await _loadDatasets(selectDatasetId: datasetId);
      _showSnackBar(
        'Imported $pickedName using ${_delimiterDisplayName(delimiter)} delimiter.',
      );
    } catch (_) {
      _showSnackBar('Failed to import file. Please check the file format.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFile = false;
        });
      }
    }
  }

  /// Selects a tab and loads its dataset rows on demand.
  Future<void> _onTabSelected(int index) async {
    setState(() {
      _selectedTabIndex = index;
    });

    final CsvDataset? dataset = _activeDataset();
    if (dataset != null) {
      await _ensureRowsLoaded(dataset.id);
    }
  }

  /// Prompts for a new unique name and persists it for [dataset].
  Future<void> _renameDataset(CsvDataset dataset) async {
    final TextEditingController controller = TextEditingController(
      text: dataset.name,
    );

    final String? renamed = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Rename CSV Tab'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'New name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (renamed == null || renamed.isEmpty) {
      return;
    }

    final String uniqueName = _resolveUniqueFileName(
      renamed,
      ignoreId: dataset.id,
    );
    await _repository.renameDataset(dataset.id, uniqueName);
    await _loadDatasets(selectDatasetId: dataset.id);
  }

  /// Confirms and permanently removes [dataset] and its cached rows.
  Future<void> _deleteDataset(CsvDataset dataset) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete CSV Tab'),
          content: Text('Delete ${dataset.name} and all stored rows?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _repository.deleteDataset(dataset.id);
    _datasetRows.remove(dataset.id);
    await _loadDatasets();
  }

  /// Generates JSON and opens it in the shared export dialog.
  Future<void> _exportDatasetAsJson(CsvDataset dataset) async {
    try {
      final String content = await _repository.exportDatasetAsJson(dataset.id);
      await _showExportDialog(
        title: '${dataset.name}.json',
        formatLabel: 'JSON',
        content: content,
      );
    } catch (_) {
      _showSnackBar('Failed to export JSON for ${dataset.name}.');
    }
  }

  /// Generates XML and opens it in the shared export dialog.
  Future<void> _exportDatasetAsXml(CsvDataset dataset) async {
    try {
      final String content = await _repository.exportDatasetAsXml(dataset.id);
      await _showExportDialog(
        title: '${dataset.name}.xml',
        formatLabel: 'XML',
        content: content,
      );
    } catch (_) {
      _showSnackBar('Failed to export XML for ${dataset.name}.');
    }
  }

  /// Displays generated export text with an option to copy it.
  Future<void> _showExportDialog({
    required String title,
    required String formatLabel,
    required String content,
  }) async {
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Export $formatLabel'),
          content: SizedBox(
            width: 700,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(dialogContext).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 340),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(dialogContext).dividerColor,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(child: SelectableText(content)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: content));
                if (!dialogContext.mounted || !mounted) {
                  return;
                }
                Navigator.of(dialogContext).pop();
                _showSnackBar('$formatLabel copied to clipboard.');
              },
              child: const Text('Copy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final CsvDataset? activeDataset = _activeDataset();

    final Widget csvTabsSection = _CsvTabsSection(
      datasets: _datasets,
      selectedTabIndex: _selectedTabIndex,
      isLoadingFile: _isLoadingFile,
      isLoadingDatasets: _isLoadingDatasets,
      activeRows: activeDataset == null ? null : _datasetRows[activeDataset.id],
      informationContent: _InformationTabsPanel(
        formContent: ContactPage(
          serverUri: Uri.parse('https://stefanronnkvist.com/contact.php'),
          showAppBar: false,
          wrapInScaffold: false,
        ),
        serverDataContent: const SubmissionsCsvCardsView(
          csvUrl: 'https://stefanronnkvist.com/submissions.csv',
        ),
      ),
      onTabSelected: _onTabSelected,
      onPickFile: _pickLocalFile,
      onRenameDataset: _renameDataset,
      onDeleteDataset: _deleteDataset,
      onExportJson: _exportDatasetAsJson,
      onExportXml: _exportDatasetAsXml,
    );

    final Widget responsiveLayout = LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < ResponsiveHomePage.phoneMaxWidth) {
          return PhoneLayout(
            csvTabsSection: csvTabsSection,
            themeMode: widget.themeMode,
            onThemeModeChanged: widget.onThemeModeChanged,
          );
        }

        if (constraints.maxWidth < ResponsiveHomePage.tabletMaxWidth) {
          return TabletLayout(
            csvTabsSection: csvTabsSection,
            themeMode: widget.themeMode,
            onThemeModeChanged: widget.onThemeModeChanged,
          );
        }

        return DesktopLayout(
          csvTabsSection: csvTabsSection,
          themeMode: widget.themeMode,
          onThemeModeChanged: widget.onThemeModeChanged,
        );
      },
    );

    if (!kIsWeb || !_showWebDatabaseNotice) {
      return responsiveLayout;
    }

    return Column(
      children: [
        Material(
          color: Colors.red.shade700,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'PWA notice: database functions are not available on web builds. Data is temporary for this browser session only.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Dismiss notice',
                    onPressed: () {
                      setState(() {
                        _showWebDatabaseNotice = false;
                      });
                    },
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(child: responsiveLayout),
      ],
    );
  }

  /// Returns a case-insensitively unique display name for an imported file.
  ///
  /// During a rename, [ignoreId] excludes the dataset being renamed from the
  /// collision check.
  String _resolveUniqueFileName(String originalName, {int? ignoreId}) {
    final Set<String> existing = _datasets
        .where((dataset) => dataset.id != ignoreId)
        .map((dataset) => dataset.name.toLowerCase())
        .toSet();

    if (!existing.contains(originalName.toLowerCase())) {
      return originalName;
    }

    int suffix = 2;
    while (true) {
      final String candidate = '$originalName ($suffix)';
      if (!existing.contains(candidate.toLowerCase())) {
        return candidate;
      }
      suffix++;
    }
  }

  /// Cleans header text and gives blank or duplicate columns stable names.
  List<String> _normalizeHeaders(List<dynamic> rawHeaders) {
    final Map<String, int> usedCounts = <String, int>{};
    final List<String> headers = <String>[];

    for (int i = 0; i < rawHeaders.length; i++) {
      final String rawValue = rawHeaders[i].toString();
      final String trimmed = rawValue.replaceFirst('\uFEFF', '').trim();
      final String baseHeader = trimmed.isEmpty ? 'col_${i + 1}' : trimmed;

      final String normalizedKey = baseHeader.toLowerCase();
      final int existingCount = usedCounts[normalizedKey] ?? 0;
      usedCounts[normalizedKey] = existingCount + 1;

      if (existingCount == 0) {
        headers.add(baseHeader);
      } else {
        headers.add('$baseHeader (${existingCount + 1})');
      }
    }

    return headers;
  }

  /// Chooses the delimiter that produces the most fields in sampled lines.
  String _detectDelimiter(String text) {
    final List<String> lines = text
        .split(RegExp(r'\r\n|\n|\r'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .take(5)
        .toList();

    if (lines.isEmpty) {
      return ',';
    }

    const List<String> candidates = <String>[',', ';', '\t', '|'];
    String bestDelimiter = ',';
    int bestScore = -1;

    for (final String delimiter in candidates) {
      int score = 0;
      for (final String line in lines) {
        final int parts = line.split(delimiter).length;
        if (parts > 1) {
          score += parts;
        }
      }

      if (score > bestScore) {
        bestScore = score;
        bestDelimiter = delimiter;
      }
    }

    return bestDelimiter;
  }

  /// Converts a delimiter character into user-facing text.
  String _delimiterDisplayName(String delimiter) {
    switch (delimiter) {
      case ',':
        return 'comma (,)';
      case ';':
        return 'semicolon (;)';
      case '\t':
        return 'tab';
      case '|':
        return 'pipe (|)';
      default:
        return 'custom';
    }
  }
}

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

/// Phone layout for the CSV workspace.
class PhoneLayout extends StatefulWidget {
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
  State<PhoneLayout> createState() => _PhoneLayoutState();
}

class _PhoneLayoutState extends State<PhoneLayout> {
  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: '',
      themeMode: widget.themeMode,
      onThemeModeChanged: widget.onThemeModeChanged,
      content: ListView(
        key: const ValueKey<String>('phone-data'),
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.palette_outlined),
                    const SizedBox(width: 8),
                    const Text('Theme'),
                    const Spacer(),
                    ThemeModeSelector(
                      themeMode: widget.themeMode,
                      onChanged: widget.onThemeModeChanged,
                    ),
                  ],
                ),
              ),
            ),
          ),
          widget.csvTabsSection,
        ],
      ),
    );
  }
}

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
    return _LargeScreenLayout(
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
    return _LargeScreenLayout(
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

class _LargeScreenLayout extends StatefulWidget {
  const _LargeScreenLayout({
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
  State<_LargeScreenLayout> createState() => _LargeScreenLayoutState();
}

class _LargeScreenLayoutState extends State<_LargeScreenLayout> {
  Widget _buildSection() {
    return ListView(
      key: const ValueKey<String>('large-screen-data'),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.palette_outlined),
                  const SizedBox(width: 8),
                  const Text('Theme'),
                  const Spacer(),
                  ThemeModeSelector(
                    themeMode: widget.themeMode,
                    onChanged: widget.onThemeModeChanged,
                  ),
                ],
              ),
            ),
          ),
        ),
        widget.csvTabsSection,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget body = SafeArea(
      child: Padding(padding: widget.contentPadding, child: _buildSection()),
    );

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              leadingWidth: 140,
              leading: ThemeModeSelector(
                themeMode: widget.themeMode,
                onChanged: widget.onThemeModeChanged,
              ),
              title: Text(widget.title),
            )
          : null,
      body: body,
    );
  }
}

class _CsvTabsSection extends StatelessWidget {
  const _CsvTabsSection({
    required this.datasets,
    required this.selectedTabIndex,
    required this.isLoadingFile,
    required this.isLoadingDatasets,
    required this.activeRows,
    required this.informationContent,
    required this.onTabSelected,
    required this.onPickFile,
    required this.onRenameDataset,
    required this.onDeleteDataset,
    required this.onExportJson,
    required this.onExportXml,
  });

  final List<CsvDataset> datasets;
  final int selectedTabIndex;
  final bool isLoadingFile;
  final bool isLoadingDatasets;
  final List<Map<String, String>>? activeRows;
  final Widget informationContent;
  final ValueChanged<int> onTabSelected;
  final Future<void> Function() onPickFile;
  final Future<void> Function(CsvDataset dataset) onRenameDataset;
  final Future<void> Function(CsvDataset dataset) onDeleteDataset;
  final Future<void> Function(CsvDataset dataset) onExportJson;
  final Future<void> Function(CsvDataset dataset) onExportXml;

  @override
  Widget build(BuildContext context) {
    const int uploadTabIndex = 0;
    const int helpTabIndex = 1;
    const int informationTabIndex = 2;
    const int firstDatasetTabIndex = 3;

    final List<String> tabLabels = <String>[
      'Upload New Document',
      'Help',
      'Information',
    ];
    tabLabels.addAll(datasets.map((e) => e.name));

    final CsvDataset? activeDataset = selectedTabIndex < firstDatasetTabIndex
        ? null
        : datasets[selectedTabIndex - firstDatasetTabIndex];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ScrollableEqualTabs(
              labels: tabLabels,
              selectedIndex: selectedTabIndex,
              onSelected: onTabSelected,
            ),
            const SizedBox(height: 12),
            if (selectedTabIndex == uploadTabIndex)
              _UploadPanel(isLoadingFile: isLoadingFile, onPickFile: onPickFile)
            else if (selectedTabIndex == helpTabIndex)
              const _HelpPanel()
            else if (selectedTabIndex == informationTabIndex)
              informationContent
            else if (isLoadingDatasets)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (activeDataset != null)
              _DatasetPanel(
                dataset: activeDataset,
                rows: activeRows,
                onRenameDataset: onRenameDataset,
                onDeleteDataset: onDeleteDataset,
                onExportJson: onExportJson,
                onExportXml: onExportXml,
              ),
          ],
        ),
      ),
    );
  }
}

class _ScrollableEqualTabs extends StatelessWidget {
  const _ScrollableEqualTabs({
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double minTabWidth = 120;
        final double width = constraints.maxWidth;
        final double tabWidth = math.max(minTabWidth, width / labels.length);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List<Widget>.generate(labels.length, (int index) {
              return SizedBox(
                width: tabWidth,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    selected: selectedIndex == index,
                    label: SizedBox(
                      width: double.infinity,
                      child: Text(
                        labels[index],
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    onSelected: (_) => onSelected(index),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

class _UploadPanel extends StatelessWidget {
  const _UploadPanel({required this.isLoadingFile, required this.onPickFile});

  final bool isLoadingFile;
  final Future<void> Function() onPickFile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilledButton.icon(
          onPressed: isLoadingFile ? null : onPickFile,
          icon: const Icon(Icons.upload_file),
          label: Text(isLoadingFile ? 'Loading...' : 'Upload document'),
        ),
        const SizedBox(height: 10),
        const Text(
          'Upload a CSV, TSV, or TXT document to inspect its rows and columns. Supported files are imported as separate tabs for easy review and export.',
        ),
      ],
    );
  }
}

class _HelpPanel extends StatelessWidget {
  const _HelpPanel();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Using Read CSV',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Import a tabular file, inspect and filter its rows, then copy the data as JSON or XML. Each imported file has its own dataset tab.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          _HelpSection(
            title: '1) Import a file',
            body:
                'Open Upload New Document and choose a CSV, TSV, or TXT file. Import is available on Android and Windows in this build. Comma, semicolon, tab, and pipe delimiters are detected automatically.',
          ),
          const SizedBox(height: 10),
          _HelpSection(
            title: '2) Check the imported data',
            body:
                'The first record is used as the header row. Blank header names receive a generated name, duplicate headers are made unique, and completely empty data rows are skipped. The dataset tab shows its row count, file size, and scrollable table.',
          ),
          const SizedBox(height: 10),
          _HelpSection(
            title: '3) Search and filter',
            body:
                'Choose a column and one of its values to find exact matches. Text search checks every column and is not case-sensitive. Both filters can be used together; the row summary shows how many records match.',
          ),
          const SizedBox(height: 10),
          _HelpSection(
            title: '4) Manage datasets',
            body:
                'Use Rename to change a dataset tab name. Duplicate names receive a numeric suffix. Use Delete to permanently remove a dataset and all of its stored rows after confirmation.',
          ),
          const SizedBox(height: 10),
          _HelpSection(
            title: '5) Copy JSON or XML',
            body:
                'Export JSON and Export XML open a preview of the complete dataset. Select Copy to place the generated text on the clipboard, then paste it into the app or file of your choice.',
          ),
          const SizedBox(height: 10),
          _HelpSection(
            title: '6) Storage and privacy',
            body:
                'Imported datasets are stored locally on your device and remain available after restarting the app. Importing, browsing, filtering, and exporting do not send your dataset contents to the contact server.',
          ),
          const SizedBox(height: 10),
          _HelpSection(
            title: '7) Information and network access',
            body:
                'Information > Form sends your name, return email, question, and basic app/device diagnostics to the configured contact server. Server Data uses the internet to retrieve inquiries associated with this app.',
          ),
          const SizedBox(height: 10),
          _HelpSection(
            title: '8) Appearance and layout',
            body:
                'Choose System, Dark, or Light from the theme control; your choice is remembered. The workspace adapts to phone, tablet, and desktop widths, and tab bars scroll when space is limited.',
          ),
        ],
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  const _HelpSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(body, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _InformationTabsPanel extends StatefulWidget {
  const _InformationTabsPanel({
    required this.formContent,
    required this.serverDataContent,
  });

  final Widget formContent;
  final Widget serverDataContent;

  @override
  State<_InformationTabsPanel> createState() => _InformationTabsPanelState();
}

class _InformationTabsPanelState extends State<_InformationTabsPanel> {
  static const String _selectedInfoTabKey = 'selected_information_tab_index';
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _restoreSelectedInformationTab();
  }

  /// Restores the previously selected information sub-tab.
  Future<void> _restoreSelectedInformationTab() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int savedIndex = prefs.getInt(_selectedInfoTabKey) ?? 0;
    final int normalizedIndex = savedIndex.clamp(0, 1);

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedIndex = normalizedIndex;
    });
  }

  /// Saves the selected information sub-tab for the next session.
  Future<void> _persistSelectedInformationTab(int index) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_selectedInfoTabKey, index);
  }

  @override
  Widget build(BuildContext context) {
    const int formTabIndex = 0;
    const int serverDataTabIndex = 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ScrollableEqualTabs(
          labels: const <String>['Form', 'Server Data'],
          selectedIndex: _selectedIndex,
          onSelected: (int index) {
            setState(() {
              _selectedIndex = index;
            });
            _persistSelectedInformationTab(index);
          },
        ),
        const SizedBox(height: 12),
        if (_selectedIndex == formTabIndex)
          widget.formContent
        else if (_selectedIndex == serverDataTabIndex)
          widget.serverDataContent,
      ],
    );
  }
}

class _DatasetPanel extends StatefulWidget {
  const _DatasetPanel({
    required this.dataset,
    required this.rows,
    required this.onRenameDataset,
    required this.onDeleteDataset,
    required this.onExportJson,
    required this.onExportXml,
  });

  final CsvDataset dataset;
  final List<Map<String, String>>? rows;
  final Future<void> Function(CsvDataset dataset) onRenameDataset;
  final Future<void> Function(CsvDataset dataset) onDeleteDataset;
  final Future<void> Function(CsvDataset dataset) onExportJson;
  final Future<void> Function(CsvDataset dataset) onExportXml;

  @override
  State<_DatasetPanel> createState() => _DatasetPanelState();
}

class _DatasetPanelState extends State<_DatasetPanel> {
  static const String _allColumnsValue = '__all_columns__';
  static const String _allValues = '__all_values__';

  String _selectedSearchValue = _allValues;
  String _selectedHeader = _allColumnsValue;
  String _textSearchQuery = '';

  /// Resets filters when the active dataset changes and repairs stale values.
  @override
  void didUpdateWidget(covariant _DatasetPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.dataset.id != widget.dataset.id) {
      _selectedSearchValue = _allValues;
      _selectedHeader = _allColumnsValue;
      _textSearchQuery = '';
      return;
    }

    if (_selectedHeader != _allColumnsValue &&
        !widget.dataset.headers.contains(_selectedHeader)) {
      _selectedHeader = _allColumnsValue;
    }

    final List<String> options = _searchOptions();
    if (_selectedSearchValue != _allValues &&
        !options.contains(_selectedSearchValue)) {
      _selectedSearchValue = _allValues;
    }
  }

  /// Returns sorted, distinct non-empty values for the selected column.
  List<String> _searchOptions() {
    if (_selectedHeader == _allColumnsValue || widget.rows == null) {
      return <String>[];
    }

    final Set<String> values = <String>{};
    for (final Map<String, String> row in widget.rows!) {
      final String value = (row[_selectedHeader] ?? '').trim();
      if (value.isNotEmpty) {
        values.add(value);
      }
    }

    final List<String> sortedValues = values.toList()
      ..sort(
        (String a, String b) => a.toLowerCase().compareTo(b.toLowerCase()),
      );
    return sortedValues;
  }

  /// Applies the exact-value filter followed by case-insensitive text search.
  ///
  /// Returns `null` while rows are still loading.
  List<Map<String, String>>? _filteredRows() {
    final List<Map<String, String>>? sourceRows = widget.rows;
    if (sourceRows == null) {
      return null;
    }

    Iterable<Map<String, String>> filtered = sourceRows;

    if (_selectedSearchValue != _allValues &&
        _selectedHeader != _allColumnsValue) {
      final String selected = _selectedSearchValue.toLowerCase();
      filtered = filtered.where((Map<String, String> row) {
        final String value = (row[_selectedHeader] ?? '').trim().toLowerCase();
        return value == selected;
      });
    }

    final String query = _textSearchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((Map<String, String> row) {
        for (final String header in widget.dataset.headers) {
          final String value = (row[header] ?? '').toLowerCase();
          if (value.contains(query)) {
            return true;
          }
        }
        return false;
      });
    }

    return filtered.toList();
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>>? filteredRows = _filteredRows();
    final List<String> searchOptions = _searchOptions();
    final bool hasSearch =
        _selectedSearchValue != _allValues ||
        _textSearchQuery.trim().isNotEmpty;
    final int totalRows = widget.rows?.length ?? 0;
    final int shownRows = filteredRows?.length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${widget.dataset.name} • ${widget.dataset.rowCount} rows',
                style: Theme.of(context).textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton.icon(
              onPressed: () => widget.onRenameDataset(widget.dataset),
              icon: const Icon(Icons.edit),
              label: const Text('Rename'),
            ),
            TextButton.icon(
              onPressed: () => widget.onDeleteDataset(widget.dataset),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete'),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => widget.onExportJson(widget.dataset),
              icon: const Icon(Icons.data_object),
              label: const Text('Export JSON'),
            ),
            OutlinedButton.icon(
              onPressed: () => widget.onExportXml(widget.dataset),
              icon: const Icon(Icons.code),
              label: const Text('Export XML'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Size: ${_formatFileSize(widget.dataset.size)}'),
        const SizedBox(height: 8),
        Text('Search', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final Widget catagoryField = DropdownButtonFormField<String>(
              initialValue: _selectedHeader,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Catagory',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: <DropdownMenuItem<String>>[
                const DropdownMenuItem<String>(
                  value: _allColumnsValue,
                  child: Text('All Catagories'),
                ),
                ...widget.dataset.headers.map(
                  (String header) => DropdownMenuItem<String>(
                    value: header,
                    child: Text(header, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
              onChanged: (String? value) {
                setState(() {
                  _selectedHeader = value ?? _allColumnsValue;
                  _selectedSearchValue = _allValues;
                });
              },
            );

            final Widget searchValueField = DropdownButtonFormField<String>(
              initialValue: _selectedSearchValue,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Search contents',
                hintText: _selectedHeader == _allColumnsValue
                    ? 'Select catagory first'
                    : 'Select a value',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              items: <DropdownMenuItem<String>>[
                const DropdownMenuItem<String>(
                  value: _allValues,
                  child: Text('All Values'),
                ),
                ...searchOptions.map(
                  (String value) => DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
              onChanged: _selectedHeader == _allColumnsValue
                  ? null
                  : (String? value) {
                      setState(() {
                        _selectedSearchValue = value ?? _allValues;
                      });
                    },
            );

            if (constraints.maxWidth < 700) {
              return Column(
                children: [
                  catagoryField,
                  const SizedBox(height: 8),
                  searchValueField,
                ],
              );
            }

            return Row(
              children: [
                Expanded(flex: 2, child: catagoryField),
                const SizedBox(width: 8),
                Expanded(flex: 3, child: searchValueField),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Text search',
            hintText: 'Enter text to match rows',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (String value) {
            setState(() {
              _textSearchQuery = value;
            });
          },
        ),
        const SizedBox(height: 8),
        Text(
          hasSearch
              ? 'Showing $shownRows of $totalRows rows'
              : '$totalRows rows',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        Text('Contents', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        SizedBox(
          height: 250,
          child: _DatasetRowsTable(
            headers: widget.dataset.headers,
            rows: filteredRows,
            emptyMessage: hasSearch
                ? 'No matching rows found.'
                : 'No data rows found.',
          ),
        ),
      ],
    );
  }
}

class _DatasetRowsTable extends StatelessWidget {
  const _DatasetRowsTable({
    required this.headers,
    required this.rows,
    required this.emptyMessage,
  });

  final List<String> headers;
  final List<Map<String, String>>? rows;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (rows == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (headers.isEmpty) {
      return const Center(child: Text('No header row found in CSV.'));
    }

    if (rows!.isEmpty) {
      return Center(child: Text(emptyMessage));
    }

    final List<Map<String, String>> visibleRows = rows!;

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: headers
                .map(
                  (h) => DataColumn(
                    label: Text(h, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            rows: visibleRows
                .map(
                  (row) => DataRow(
                    cells: headers
                        .map(
                          (header) => DataCell(
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 260),
                              child: Text(
                                row[header] ?? '',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

/// Formats a byte count using bytes, kibibyte-sized KB, or mebibyte-sized MB.
String _formatFileSize(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
