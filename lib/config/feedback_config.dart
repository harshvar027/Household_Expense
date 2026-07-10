/// Help & feedback configuration.
///
/// Set [syncBaseUrl] to your backend API to collect feedback from all users.
/// Example endpoints: POST /feedback, GET /feedback (admin auth header).
class FeedbackConfig {
  FeedbackConfig._();

  static const appVersion = '1.0.0';
  static const supportEmail = 'krishanshekhawat@gmail.com';
  static const feedbackEmail = supportEmail;

  static const creatorName = 'Krishan Singh Shekhawat';
  static const creatorPhone = '8975505854';
  static const creatorPhoneDisplay = '+91 8975505854';
  static const creatorEmail = supportEmail;

  static const appAboutBrief =
      'Household Expense helps you track daily spending, import bank statements, '
      'set monthly budgets, analyse categories, and export PDF/CSV reports — '
      'with your data stored securely on this device.';

  /// Optional remote API base (no trailing slash). Leave empty for local-only.
  static const syncBaseUrl = '';

  /// Admin username for the developer dashboard.
  static const adminUsername = 'admin';

  /// One-time code to create the admin password on first setup.
  /// Change this before publishing to Google Play.
  static const adminSetupCode = 'CHANGE-BEFORE-PLAY-RELEASE';

  static const adminSessionKey = 'admin_logged_in_v1';
}
