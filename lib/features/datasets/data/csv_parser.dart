import 'dart:convert';

import 'package:csv/csv.dart';

/// A parsed tabular file ready to be persisted as a dataset.
class ParsedTable {
  const ParsedTable({
    required this.headers,
    required this.rows,
    required this.delimiter,
  });

  final List<String> headers;
  final List<Map<String, String>> rows;
  final String delimiter;
}

/// Pure, testable conversions from raw file text into a [ParsedTable].
///
/// This deliberately holds no Flutter or platform dependency so it can be
/// exercised directly by unit tests.
class CsvParser {
  const CsvParser();

  /// Chooses the delimiter that produces the most fields across sampled lines.
  ///
  /// Candidates are comma, semicolon, tab, and pipe. Falls back to comma when
  /// the text has no usable line or no delimiter occurs more than zero times.
  String detectDelimiter(String text) {
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

  /// Cleans header text and gives blank or duplicate columns stable names.
  ///
  /// A UTF-8 byte-order mark is stripped, blank names become `col_<index>`, and
  /// repeats gain a numeric suffix.
  List<String> normalizeHeaders(List<dynamic> rawHeaders) {
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

  /// Parses [text] into headers and rows keyed by the normalized header names.
  ///
  /// The first record becomes the header row. Rows that are entirely empty are
  /// skipped, and short rows are padded with empty values.
  ParsedTable parse(String text, {String? delimiter}) {
    final String resolvedDelimiter = delimiter ?? detectDelimiter(text);
    final List<List<dynamic>> records = Csv(
      fieldDelimiter: resolvedDelimiter,
      autoDetect: false,
    ).decode(text);

    if (records.isEmpty) {
      return ParsedTable(
        headers: const <String>[],
        rows: const <Map<String, String>>[],
        delimiter: resolvedDelimiter,
      );
    }

    final List<String> headers = normalizeHeaders(records.first);
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

    return ParsedTable(
      headers: headers,
      rows: rows,
      delimiter: resolvedDelimiter,
    );
  }

  /// Builds a short text preview of the first [maxBytes] bytes of a file.
  String buildPreview(List<int> bytes, {int maxBytes = 500}) {
    final List<int> slice = bytes.length > maxBytes
        ? bytes.take(maxBytes).toList()
        : bytes;
    return utf8.decode(slice, allowMalformed: true);
  }

  /// Converts a delimiter character into user-facing text.
  String delimiterDisplayName(String delimiter) {
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
