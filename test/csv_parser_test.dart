import 'package:flutter_test/flutter_test.dart';
import 'package:readcsv/features/datasets/data/csv_parser.dart';

void main() {
  const CsvParser parser = CsvParser();

  group('detectDelimiter', () {
    test('detects comma separated values', () {
      const String text = 'a,b,c\n1,2,3\n4,5,6';
      expect(parser.detectDelimiter(text), ',');
    });

    test('detects semicolon separated values', () {
      const String text = 'a;b;c\n1;2;3\n4;5;6';
      expect(parser.detectDelimiter(text), ';');
    });

    test('detects tab separated values', () {
      const String text = 'a\tb\tc\n1\t2\t3';
      expect(parser.detectDelimiter(text), '\t');
    });

    test('detects pipe separated values', () {
      const String text = 'a|b|c\n1|2|3';
      expect(parser.detectDelimiter(text), '|');
    });

    test('falls back to comma for empty text', () {
      expect(parser.detectDelimiter(''), ',');
    });

    test('falls back to comma for whitespace-only text', () {
      expect(parser.detectDelimiter('   \n  \n '), ',');
    });

    test('ignores carriage return line endings', () {
      const String text = 'a;b\r\n1;2\r\n3;4';
      expect(parser.detectDelimiter(text), ';');
    });
  });

  group('normalizeHeaders', () {
    test('trims whitespace from header names', () {
      final List<String> result = parser.normalizeHeaders(<dynamic>[
        '  name  ',
        ' age',
      ]);
      expect(result, <String>['name', 'age']);
    });

    test('strips a UTF-8 byte-order mark from the first header', () {
      final List<String> result = parser.normalizeHeaders(<dynamic>[
        '﻿name',
        'age',
      ]);
      expect(result, <String>['name', 'age']);
    });

    test('generates names for blank headers', () {
      final List<String> result = parser.normalizeHeaders(<dynamic>[
        '',
        '   ',
        'age',
      ]);
      expect(result, <String>['col_1', 'col_2', 'age']);
    });

    test('suffixes duplicate headers with an incrementing counter', () {
      final List<String> result = parser.normalizeHeaders(<dynamic>[
        'name',
        'name',
        'name',
      ]);
      expect(result, <String>['name', 'name (2)', 'name (3)']);
    });

    test('treats header collisions case-insensitively', () {
      final List<String> result = parser.normalizeHeaders(<dynamic>[
        'Name',
        'name',
      ]);
      expect(result, <String>['Name', 'name (2)']);
    });

    test('returns an empty list for no headers', () {
      expect(parser.normalizeHeaders(<dynamic>[]), isEmpty);
    });
  });

  group('parse', () {
    test('treats the first record as the header row', () {
      const String text = 'name,age\nAda,36\nGrace,45';
      final ParsedTable table = parser.parse(text);

      expect(table.headers, <String>['name', 'age']);
      expect(table.rows, hasLength(2));
      expect(table.rows.first, <String, String>{'name': 'Ada', 'age': '36'});
      expect(table.delimiter, ',');
    });

    test('skips completely empty data rows', () {
      const String text = 'name,age\nAda,36\n,\nGrace,45';
      final ParsedTable table = parser.parse(text);

      expect(table.rows, hasLength(2));
    });

    test('keeps rows that contain a value in any column', () {
      const String text = 'name,age\n,36\n,';
      final ParsedTable table = parser.parse(text);

      expect(table.rows, hasLength(1));
      expect(table.rows.single['age'], '36');
    });

    test('pads short rows with empty values', () {
      const String text = 'a,b,c\n1';
      final ParsedTable table = parser.parse(text);

      expect(table.rows.single, <String, String>{'a': '1', 'b': '', 'c': ''});
    });

    test('returns empty results for empty text', () {
      final ParsedTable table = parser.parse('');

      expect(table.headers, isEmpty);
      expect(table.rows, isEmpty);
    });

    test('honours an explicit delimiter over detection', () {
      const String text = 'a;b\n1;2';
      final ParsedTable table = parser.parse(text, delimiter: ';');

      expect(table.headers, <String>['a', 'b']);
      expect(table.delimiter, ';');
    });

    test('auto-detects a semicolon delimiter without an override', () {
      const String text = 'a;b;c\n1;2;3';
      final ParsedTable table = parser.parse(text);

      expect(table.headers, <String>['a', 'b', 'c']);
      expect(table.rows, hasLength(1));
    });
  });

  group('buildPreview', () {
    test('returns the whole payload when it is under the limit', () {
      expect(parser.buildPreview(<int>[104, 105]), 'hi');
    });

    test('truncates to the requested byte count', () {
      final List<int> bytes = 'abcdefgh'.codeUnits;
      expect(parser.buildPreview(bytes, maxBytes: 3), 'abc');
    });

    test('replaces malformed UTF-8 instead of throwing', () {
      final List<int> bytes = <int>[0xC3, 0x28];
      expect(() => parser.buildPreview(bytes), returnsNormally);
    });
  });

  group('delimiterDisplayName', () {
    test('names each supported delimiter', () {
      expect(parser.delimiterDisplayName(','), 'comma (,)');
      expect(parser.delimiterDisplayName(';'), 'semicolon (;)');
      expect(parser.delimiterDisplayName('\t'), 'tab');
      expect(parser.delimiterDisplayName('|'), 'pipe (|)');
    });

    test('falls back to custom for anything else', () {
      expect(parser.delimiterDisplayName('#'), 'custom');
    });
  });
}
