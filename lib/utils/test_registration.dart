import 'package:flutter/material.dart';

import '../screens/auth/register_screen.dart';
import '../services/auth_service.dart';

/// Confirms replacing the on-device account for registration testing.
Future<bool> confirmTestRegistration(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Test: register new user?'),
      content: const Text(
        'This clears the current sign-in profile on this device so you can '
        'test registration again (India, US, UK, Europe, etc.).\n\n'
        'Expense data in the app is kept. Release builds do not allow this.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Continue'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

Future<void> startTestRegistrationFlow(
  BuildContext context, {
  required VoidCallback onCompleted,
}) async {
  if (!await confirmTestRegistration(context)) return;
  if (!context.mounted) return;
  await AuthService.instance.prepareForTestRegistration();
  if (!context.mounted) return;
  await Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => RegisterScreen(onCompleted: onCompleted),
    ),
  );
}
