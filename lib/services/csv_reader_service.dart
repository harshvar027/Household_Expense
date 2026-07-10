import 'package:csv/csv.dart';

class CsvReaderService {
  List<List<dynamic>> readCsvContent(String input) {
    const converter = CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
      allowInvalid: true,
    );

    final rows = converter.convert(input);

    return rows
        .map((row) => row.map((cell) => cell.toString().trim()).toList())
        .where((row) => row.any((cell) => cell.isNotEmpty))
        .toList();
  }
}
