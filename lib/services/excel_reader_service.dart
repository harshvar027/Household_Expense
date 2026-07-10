import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:excel2003/excel2003.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

import 'header_detector.dart';

class ExcelReaderService {
  List<List<String>> readBytes(Uint8List bytes, {String? extension}) {
    if (_shouldReadAsXls(bytes, extension)) {
      return _readXls(bytes);
    }
    return _readXlsx(bytes);
  }

  bool _shouldReadAsXls(Uint8List bytes, String? extension) {
    if (_isOleXls(bytes)) return true;
    final ext = extension?.toLowerCase().replaceFirst('.', '');
    return ext == 'xls';
  }

  bool _isOleXls(Uint8List bytes) {
    return bytes.length >= 4 &&
        bytes[0] == 0xD0 &&
        bytes[1] == 0xCF &&
        bytes[2] == 0x11 &&
        bytes[3] == 0xE0;
  }

  List<List<String>> _readXls(Uint8List bytes) {
    final reader = XlsReader.fromBytes(bytes);
    reader.open();

    List<List<String>>? best;

    for (var i = 0; i < reader.sheetCount; i++) {
      final rows = _normalizeRowWidths(_rowsFromXlsSheet(reader.sheet(i)));
      if (rows.isEmpty) continue;
      best ??= rows;

      if (_looksLikeStatementSheet(rows)) {
        return rows;
      }
    }

    if (best == null || best.isEmpty) {
      throw Exception('Excel file has no readable rows.');
    }
    return best;
  }

  List<List<String>> _readXlsx(Uint8List bytes) {
    try {
      return _readXlsxWithExcelPackage(bytes);
    } catch (e) {
      if (!_isRecoverableXlsxStyleError(e)) rethrow;
      return _readXlsxWithSpreadsheetDecoder(bytes);
    }
  }

  bool _isRecoverableXlsxStyleError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('numfmtid') ||
        message.contains('numfmts') ||
        message.contains('stylesheet');
  }

  List<List<String>> _readXlsxWithExcelPackage(Uint8List bytes) {
    final excel = Excel.decodeBytes(bytes);
    List<List<String>>? best;

    for (final sheetName in excel.tables.keys) {
      final table = excel.tables[sheetName];
      if (table == null) continue;

      final rows = <List<String>>[];
      for (final row in table.rows) {
        final cells = row.map(_xlsxCellText).toList();
        if (cells.any((cell) => cell.isNotEmpty)) {
          rows.add(cells);
        }
      }

      final normalizedRows = _normalizeRowWidths(rows);

      if (normalizedRows.isEmpty) continue;
      best ??= normalizedRows;

      if (_looksLikeStatementSheet(normalizedRows)) {
        return normalizedRows;
      }
    }

    if (best == null || best.isEmpty) {
      throw Exception('Excel file has no readable rows.');
    }
    return best;
  }

  List<List<String>> _readXlsxWithSpreadsheetDecoder(Uint8List bytes) {
    final decoder = SpreadsheetDecoder.decodeBytes(bytes);
    List<List<String>>? best;

    for (final table in decoder.tables.values) {
      final rows = <List<String>>[];
      for (final row in table.rows) {
        final cells = row.map(_decoderCellText).toList();
        if (cells.any((cell) => cell.isNotEmpty)) {
          rows.add(cells);
        }
      }

      final normalizedRows = _normalizeRowWidths(rows);
      if (normalizedRows.isEmpty) continue;
      best ??= normalizedRows;

      if (_looksLikeStatementSheet(normalizedRows)) {
        return normalizedRows;
      }
    }

    if (best == null || best.isEmpty) {
      throw Exception('Excel file has no readable rows.');
    }
    return best;
  }

  /// Reads every column in the sheet grid so DR/CR values stay in the right column.
  List<List<String>> _rowsFromXlsSheet(XlsSheet sheet) {
    final rows = <List<String>>[];
    for (var r = sheet.firstRow; r < sheet.lastRow; r++) {
      final cells = <String>[];
      for (var c = sheet.firstCol; c < sheet.lastCol; c++) {
        cells.add(_cellValueToString(sheet.cell(r, c)));
      }
      if (cells.any((cell) => cell.isNotEmpty)) {
        rows.add(cells);
      }
    }
    return rows;
  }

  /// Pad short rows so empty DR/CR cells do not shift amounts into the wrong column.
  List<List<String>> _normalizeRowWidths(List<List<String>> rows) {
    if (rows.isEmpty) return rows;

    final headerIndex = HeaderDetector.findHeaderRowIndex(rows);
    final width = headerIndex != null
        ? rows[headerIndex].length
        : rows.fold<int>(0, (max, row) => row.length > max ? row.length : max);

    return rows.map((row) {
      if (row.length >= width) return row;
      return [...row, ...List.filled(width - row.length, '')];
    }).toList();
  }

  bool _looksLikeStatementSheet(List<List<String>> rows) {
    final joined =
        rows.take(25).map((r) => r.join('|').toLowerCase()).join('\n');
    return joined.contains('date') &&
        (joined.contains('narration') ||
            joined.contains('particular') ||
            joined.contains('description') ||
            joined.contains('remarks'));
  }

  String _xlsxCellText(Data? cell) {
    if (cell == null || cell.value == null) return '';
    return _normalizeCellText(cell.value);
  }

  String _decoderCellText(dynamic cell) {
    if (cell == null) return '';
    return _normalizeCellText(cell);
  }

  String _normalizeCellText(dynamic value) {
    if (value is DateTime) {
      return '${value.year.toString().padLeft(4, '0')}-'
          '${value.month.toString().padLeft(2, '0')}-'
          '${value.day.toString().padLeft(2, '0')}';
    }
    return value
        .toString()
        .replaceAll(RegExp(r'[\r\n]+'), ' ')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
  }

  String _cellValueToString(dynamic value) {
    if (value == null) return '';
    return _normalizeCellText(value);
  }
}
