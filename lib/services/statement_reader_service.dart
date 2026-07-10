import 'dart:convert';
import 'dart:typed_data';

import '../utils/file_type_sniffer.dart';
import '../models/bank_profile.dart';
import 'csv_reader_service.dart';
import 'excel_reader_service.dart';
import 'pdf_reader_service.dart';
import 'pdf_statement_parser.dart';

class StatementReadResult {
  final List<List<dynamic>> rows;
  final String? rawText;

  const StatementReadResult({required this.rows, this.rawText});
}

class StatementReaderService {
  final _csv = CsvReaderService();
  final _excel = ExcelReaderService();
  final _pdfText = PdfReaderService();
  final _pdfParser = PdfStatementParser();

  StatementReadResult read(
    String fileName,
    Uint8List bytes, {
    String? mimeType,
    String? pdfPassword,
    BankId? bankId,
  }) {
    final ext = FileTypeSniffer.resolveExtension(
      fileName: fileName,
      bytes: bytes,
      mimeType: mimeType,
    );

    switch (ext) {
      case '.csv':
        final content = utf8.decode(bytes, allowMalformed: true);
        return StatementReadResult(
          rows: _csv.readCsvContent(content),
          rawText: content,
        );
      case '.xlsx':
      case '.xls':
        return StatementReadResult(
          rows: _excel.readBytes(bytes, extension: ext),
        );
      case '.pdf':
        final text = _pdfText.extractText(bytes, password: pdfPassword);
        if (text.trim().isEmpty) {
          throw Exception(
            'PDF has no readable text layer. Scanned or image PDFs are not supported — '
            'download CSV or Excel from your bank instead.',
          );
        }
        return StatementReadResult(
          rows: _pdfParser.toRows(text, bankId: bankId),
          rawText: text,
        );
      default:
        throw Exception(
          'Unsupported file type "$ext". Use CSV, Excel (.xls/.xlsx), or PDF.',
        );
    }
  }
}
