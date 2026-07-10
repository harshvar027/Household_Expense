import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:share_plus/share_plus.dart';

import '../config/feedback_config.dart';
import '../models/user_feedback.dart';
import 'auth_service.dart';

class FeedbackEmailException implements Exception {
  final String message;
  const FeedbackEmailException(this.message);

  @override
  String toString() => message;
}

class FeedbackEmailService {
  FeedbackEmailService._();

  static final FeedbackEmailService instance = FeedbackEmailService._();

  Future<bool> sendFeedbackEmail(UserFeedback feedback) async {
    final subject = _emailSubject(feedback);
    final body = _emailBody(feedback);

    return AuthService.instance.runWithNativeSheetGuard(() async {
      try {
        await FlutterEmailSender.send(
          Email(
            body: body,
            subject: subject,
            recipients: [FeedbackConfig.feedbackEmail],
            isHTML: false,
          ),
        );
        return true;
      } on FlutterEmailSenderNotAvailableException {
        // Fall through to share sheet.
      }

      await SharePlus.instance.share(
        ShareParams(
          text:
              'To: ${FeedbackConfig.feedbackEmail}\n'
              'Subject: $subject\n\n'
              '$body',
          subject: subject,
        ),
      );
      return true;
    });
  }

  Future<bool> openSupportEmail({
    String subject = 'Household Expense - Help request',
    String? body,
  }) async {
    return sendFeedbackEmail(
      UserFeedback(
        category: FeedbackCategory.general,
        subject: subject,
        message: body ?? 'I need help with Household Expense.',
        appVersion: FeedbackConfig.appVersion,
        createdAt: DateTime.now(),
      ),
    );
  }

  String _emailSubject(UserFeedback feedback) {
    return '[Household Expense - ${feedback.category.label}] ${feedback.subject}';
  }

  String _emailBody(UserFeedback feedback) {
    final name = feedback.userName.trim().isEmpty
        ? 'Not provided'
        : feedback.userName.trim();
    final email = feedback.userEmail.trim().isEmpty
        ? 'Not provided'
        : feedback.userEmail.trim();
    final phone = feedback.userPhone.trim().isEmpty
        ? 'Not provided'
        : feedback.userPhone.trim();

    return [
      'Household Expense feedback',
      '',
      'Category: ${feedback.category.label}',
      'Subject: ${feedback.subject}',
      '',
      'Sender details',
      'Name: $name',
      'Email: $email',
      'Phone: $phone',
      'App version: ${feedback.appVersion}',
      'Submitted: ${feedback.createdAt.toIso8601String()}',
      '',
      'Message',
      feedback.message,
    ].join('\n');
  }
}
