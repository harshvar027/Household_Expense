import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/subscription_config.dart';
import '../../services/auth_service.dart';
import '../../services/device_enrollment_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui/app_logo.dart';
import '../../widgets/ui/glass_surface.dart';
import '../../widgets/ui/mesh_background.dart';
import 'login_screen.dart';
import 'register_screen.dart';

/// First-time entry — one household account per device.
class WelcomeAuthScreen extends StatefulWidget {
  final VoidCallback onRegistered;

  /// Called after a successful unlock from the Sign in path.
  final VoidCallback onSignedIn;

  const WelcomeAuthScreen({
    super.key,
    required this.onRegistered,
    required this.onSignedIn,
  });

  @override
  State<WelcomeAuthScreen> createState() => _WelcomeAuthScreenState();
}

class _WelcomeAuthScreenState extends State<WelcomeAuthScreen> {
  bool _deviceEnrolled = false;
  bool _canSignIn = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final enrolled = await DeviceEnrollmentService.instance.isEnrolled();
    final canSignIn = await AuthService.instance.hasAccount() ||
        await AuthService.instance.hasUnlockCredential();
    if (!mounted) return;
    setState(() {
      _deviceEnrolled = enrolled;
      _canSignIn = canSignIn || enrolled;
    });
  }

  Future<void> _openSignIn() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (loginContext) => LoginScreen(
          onSuccess: () {
            // Pop the pushed unlock screen, then let AuthGate switch to the app.
            if (loginContext.mounted) {
              Navigator.of(loginContext).pop();
            }
            widget.onSignedIn();
          },
        ),
      ),
    );
  }

  Future<void> _openRegister() async {
    // Do not pre-block without email/phone — enrolled devices must be able to
    // open the form and re-create with the same identity.
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => RegisterScreen(onCompleted: widget.onRegistered),
      ),
    );
  }

  Future<void> _showAlreadyRegisteredHelp() async {
    final check = await AuthService.instance.checkRegistrationAllowed();
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Account already on this device'),
        content: Text(check.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          if (_canSignIn)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _openSignIn();
              },
              child: const Text('Sign in'),
            ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _openRegister();
            },
            child: const Text('Re-create account'),
          ),
        ],
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
                    const AppLogo(size: 112)
                        .animate()
                        .scale(duration: 500.ms, curve: Curves.easeOutBack),
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
                              'Sign in with your PIN, or re-create the account using the '
                              'same email and mobile number. You can restore a backup from Menu after sign-in.'
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
                            _deviceEnrolled ? 'Continue' : 'New here?',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _deviceEnrolled
                                ? 'Only one household account is allowed on this device. '
                                    'Use Sign in if you still have your PIN. '
                                    'Use Re-create only with the same email and mobile number — '
                                    'your original free-trial period still applies.'
                                : 'Create one household account per device. '
                                    'You will set a PIN, email, and mobile number for local sign-in and recovery.',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              height: 1.4,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (_deviceEnrolled || _canSignIn) ...[
                            FilledButton.icon(
                              onPressed: _openSignIn,
                              icon: const Icon(Icons.login_rounded),
                              label: const Text('Sign in'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _openRegister,
                              icon: const Icon(Icons.restore_rounded),
                              label: const Text('Re-create my account'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _showAlreadyRegisteredHelp,
                              child: const Text('Why can’t I create a new account?'),
                            ),
                          ] else
                            FilledButton.icon(
                              onPressed: _openRegister,
                              icon: const Icon(Icons.person_add_outlined),
                              label: const Text('Create account'),
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
