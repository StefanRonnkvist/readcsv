import 'dart:convert';

import 'package:sembast/sembast.dart';

import 'database_factory_provider.dart';

/// Metadata for one imported CSV file stored by [CsvRepository].
class CsvDataset {
  const CsvDataset({
    required this.id,
    required this.name,
    required this.size,
    required this.preview,
    required this.headers,
    required this.rowCount,
    required this.createdAt,
  });

  final int id;
  final String name;
  final int size;
  final String preview;
  final List<String> headers;
  final int rowCount;
  final DateTime createdAt;

  /// Reconstructs dataset metadata from a Sembast record.
  ///
  /// Missing fields use safe defaults so older or incomplete records remain
  /// readable.
  static CsvDataset fromRecord(
    RecordSnapshot<int, Map<String, Object?>> record,
  ) {
    final map = record.value;
    final dynamic headersValue = map['headers'];
    return CsvDataset(
      id: record.key,
      name: map['name'] as String? ?? 'Untitled CSV',
      size: map['size'] as int? ?? 0,
      preview: map['preview'] as String? ?? '',
      headers: headersValue is List
          ? headersValue.map((e) => e.toString()).toList()
          : const <String>[],
      rowCount: map['rowCount'] as int? ?? 0,
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

/// Persists CSV metadata and rows and exports complete datasets.
class CsvRepository {
  CsvRepository();

  final StoreRef<int, Map<String, Object?>> _datasetsStore = intMapStoreFactory
      .store('datasets');
  final StoreRef<int, Map<String, Object?>> _rowsStore = intMapStoreFactory
      .store('dataset_rows');

  Database? _db;

  /// Opens the platform database once and reuses it for later operations.
  Future<Database> _database() async {
    if (_db != null) {
      return _db!;
    }
    _db = await openAppDatabase();
    return _db!;
  }

  /// Returns all dataset metadata in creation order.
  Future<List<CsvDataset>> getDatasets() async {
    final db = await _database();
    final records = await _datasetsStore.find(
      db,
      finder: Finder(sortOrders: [SortOrder('createdAt')]),
    );
    return records.map(CsvDataset.fromRecord).toList();
  }

  /// Stores a dataset and all of its rows atomically.
  ///
  /// Returns the generated dataset identifier.
  Future<int> createDataset({
    required String name,
    required int size,
    required String preview,
    required List<String> headers,
    required List<Map<String, String>> rows,
  }) async {
    final db = await _database();
    return db.transaction<int>((txn) async {
      final datasetId = await _datasetsStore.add(txn, <String, Object?>{
        'name': name,
        'size': size,
        'preview': preview,
        'headers': headers,
        'rowCount': rows.length,
        'createdAt': DateTime.now().toIso8601String(),
      });

      if (rows.isNotEmpty) {
        for (int i = 0; i < rows.length; i++) {
          await _rowsStore.add(txn, <String, Object?>{
            'datasetId': datasetId,
            'rowIndex': i,
            'row': rows[i],
          });
        }
      }

      return datasetId;
    });
  }

  /// Loads the rows for [datasetId] in their original import order.
  Future<List<Map<String, String>>> getRowsForDataset(int datasetId) async {
    final db = await _database();
    final finder = Finder(
      filter: Filter.equals('datasetId', datasetId),
      sortOrders: [SortOrder('rowIndex')],
    );
    final records = await _rowsStore.find(db, finder: finder);

    return records.map((record) {
      final map =
          (record.value['row'] as Map<String, Object?>?) ??
          const <String, Object?>{};
      return map.map((key, value) => MapEntry(key, value?.toString() ?? ''));
    }).toList();
  }

  /// Changes the display name of the dataset identified by [datasetId].
  Future<void> renameDataset(int datasetId, String name) async {
    final db = await _database();
    await _datasetsStore.record(datasetId).update(db, <String, Object?>{
      'name': name,
    });
  }

  /// Deletes dataset metadata and its associated rows in one transaction.
  Future<void> deleteDataset(int datasetId) async {
    final db = await _database();
    await db.transaction((txn) async {
      await _datasetsStore.record(datasetId).delete(txn);
      await _rowsStore.delete(
        txn,
        finder: Finder(filter: Filter.equals('datasetId', datasetId)),
      );
    });
  }

  /// Serializes a dataset and its rows as JSON.
  ///
  /// Throws [StateError] when [datasetId] does not exist.
  Future<String> exportDatasetAsJson(
    int datasetId, {
    bool pretty = true,
  }) async {
    final CsvDataset? dataset = await getDatasetById(datasetId);
    if (dataset == null) {
      throw StateError('Dataset $datasetId not found');
    }

    final List<Map<String, String>> rows = await getRowsForDataset(datasetId);
    final Map<String, Object?> payload = <String, Object?>{
      'id': dataset.id,
      'name': dataset.name,
      'size': dataset.size,
      'rowCount': dataset.rowCount,
      'createdAt': dataset.createdAt.toIso8601String(),
      'headers': dataset.headers,
      'rows': rows,
    };

    return pretty
        ? const JsonEncoder.withIndent('  ').convert(payload)
        : jsonEncode(payload);
  }

  /// Serializes a dataset and its rows as an XML document.
  ///
  /// Throws [StateError] when [datasetId] does not exist.
  Future<String> exportDatasetAsXml(int datasetId) async {
    final CsvDataset? dataset = await getDatasetById(datasetId);
    if (dataset == null) {
      throw StateError('Dataset $datasetId not found');
    }

    final List<Map<String, String>> rows = await getRowsForDataset(datasetId);
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln(
      '<dataset id="${dataset.id}" name="${_escapeXml(dataset.name)}" size="${dataset.size}" rowCount="${dataset.rowCount}" createdAt="${dataset.createdAt.toIso8601String()}">',
    );
    buffer.writeln('  <headers>');
    for (final String header in dataset.headers) {
      buffer.writeln('    <header>${_escapeXml(header)}</header>');
    }
    buffer.writeln('  </headers>');
    buffer.writeln('  <rows>');
    for (int i = 0; i < rows.length; i++) {
      buffer.writeln('    <row index="$i">');
      final Map<String, String> row = rows[i];
      for (final String header in dataset.headers) {
        final String value = row[header] ?? '';
        buffer.writeln(
          '      <cell header="${_escapeXml(header)}">${_escapeXml(value)}</cell>',
        );
      }
      buffer.writeln('    </row>');
    }
    buffer.writeln('  </rows>');
    buffer.write('</dataset>');
    return buffer.toString();
  }

  /// Returns metadata for [datasetId], or `null` when it is not stored.
  Future<CsvDataset?> getDatasetById(int datasetId) async {
    final db = await _database();
    final RecordSnapshot<int, Map<String, Object?>>? record =
        await _datasetsStore.record(datasetId).getSnapshot(db);
    if (record == null) {
      return null;
    }
    return CsvDataset.fromRecord(record);
  }

  /// Escapes text before it is written into XML content or attributes.
  String _escapeXml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
