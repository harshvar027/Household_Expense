/// Indicative account label for imported bank transactions.
const accountNotePrefix = 'Account:';

String formatAccountNote(String accountName) {
  final trimmed = accountName.trim();
  if (trimmed.isEmpty) return '';
  return '$accountNotePrefix $trimmed';
}

String? accountNameFromNote(String? notes) {
  final text = notes?.split('\n').first.trim();
  if (text == null || text.isEmpty) return null;
  if (!text.startsWith(accountNotePrefix)) return null;
  final name = text.substring(accountNotePrefix.length).trim();
  return name.isEmpty ? null : name;
}

String? bankNameFromNote(String? notes) {
  if (notes == null) return null;
  for (final line in notes.split('\n')) {
    final text = line.trim();
    if (text.startsWith('Bank:')) {
      final name = text.substring('Bank:'.length).trim();
      if (name.isNotEmpty) return name;
    }
  }
  return null;
}

String buildImportNotes({
  String? accountName,
  String? bankName,
}) {
  final lines = <String>[];
  if (accountName != null && accountName.trim().isNotEmpty) {
    lines.add(formatAccountNote(accountName));
  }
  if (bankName != null && bankName.trim().isNotEmpty) {
    lines.add('Bank: $bankName');
  }
  return lines.join('\n');
}

String buildPaymentMeta({
  required String paymentMethod,
  String? accountName,
  String? bankName,
}) {
  final parts = <String>[];
  if (paymentMethod.trim().isNotEmpty) parts.add(paymentMethod.trim());
  if (bankName != null && bankName.trim().isNotEmpty) parts.add(bankName.trim());
  if (accountName != null && accountName.trim().isNotEmpty) {
    parts.add(accountName.trim());
  }
  return parts.join(' · ');
}
