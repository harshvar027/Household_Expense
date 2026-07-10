import 'package:file_selector/file_selector.dart';

/// Apple platforms require [uniformTypeIdentifiers] on [XTypeGroup].
class FileTypeGroups {
  FileTypeGroups._();

  static const csv = XTypeGroup(
    label: 'CSV files',
    extensions: ['csv'],
    mimeTypes: [
      'text/csv',
      'text/comma-separated-values',
      'application/csv',
    ],
    uniformTypeIdentifiers: [
      'public.comma-separated-values-text',
      'public.plain-text',
      'public.text',
    ],
  );

  static const bankStatement = XTypeGroup(
    label: 'Bank statements',
    extensions: ['csv', 'xlsx', 'xls', 'pdf'],
    mimeTypes: [
      'text/csv',
      'text/comma-separated-values',
      'application/csv',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'application/vnd.ms-excel',
      'application/pdf',
    ],
    uniformTypeIdentifiers: [
      'public.comma-separated-values-text',
      'org.openxmlformats.spreadsheetml.sheet',
      'com.microsoft.excel.xls',
      'com.adobe.pdf',
      'public.data',
      'public.content',
    ],
  );

  static const json = XTypeGroup(
    label: 'JSON',
    extensions: ['json'],
    mimeTypes: ['application/json'],
    uniformTypeIdentifiers: ['public.json', 'public.text'],
  );
}
