/// Why registration may be blocked on this device.
enum RegistrationBlockReason {
  allowed,
  deviceAlreadyRegistered,
  identityMatchesExisting,
}

class RegistrationCheck {
  final RegistrationBlockReason reason;
  final String? maskedEmail;
  final String? maskedPhone;

  const RegistrationCheck({
    required this.reason,
    this.maskedEmail,
    this.maskedPhone,
  });

  bool get allowed => reason == RegistrationBlockReason.allowed;

  String get message {
    switch (reason) {
      case RegistrationBlockReason.allowed:
        return '';
      case RegistrationBlockReason.identityMatchesExisting:
        return 'An account with this email and mobile number already exists '
            'on this device. Sign in or use Forgot PIN / password.';
      case RegistrationBlockReason.deviceAlreadyRegistered:
        if (maskedEmail == null && maskedPhone == null) {
          return 'This device already has a household account. '
              'Restore your backup, sign in, or re-create your account using '
              'the same email and mobile number from your original registration. '
              'A second account is not allowed on this device.';
        }
        final email = maskedEmail ?? 'your email';
        final phone = maskedPhone ?? 'your mobile';
        return 'This device already has a household account ($email, $phone). '
            'Sign in or reset your PIN — you cannot create a second account here.';
    }
  }
}
