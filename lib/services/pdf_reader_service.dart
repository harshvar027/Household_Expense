import 'dart:typed_data';

import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../exceptions/pdf_password_exception.dart';

class PdfReaderService {
  String extractText(Uint8List bytes, {String? password}) {
    PdfDocument? document;
    try {
      document = PdfDocument(inputBytes: bytes, password: password);
      final extractor = PdfTextExtractor(document);

      final fullText = extractor.extractText().trim();

      final pageBuffer = StringBuffer();
      for (var i = 0; i < document.pages.count; i++) {
        final pageText = extractor
            .extractText(startPageIndex: i, endPageIndex: i)
            .trim();
        if (pageText.isNotEmpty) {
          pageBuffer.writeln(pageText);
        }
      }
      final perPageText = pageBuffer.toString().trim();

      if (fullText.length >= perPageText.length) {
        return fullText;
      }
      return perPageText;
    } on ArgumentError catch (e) {
      if (isPdfPasswordArgumentError(e)) {
        throw PdfPasswordException(
          passwordProvided: password != null && password.isNotEmpty,
        );
      }
      rethrow;
    } finally {
      document?.dispose();
    }
  }
}
