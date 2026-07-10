import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/subscription_config.dart';
import '../../services/auth_service.dart';
import '../../services/device_enrollment_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui/finance_illustration.dart';
import '../../widgets/ui/glass_surface.dart';
import '../../widgets/ui/mesh_background.dart';
import 'register_screen.dart';

/// First-time entry — one household account per device.
class WelcomeAuthScreen extends StatefulWidget {
  final VoidCallback onRegistered;

  const WelcomeAuthScreen({super.key, required this.onRegistered});

  @override
  State<WelcomeAuthScreen> createState() => _WelcomeAuthScreenState();
}

class _WelcomeAuthScreenState extends State<WelcomeAuthScreen> {
  bool _deviceEnrolled = false;

  @override
  void initState() {
    super.initState();
    _loadEnrollment();
  }

  Future<void> _loadEnrollment() async {
    final enrolled = await DeviceEnrollmentService.instance.isEnrolled();
    if (!mounted) return;
    setState(() => _deviceEnrolled = enrolled);
  }

  Future<void> _openRegister(BuildContext context) async {
    final check = await AuthService.instance.checkRegistrationAllowed();
    if (!context.mounted) return;

    if (!check.allowed) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Account already on this device'),
          content: Text(check.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => RegisterScreen(onCompleted: widget.onRegistered),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MeshBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  children: [
                    const FinanceIllustration(
                      type: FinanceIllustrationType.wallet,
                      size: 88,
                    ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                    const SizedBox(height: 24),
                    Text(
                      'Household Expense',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _deviceEnrolled
                          ? 'Welcome back. This device already has a household account. '
                              'Re-create it with the same email and mobile number, or restore '
                              'your backup from Menu after sign-in.'
                          : 'Track spending, import bank statements, and manage your household budget — all on this device.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 28),
                    GlassSurface.card(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _deviceEnrolled ? 'Restore your account' : 'New here?',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _deviceEnrolled
                                ? 'Only one household account is allowed on this device. '
                                    'Use the same email and mobile number as before to set a new PIN. '
                                    'Your original free-trial period still applies.'
                                : 'Create one household account per device. '
                                    'You will set a PIN, email, and mobile number for local sign-in and recovery.',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              height: 1.4,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: () => _openRegister(context),
                            icon: Icon(
                              _deviceEnrolled
                                  ? Icons.restore_rounded
                                  : Icons.person_add_outlined,
                            ),
                            label: Text(
                              _deviceEnrolled
                                  ? 'Re-create my account'
                                  : 'Create account',
                            ),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _deviceEnrolled
                          ? 'After the ${SubscriptionConfig.freeTrialMonths}-month free trial, a yearly subscription is required to continue using the app.'
                          : 'Already registered? After setup you unlock with your PIN each time you open the app.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted.withValues(alpha: 0.9),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
