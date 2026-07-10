import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:household_expense/utils/file_type_sniffer.dart';

void main() {
  group('FileTypeSniffer', () {
    test('detects PDF from magic bytes when filename has no extension', () {
      final bytes = Uint8List.fromList('%PDF-1.4'.codeUnits);
      expect(
        FileTypeSniffer.resolveExtension(fileName: 'download', bytes: bytes),
        '.pdf',
      );
    });

    test('detects PDF from mime type', () {
      expect(
        FileTypeSniffer.resolveExtension(
          fileName: 'statement',
          bytes: Uint8List(0),
          mimeType: 'application/pdf',
        ),
        '.pdf',
      );
    });

    test('resolves filename with extension from bytes', () {
      final bytes = Uint8List.fromList('%PDF-1.4'.codeUnits);
      expect(
        FileTypeSniffer.resolveFileName(fileName: 'import.csv', bytes: bytes),
        'statement.pdf',
      );
    });
  });
}
