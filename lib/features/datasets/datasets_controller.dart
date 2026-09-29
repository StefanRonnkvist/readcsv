import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'data/csv_parser.dart';
import 'data/csv_repository.dart';

/// Tab positions of the three fixed tabs that precede dataset tabs.
const int kUploadTabIndex = 0;
const int kHelpTabIndex = 1;
const int kInformationTabIndex = 2;
const int kFirstDatasetTabIndex = 3;

/// Outcome of an import attempt, so the UI can report a result without the
/// controller needing to know about [ScaffoldMessenger].
class ImportResult {
  const ImportResult.success(this.message) : isSuccess = true;
  const ImportResult.failure(this.message) : isSuccess = false;

  final String message;
  final bool isSuccess;
}

/// Owns the imported datasets, their row cache, and the active tab.
///
/// All database access, file picking, and name resolution live here so the
/// widget tree only renders state and forwards user intent.
class DatasetsController extends ChangeNotifier {
  DatasetsController({
    CsvRepository? repository,
    this._parser = const CsvParser(),
  }) : _repository = repository ?? CsvRepository();

  final CsvRepository _repository;
  final CsvParser _parser;

  List<CsvDataset> _datasets = <CsvDataset>[];
  final Map<int, List<Map<String, String>>> _datasetRows =
      <int, List<Map<String, String>>>{};

  bool _isLoadingFile = false;
  bool _isLoadingDatasets = true;
  bool _showWebDatabaseNotice = true;
  int _selectedTabIndex = kUploadTabIndex;

  List<CsvDataset> get datasets => List<CsvDataset>.unmodifiable(_datasets);
  bool get isLoadingFile => _isLoadingFile;
  bool get isLoadingDatasets => _isLoadingDatasets;
  bool get showWebDatabaseNotice => _showWebDatabaseNotice;
  int get selectedTabIndex => _selectedTabIndex;

  /// The dataset behind the selected tab, or `null` for a fixed tab.
  CsvDataset? get activeDataset {
    if (_selectedTabIndex < kFirstDatasetTabIndex || _datasets.isEmpty) {
      return null;
    }
    final int index = _selectedTabIndex - kFirstDatasetTabIndex;
    if (index < 0 || index >= _datasets.length) {
      return null;
    }
    return _datasets[index];
  }

  /// Cached rows for [activeDataset], or `null` while they are still loading.
  List<Map<String, String>>? get activeRows {
    final CsvDataset? dataset = activeDataset;
    if (dataset == null) {
      return null;
    }
    return _datasetRows[dataset.id];
  }

  /// Whether CSV import is allowed on the current platform.
  bool get isImportSupported {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.windows;
  }

  /// Refreshes dataset metadata and keeps the requested or current tab valid.
  Future<void> loadDatasets({int? selectDatasetId}) async {
    _isLoadingDatasets = true;
    notifyListeners();

    final List<CsvDataset> datasets = await _repository.getDatasets();

    int nextIndex = _selectedTabIndex;
    if (selectDatasetId != null) {
      final int idx = datasets.indexWhere((d) => d.id == selectDatasetId);
      nextIndex = idx >= 0 ? idx + kFirstDatasetTabIndex : kUploadTabIndex;
    } else if (datasets.isEmpty) {
      nextIndex = kHelpTabIndex;
    } else {
      nextIndex = nextIndex.clamp(
        kUploadTabIndex,
        datasets.length + kInformationTabIndex,
      );
    }

    _datasets = datasets;
    _selectedTabIndex = nextIndex;
    _isLoadingDatasets = false;
    notifyListeners();

    final CsvDataset? dataset = activeDataset;
    if (dataset != null) {
      await _ensureRowsLoaded(dataset.id);
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
    _datasetRows[datasetId] = rows;
    notifyListeners();
  }

  /// Selects a tab and loads its dataset rows on demand.
  Future<void> selectTab(int index) async {
    if (_selectedTabIndex == index) {
      return;
    }
    _selectedTabIndex = index;
    notifyListeners();

    final CsvDataset? dataset = activeDataset;
    if (dataset != null) {
      await _ensureRowsLoaded(dataset.id);
    }
  }

  /// Dismisses the web-only storage notice for this session.
  void dismissWebDatabaseNotice() {
    if (!_showWebDatabaseNotice) {
      return;
    }
    _showWebDatabaseNotice = false;
    notifyListeners();
  }

  /// Picks, parses, normalizes, and persists a supported local tabular file.
  Future<ImportResult> pickLocalFile() async {
    if (!isImportSupported) {
      return const ImportResult.failure(
        'CSV import is currently available on Android and Windows in this '
        'build.',
      );
    }

    _isLoadingFile = true;
    notifyListeners();

    try {
      final List<PlatformFile> result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: <String>['csv', 'tsv', 'txt'],
      );

      if (result.isEmpty) {
        return const ImportResult.failure('');
      }

      final PlatformFile pickedFile = result.single;
      final Uint8List bytes = await pickedFile.readAsBytes();
      if (bytes.isEmpty) {
        return const ImportResult.failure(
          'Could not read file bytes. Please try another file.',
        );
      }

      final String csvText = utf8.decode(bytes, allowMalformed: true);
      final ParsedTable table = _parser.parse(csvText);

      if (table.headers.isEmpty) {
        return const ImportResult.failure('CSV is empty.');
      }

      final String resolvedName = resolveUniqueName(pickedFile.name);

      final int datasetId = await _repository.createDataset(
        name: resolvedName,
        size: bytes.length,
        preview: _parser.buildPreview(bytes),
        headers: table.headers,
        rows: table.rows,
      );

      await loadDatasets(selectDatasetId: datasetId);

      return ImportResult.success(
        'Imported ${pickedFile.name} using '
        '${_parser.delimiterDisplayName(table.delimiter)} delimiter.',
      );
    } catch (_) {
      return const ImportResult.failure(
        'Failed to import file. Please check the file format.',
      );
    } finally {
      _isLoadingFile = false;
      notifyListeners();
    }
  }

  /// Renames [dataset], keeping the new name case-insensitively unique.
  Future<void> renameDataset(CsvDataset dataset, String newName) async {
    final String uniqueName = resolveUniqueName(newName, ignoreId: dataset.id);
    await _repository.renameDataset(dataset.id, uniqueName);
    await loadDatasets(selectDatasetId: dataset.id);
  }

  /// Permanently removes [dataset] and evicts its cached rows.
  Future<void> deleteDataset(CsvDataset dataset) async {
    await _repository.deleteDataset(dataset.id);
    _datasetRows.remove(dataset.id);
    await loadDatasets();
  }

  /// Generates the JSON document for [dataset].
  Future<String> exportDatasetAsJson(CsvDataset dataset) {
    return _repository.exportDatasetAsJson(dataset.id);
  }

  /// Generates the XML document for [dataset].
  Future<String> exportDatasetAsXml(CsvDataset dataset) {
    return _repository.exportDatasetAsXml(dataset.id);
  }

  /// Returns a case-insensitively unique display name for an imported file.
  ///
  /// During a rename, [ignoreId] excludes the dataset being renamed from the
  /// collision check.
  String resolveUniqueName(String originalName, {int? ignoreId}) {
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
}
