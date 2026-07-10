import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/feedback_config.dart';
import '../models/user_feedback.dart';
import '../models/user_profile.dart';
import '../services/feedback_email_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ui/app_scaffold.dart';
import '../widgets/ui/glass_surface.dart';
import 'admin/admin_login_screen.dart';
import 'feedback_screen.dart';

class HelpAboutScreen extends StatefulWidget {
  final UserProfile? userProfile;

  const HelpAboutScreen({super.key, this.userProfile});

  @override
  State<HelpAboutScreen> createState() => _HelpAboutScreenState();
}

class _HelpAboutScreenState extends State<HelpAboutScreen> {
  int _versionTapCount = 0;

  void _onVersionTap() {
    _versionTapCount++;
    if (_versionTapCount >= 5) {
      _versionTapCount = 0;
      Navigator.push(
        context,
        appPageRoute(const AdminLoginScreen()),
      );
    }
  }

  Future<void> _launchExternal(Uri uri) async {
    HapticFeedback.lightImpact();
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open ${uri.scheme} link on this device.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScreenScaffold(
      title: 'Help & About',
      scrollBody: true,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          GlassSurface.card(
            padding: const EdgeInsets.all(22),
            borderRadius: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Household Expense',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _onVersionTap,
                  child: Text(
                    'Version ${FeedbackConfig.appVersion}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  FeedbackConfig.appAboutBrief,
                  style: const TextStyle(height: 1.45, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'ABOUT',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          GlassSurface.card(
            padding: const EdgeInsets.all(20),
            borderRadius: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Created by',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  FeedbackConfig.creatorName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Contact for app enhancement, support, or feedback',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                _AboutContactRow(
                  icon: Icons.phone_outlined,
                  label: 'Mobile',
                  value: FeedbackConfig.creatorPhoneDisplay,
                  onTap: () => _launchExternal(
                    Uri(scheme: 'tel', path: FeedbackConfig.creatorPhone),
                  ),
                ),
                const SizedBox(height: 10),
                _AboutContactRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: FeedbackConfig.creatorEmail,
                  onTap: () => _launchExternal(
                    Uri(
                      scheme: 'mailto',
                      path: FeedbackConfig.creatorEmail,
                      query: 'subject=Household Expense - App enhancement',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'GET HELP',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          _HelpTile(
            icon: Icons.feedback_outlined,
            title: 'Send feedback',
            subtitle: 'Email bug reports, ideas, or questions',
            color: AppColors.primary,
            onTap: () {
              Navigator.push(
                context,
                appPageRoute(
                  FeedbackScreen(userProfile: widget.userProfile),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          _HelpTile(
            icon: Icons.bug_report_outlined,
            title: 'Report a problem',
            subtitle: 'Email details when something is not working',
            color: AppColors.expense,
            onTap: () {
              Navigator.push(
                context,
                appPageRoute(
                  FeedbackScreen(
                    userProfile: widget.userProfile,
                    initialCategory: FeedbackCategory.bug,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          _HelpTile(
            icon: Icons.lightbulb_outline_rounded,
            title: 'Request a feature',
            subtitle: 'Email suggestions to improve the app',
            color: AppColors.warning,
            onTap: () {
              Navigator.push(
                context,
                appPageRoute(
                  FeedbackScreen(
                    userProfile: widget.userProfile,
                    initialCategory: FeedbackCategory.feature,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'QUICK TIPS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          GlassSurface.card(
            padding: const EdgeInsets.all(18),
            borderRadius: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _TipRow('Use Menu → Import Bank for CSV/Excel/PDF statements'),
                SizedBox(height: 10),
                _TipRow('Premium plans unlock backup, export, and bank import'),
                SizedBox(height: 10),
                _TipRow('Your data is encrypted locally on this device'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: InkWell(
              onTap: () async {
                HapticFeedback.lightImpact();
                final opened = await FeedbackEmailService.instance
                    .openSupportEmail();
                if (!context.mounted) return;
                if (!opened) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Could not open an email app on this device.'),
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  'Email support: ${FeedbackConfig.supportEmail}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _AboutContactRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.open_in_new_rounded, size: 16, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _HelpTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final String text;

  const _TipRow(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle_outline, size: 18, color: AppColors.income),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ],
    );
  }
}
