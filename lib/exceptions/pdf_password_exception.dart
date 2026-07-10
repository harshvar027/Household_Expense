/// Thrown when a PDF statement needs a password to open.
class PdfPasswordException implements Exception {
  const PdfPasswordException({this.passwordProvided = false});

  /// True when a password was supplied but did not unlock the file.
  final bool passwordProvided;

  String get message => passwordProvided
      ? 'Incorrect PDF password. Please try again.'
      : 'This PDF is password-protected. Enter the password to continue.';

  @override
  String toString() => message;
}

bool isPdfPasswordArgumentError(Object error) {
  if (error is! ArgumentError) return false;
  if (error.name == 'password') return true;
  final message = error.message?.toString().toLowerCase() ?? '';
  return message.contains('encrypted') && message.contains('password');
}
