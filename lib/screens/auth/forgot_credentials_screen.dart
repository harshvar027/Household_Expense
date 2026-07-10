import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/region_config.dart';
import '../../models/app_region.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/auth_validators.dart';
import '../../widgets/ui/app_logo.dart';
import '../../widgets/ui/glass_surface.dart';
import '../../widgets/ui/mesh_background.dart';

/// Local identity recovery — verifies email + phone on device (no SMS/email cost).
class ForgotCredentialsScreen extends StatefulWidget {
  final VoidCallback onSuccess;

  const ForgotCredentialsScreen({super.key, required this.onSuccess});

  @override
  State<ForgotCredentialsScreen> createState() => _ForgotCredentialsScreenState();
}

class _ForgotCredentialsScreenState extends State<ForgotCredentialsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _secretController = TextEditingController();
  final _confirmController = TextEditingController();

  UserProfile? _profile;
  bool _usePassword = false;
  bool _obscureSecret = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _error;

  RegionConfig get _config {
    final region = _profile == null
        ? AppRegion.india
        : AppRegion.fromStorage(_profile!.region);
    return RegionConfig.forRegion(region);
  }

  Future<void> _loadProfile() async {
    final profile = await AuthService.instance.getProfile();
    final method = await AuthService.instance.getAuthLockMethod();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _usePassword = method == AuthLockMethod.password;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _secretController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await AuthService.instance.resetLockAfterIdentityCheck(
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        newSecret: _secretController.text.trim(),
        method: _usePassword ? AuthLockMethod.password : AuthLockMethod.pin,
      );
      if (!mounted) return;

      // Notify AuthGate first, then close this route so the main app is visible.
      widget.onSuccess();
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not reset. Check your details and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final region = _profile == null
        ? AppRegion.india
        : AppRegion.fromStorage(_profile!.region);
    final config = _config;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot PIN / password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: MeshBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  children: [
                    const AppLogo(size: 96)
                        .animate()
                        .scale(duration: 450.ms, curve: Curves.easeOutBack),
                    const SizedBox(height: 16),
                    Text(
                      'Verify your identity',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter the email and mobile number from registration. '
                      'Verification is done on this device only — no SMS or email is sent.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    GlassSurface.card(
                      padding: const EdgeInsets.all(22),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Registered email',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              validator: AuthValidators.email,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(
                                  config.phoneMaxDigits + 3,
                                ),
                              ],
                              decoration: InputDecoration(
                                labelText: 'Registered mobile',
                                prefixText: '${config.phoneDialCode} ',
                                prefixIcon: const Icon(Icons.phone_android_outlined),
                              ),
                              validator: (v) =>
                                  AuthValidators.phone(v, region: region),
                            ),
                            const SizedBox(height: 16),
                            SegmentedButton<bool>(
                              segments: const [
                                ButtonSegment(
                                  value: false,
                                  label: Text('New PIN'),
                                  icon: Icon(Icons.pin_outlined, size: 18),
                                ),
                                ButtonSegment(
                                  value: true,
                                  label: Text('New password'),
                                  icon: Icon(Icons.password_outlined, size: 18),
                                ),
                              ],
                              selected: {_usePassword},
                              onSelectionChanged: (s) {
                                if (s.isEmpty) return;
                                setState(() => _usePassword = s.first);
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _secretController,
                              obscureText: _obscureSecret,
                              keyboardType: _usePassword
                                  ? TextInputType.visiblePassword
                                  : TextInputType.number,
                              inputFormatters: _usePassword
                                  ? null
                                  : [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(4),
                                    ],
                              decoration: InputDecoration(
                                labelText:
                                    _usePassword ? 'New password' : 'New 4-digit PIN',
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
                              validator: _usePassword
                                  ? AuthValidators.password
                                  : AuthValidators.pin,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _confirmController,
                              obscureText: _obscureConfirm,
                              keyboardType: _usePassword
                                  ? TextInputType.visiblePassword
                                  : TextInputType.number,
                              inputFormatters: _usePassword
                                  ? null
                                  : [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(4),
                                    ],
                              decoration: InputDecoration(
                                labelText: 'Confirm',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirm
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm,
                                  ),
                                ),
                              ),
                              validator: (value) => _usePassword
                                  ? AuthValidators.confirmPassword(
                                      value,
                                      _secretController.text.trim(),
                                    )
                                  : AuthValidators.confirmPin(
                                      value,
                                      _secretController.text.trim(),
                                    ),
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
                                padding: const EdgeInsets.symmetric(vertical: 16),
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
                                  : const Text('Reset & unlock'),
                            ),
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
