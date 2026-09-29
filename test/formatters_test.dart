import 'package:flutter_test/flutter_test.dart';
import 'package:readcsv/core/utils/formatters.dart';

void main() {
  group('formatFileSize', () {
    test('formats raw bytes below one kibibyte', () {
      expect(formatFileSize(0), '0 B');
      expect(formatFileSize(512), '512 B');
      expect(formatFileSize(1023), '1023 B');
    });

    test('formats kibibytes below one mebibyte', () {
      expect(formatFileSize(1024), '1.0 KB');
      expect(formatFileSize(1536), '1.5 KB');
      expect(formatFileSize(1024 * 1024 - 1), '1024.0 KB');
    });

    test('formats mebibytes from one mebibyte upward', () {
      expect(formatFileSize(1024 * 1024), '1.0 MB');
      expect(formatFileSize(5 * 1024 * 1024), '5.0 MB');
    });
  });
}
