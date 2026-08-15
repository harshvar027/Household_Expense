import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/user_profile.dart';
import '../../config/dev_auth_config.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_auth_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/auth_validators.dart';
import '../../utils/test_registration.dart';
import '../../widgets/ui/app_logo.dart';
import '../../widgets/ui/glass_surface.dart';
import '../../widgets/ui/mesh_background.dart';
import 'forgot_credentials_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onSuccess;

  const LoginScreen({super.key, required this.onSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _secretController = TextEditingController();

  bool _obscureSecret = true;
  bool _loading = false;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  String? _error;
  UserProfile? _profile;
  AuthLockMethod _lockMethod = AuthLockMethod.pin;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Show the form as soon as auth context is ready; biometrics can follow.
    await _loadContext();
    if (!mounted) return;
    unawaited(_tryBiometricUnlock());
  }

  Future<void> _loadContext() async {
    final results = await Future.wait([
      AuthService.instance.loadLoginUnlockContext(),
      BiometricAuthService.instance.isAvailable(),
    ]);
    final context =
        results[0] as ({UserProfile? profile, AuthLockMethod method, bool biometricEnabled});
    final bioAvailable = results[1] as bool;

    if (!mounted) return;
    setState(() {
      _profile = context.profile;
      _lockMethod = context.method;
      _biometricEnabled = context.biometricEnabled;
      _biometricAvailable = bioAvailable;
      if (context.profile != null && _identifierController.text.isEmpty) {
        _identifierController.text = context.profile!.email;
      }
    });
  }

  Future<void> _tryBiometricUnlock() async {
    if (!_biometricEnabled || !_biometricAvailable || _loading) return;
    if (_profile == null) return;

    final ok = await BiometricAuthService.instance.authenticate(
      reason: 'Unlock your household expense tracker',
      skipAvailabilityCheck: true,
    );
    if (!ok || !mounted) return;

    await AuthService.instance.unlockSession();
    widget.onSuccess();
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _secretController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final ok = await AuthService.instance.login(
      identifier: _identifierController.text.trim(),
      secret: _secretController.text.trim(),
    );

    if (!mounted) return;

    if (ok) {
      setState(() => _loading = false);
      widget.onSuccess();
      return;
    }

    setState(() {
      _loading = false;
      _error = _lockMethod == AuthLockMethod.password
          ? 'Email/username or password is incorrect.'
          : 'Email/username or PIN is incorrect.';
    });
  }

  Future<void> _unlockWithBiometric() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final ok = await BiometricAuthService.instance.authenticate(
      reason: 'Unlock your household expense tracker',
      skipAvailabilityCheck: true,
    );

    if (!mounted) return;

    if (ok) {
      await AuthService.instance.unlockSession();
      if (!mounted) return;
      setState(() => _loading = false);
      widget.onSuccess();
      return;
    }

    setState(() => _loading = false);
  }

  Future<void> _openForgotCredentials() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ForgotCredentialsScreen(onSuccess: widget.onSuccess),
      ),
    );
  }

  Future<void> _tryCreateAccount() async {
    if (DevAuthConfig.canBypassRegistrationGuard) {
      await startTestRegistrationFlow(
        context,
        onCompleted: widget.onSuccess,
      );
      return;
    }

    final hasAccount = await AuthService.instance.hasAccount();
    if (!mounted) return;

    if (hasAccount) {
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
              child: const Text('OK'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                _openForgotCredentials();
              },
              child: const Text('Forgot PIN / password'),
            ),
          ],
        ),
      );
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => RegisterScreen(
          onCompleted: widget.onSuccess,
        ),
      ),
    );
  }

  String? _validateIdentifier(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter your email or username';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isPassword = _lockMethod == AuthLockMethod.password;

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
                    Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppColors.primary.withValues(alpha: 0.14),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        const AppLogo(size: 168)
                            .animate()
                            .fadeIn(duration: 500.ms, curve: Curves.easeOut)
                            .scale(
                              begin: const Offset(0.88, 0.88),
                              end: const Offset(1, 1),
                              duration: 550.ms,
                              curve: Curves.easeOutBack,
                            )
                            .shimmer(
                              delay: 600.ms,
                              duration: 1200.ms,
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Household Expense',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: AppColors.primaryDark,
                          ),
                    ).animate().fadeIn(delay: 120.ms, duration: 400.ms),
                    const SizedBox(height: 6),
                    Text(
                      'Track · Budget · Manage',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: AppColors.primary.withValues(alpha: 0.75),
                      ),
                    ).animate().fadeIn(delay: 180.ms, duration: 400.ms),
                    const SizedBox(height: 16),
                    Text(
                      'Sign in',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _profile != null
                          ? 'Welcome back, ${_profile!.firstName}. '
                              'Account: ${_profile!.email}'
                          : 'Enter your email/username and PIN to continue',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 28),
                    GlassSurface.card(
                      padding: const EdgeInsets.all(22),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _identifierController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autocorrect: false,
                              decoration: const InputDecoration(
                                labelText: 'Email or username',
                                prefixIcon: Icon(Icons.person_outline),
                                helperText:
                                    'Use the email or name from your account',
                              ),
                              validator: _validateIdentifier,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _secretController,
                              obscureText: _obscureSecret,
                              keyboardType: isPassword
                                  ? TextInputType.visiblePassword
                                  : TextInputType.number,
                              inputFormatters: isPassword
                                  ? null
                                  : [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(4),
                                    ],
                              decoration: InputDecoration(
                                labelText:
                                    isPassword ? 'Password' : '4-digit PIN',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureSecret
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscureSecret = !_obscureSecret,
                                  ),
                                ),
                              ),
                              validator: isPassword
                                  ? AuthValidators.password
                                  : AuthValidators.pin,
                              onFieldSubmitted: (_) => _submit(),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _error!,
                                style: const TextStyle(
                                  color: AppColors.expense,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            FilledButton(
                              onPressed: _loading ? null : _submit,
                              style: FilledButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Sign in'),
                            ),
                            if (_biometricEnabled && _biometricAvailable) ...[
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed:
                                    _loading ? null : _unlockWithBiometric,
                                icon: const Icon(Icons.fingerprint),
                                label: const Text('Use fingerprint / Face ID'),
                              ),
                            ],
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed:
                                  _loading ? null : _openForgotCredentials,
                              child: const Text('Forgot PIN or password?'),
                            ),
                            TextButton(
                              onPressed: _loading ? null : _tryCreateAccount,
                              child: Text(
                                DevAuthConfig.showTestRegistrationUi
                                    ? 'Test: register new user'
                                    : 'New user? Create account',
                              ),
                            ),
                            if (DevAuthConfig.showTestRegistrationUi) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Debug only — try India, US, UK, Europe regions',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  color:
                                      AppColors.warning.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ],
                        ),
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
