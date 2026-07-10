import 'package:flutter/material.dart';

import '../config/feedback_config.dart';
import '../models/user_feedback.dart';
import '../models/user_profile.dart';
import '../services/feedback_email_service.dart';
import '../services/feedback_service.dart';
import '../theme/app_theme.dart';
import '../utils/auth_validators.dart';
import '../widgets/ui/app_scaffold.dart';

class FeedbackScreen extends StatefulWidget {
  final UserProfile? userProfile;
  final FeedbackCategory? initialCategory;

  const FeedbackScreen({
    super.key,
    this.userProfile,
    this.initialCategory,
  });

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  late FeedbackCategory _category =
      widget.initialCategory ?? FeedbackCategory.general;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.userProfile;
    if (profile != null) {
      _nameController.text = profile.name;
      _emailController.text = profile.email;
      _phoneController.text = profile.phone;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final feedback = UserFeedback(
        category: _category,
        subject: _subjectController.text.trim(),
        message: _messageController.text.trim(),
        userName: _nameController.text.trim(),
        userEmail: _emailController.text.trim(),
        userPhone: _phoneController.text.trim(),
        appVersion: FeedbackConfig.appVersion,
        createdAt: DateTime.now(),
      );

      final id = await FeedbackService.instance.submit(
        category: feedback.category,
        subject: feedback.subject,
        message: feedback.message,
        userName: feedback.userName,
        userEmail: feedback.userEmail,
        userPhone: feedback.userPhone,
      );

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);

      final emailOpened = await FeedbackEmailService.instance.sendFeedbackEmail(
        feedback.copyWith(id: id),
      );

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            emailOpened
                ? 'Email app opened — tap Send to deliver your feedback.'
                : 'Feedback saved locally. Could not open email app.',
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScreenScaffold(
      title: 'Send feedback',
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const Text(
              'Your message opens in your email app addressed to the developer, '
              'with your name and contact details included.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              enabled: !_submitting,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Your name',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().length < 2 ? 'Enter your name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              enabled: !_submitting,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Your email',
                border: OutlineInputBorder(),
              ),
              validator: AuthValidators.email,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              enabled: !_submitting,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Mobile number (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<FeedbackCategory>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: FeedbackCategory.values
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(c.label),
                    ),
                  )
                  .toList(),
              onChanged: _submitting
                  ? null
                  : (v) {
                      if (v != null) setState(() => _category = v);
                    },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _subjectController,
              enabled: !_submitting,
              decoration: const InputDecoration(
                labelText: 'Subject',
                hintText: 'Short summary',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().length < 3 ? 'Enter a subject' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _messageController,
              enabled: !_submitting,
              maxLines: 8,
              decoration: InputDecoration(
                labelText: 'Details',
                hintText: _category.hint,
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (v) =>
                  v == null || v.trim().length < 10 ? 'Please add more detail' : null,
            ),
            const SizedBox(height: 24),
            PrimaryActionButton(
              onPressed: _submitting ? null : _submit,
              icon: Icons.email_outlined,
              label: 'Send feedback by email',
              loading: _submitting,
            ),
          ],
        ),
      ),
    );
  }
}
