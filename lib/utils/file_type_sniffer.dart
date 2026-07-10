import 'dart:typed_data';

import 'package:path/path.dart' as p;

/// Detects bank statement file type when the filename or extension is missing/wrong
/// (common when picking PDFs from Android Downloads).
class FileTypeSniffer {
  static const supportedExtensions = {'.csv', '.xlsx', '.xls', '.pdf'};

  static String resolveExtension({
    required String fileName,
    required Uint8List bytes,
    String? mimeType,
  }) {
    final strongBytes = _strongTypeFromBytes(bytes);
    final fromName = _fromFileName(fileName);

    if (strongBytes != null && fromName != null && fromName != strongBytes) {
      return strongBytes;
    }
    if (fromName != null) return fromName;

    final fromMime = _fromMime(mimeType);
    if (fromMime != null) return fromMime;

    return _fromBytes(bytes);
  }

  static String resolveFileName({
    required String fileName,
    required Uint8List bytes,
    String? mimeType,
  }) {
    final ext = resolveExtension(
      fileName: fileName,
      bytes: bytes,
      mimeType: mimeType,
    );
    final currentExt = p.extension(fileName.toLowerCase());
    if (currentExt == ext) return fileName;

    final base = p.basenameWithoutExtension(fileName);
    final normalizedBase =
        base.isEmpty || base == 'import' || base == 'statement' ? 'statement' : base;
    return '$normalizedBase$ext';
  }

  static String? _fromFileName(String fileName) {
    final ext = p.extension(fileName.toLowerCase());
    if (supportedExtensions.contains(ext)) return ext;
    return null;
  }

  static String? _fromMime(String? mimeType) {
    if (mimeType == null || mimeType.isEmpty) return null;
    final mime = mimeType.toLowerCase();
    if (mime.contains('pdf')) return '.pdf';
    if (mime.contains('spreadsheetml') || mime.contains('openxmlformats')) {
      return '.xlsx';
    }
    if (mime.contains('ms-excel')) return '.xls';
    if (mime.contains('csv') || mime == 'text/plain') return '.csv';
    return null;
  }

  static String _fromBytes(Uint8List bytes) {
    final strong = _strongTypeFromBytes(bytes);
    if (strong != null) return strong;
    return '.csv';
  }

  static String? _strongTypeFromBytes(Uint8List bytes) {
    if (bytes.length >= 4 &&
        bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46) {
      return '.pdf';
    }

    if (bytes.length >= 2 && bytes[0] == 0x50 && bytes[1] == 0x4B) {
      return '.xlsx';
    }

    if (bytes.length >= 4 &&
        bytes[0] == 0xD0 &&
        bytes[1] == 0xCF &&
        bytes[2] == 0x11 &&
        bytes[3] == 0xE0) {
      return '.xls';
    }

    return null;
  }
}
