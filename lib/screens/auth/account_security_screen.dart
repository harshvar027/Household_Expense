import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/region_config.dart';
import '../../models/app_region.dart';
import '../../models/user_profile.dart';
import '../../services/app_locale_service.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_auth_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/auth_dialogs.dart';
import '../../utils/auth_validators.dart';
import '../../widgets/bank_dropdown_field.dart';
import '../../widgets/ui/app_scaffold.dart';
import '../../widgets/ui/glass_surface.dart';

class AccountSecurityScreen extends StatefulWidget {
  final UserProfile profile;
  final Future<void> Function()? onLogout;

  const AccountSecurityScreen({
    super.key,
    required this.profile,
    this.onLogout,
  });

  @override
  State<AccountSecurityScreen> createState() => _AccountSecurityScreenState();
}

class _AccountSecurityScreenState extends State<AccountSecurityScreen> {
  final _profileFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _householdController = TextEditingController();

  final _currentSecretController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  AppRegion _region = AppRegion.india;
  String _currency = 'INR';
  String? _primaryBankId;
  AuthLockMethod _lockMethod = AuthLockMethod.pin;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  bool _savingProfile = false;
  bool _savingSecurity = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.profile.name;
    _emailController.text = widget.profile.email;
    _phoneController.text = widget.profile.phone;
    _householdController.text = widget.profile.householdName;
    _region = AppRegion.fromStorage(widget.profile.region);
    _currency = widget.profile.currency;
    _primaryBankId = widget.profile.primaryBankId;
    AppLocaleService.instance.applyProfile(widget.profile);
    _loadSecurityState();
  }

  Future<void> _loadSecurityState() async {
    final method = await AuthService.instance.getAuthLockMethod();
    final bioEnabled = await AuthService.instance.isBiometricEnabled();
    final bioAvailable = await BiometricAuthService.instance.isAvailable();
    if (!mounted) return;
    setState(() {
      _lockMethod = method;
      _biometricEnabled = bioEnabled;
      _biometricAvailable = bioAvailable;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _householdController.dispose();
    _currentSecretController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;

    setState(() => _savingProfile = true);
    try {
      final updated = widget.profile.copyWith(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: AuthValidators.normalizePhone(
          _phoneController.text,
          region: _region,
        ),
        householdName: _householdController.text.trim(),
        region: _region.storageKey,
        currency: _currency,
        primaryBankId: _primaryBankId,
      );
      await AuthService.instance.updateProfile(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
      Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _savePin() async {
    if (_currentSecretController.text.trim().isEmpty) {
      _showError('Enter your current PIN or password');
      return;
    }
    final pinError = AuthValidators.pin(_newPinController.text);
    if (pinError != null) {
      _showError(pinError);
      return;
    }
    final confirmError = AuthValidators.confirmPin(
      _confirmPinController.text,
      _newPinController.text.trim(),
    );
    if (confirmError != null) {
      _showError(confirmError);
      return;
    }

    setState(() => _savingSecurity = true);
    try {
      await AuthService.instance.changePin(
        currentSecret: _currentSecretController.text.trim(),
        newPin: _newPinController.text.trim(),
      );
      _clearSecurityFields();
      await _loadSecurityState();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN updated — use PIN to unlock')),
      );
    } on AuthException catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _savingSecurity = false);
    }
  }

  Future<void> _savePassword() async {
    if (_currentSecretController.text.trim().isEmpty) {
      _showError('Enter your current PIN or password');
      return;
    }
    final passError = AuthValidators.password(_newPasswordController.text);
    if (passError != null) {
      _showError(passError);
      return;
    }
    final confirmError = AuthValidators.confirmPassword(
      _confirmPasswordController.text,
      _newPasswordController.text.trim(),
    );
    if (confirmError != null) {
      _showError(confirmError);
      return;
    }

    setState(() => _savingSecurity = true);
    try {
      await AuthService.instance.setPassword(
        currentSecret: _currentSecretController.text.trim(),
        newPassword: _newPasswordController.text.trim(),
      );
      _clearSecurityFields();
      await _loadSecurityState();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated — use password to unlock')),
      );
    } on AuthException catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _savingSecurity = false);
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      if (_currentSecretController.text.trim().isEmpty) {
        _showError('Enter your current PIN or password to enable biometrics');
        return;
      }
      final valid = await AuthService.instance.verifyCurrentSecret(
        _currentSecretController.text.trim(),
      );
      if (!valid) {
        _showError('Current PIN or password is incorrect');
        return;
      }
      final ok = await BiometricAuthService.instance.authenticate(
        reason: 'Confirm fingerprint or Face ID for unlock',
      );
      if (!ok) return;
    }

    await AuthService.instance.setBiometricEnabled(value);
    if (!mounted) return;
    setState(() => _biometricEnabled = value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? 'Biometric unlock enabled' : 'Biometric unlock disabled'),
      ),
    );
  }

  void _clearSecurityFields() {
    _currentSecretController.clear();
    _newPinController.clear();
    _confirmPinController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = RegionConfig.forRegion(_region);

    return AppScreenScaffold(
      title: 'Account & security',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader('Profile details'),
          const SizedBox(height: 8),
          GlassSurface.card(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _profileFormKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: AuthValidators.name,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email address',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: AuthValidators.email,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<AppRegion>(
                    value: _region,
                    decoration: const InputDecoration(
                      labelText: 'Region',
                      prefixIcon: Icon(Icons.public_outlined),
                    ),
                    items: AppRegion.values
                        .map(
                          (region) => DropdownMenuItem(
                            value: region,
                            child: Text(region.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _region = value;
                        final regional = RegionConfig.forRegion(value);
                        _currency = regional.currencyCode;
                        _primaryBankId = null;
                      });
                      AppLocaleService.instance.applyProfile(
                        widget.profile.copyWith(
                          region: value.storageKey,
                          currency: _currency,
                          primaryBankId: null,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  BankDropdownField(
                    value: _primaryBankId,
                    allowAutoDetect: false,
                    labelText: 'Primary bank',
                    onChanged: (value) => setState(() => _primaryBankId = value),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(config.phoneMaxDigits),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Mobile number',
                      prefixText: '${config.phoneDialCode} ',
                      prefixIcon: const Icon(Icons.phone_android_outlined),
                    ),
                    validator: (value) =>
                        AuthValidators.phone(value, region: _region),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _householdController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Household name',
                      prefixIcon: Icon(Icons.home_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _currency,
                    decoration: const InputDecoration(
                      labelText: 'Currency',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'INR', child: Text('INR')),
                      DropdownMenuItem(value: 'USD', child: Text('USD')),
                      DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                      DropdownMenuItem(value: 'GBP', child: Text('GBP')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _currency = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _savingProfile ? null : _saveProfile,
                    child: _savingProfile
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save profile'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _sectionHeader('Unlock method'),
          const SizedBox(height: 8),
          GlassSurface.card(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Current: ${_lockMethod == AuthLockMethod.password ? 'Password' : '4-digit PIN'}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _currentSecretController,
                  obscureText: _obscureCurrent,
                  decoration: InputDecoration(
                    labelText: 'Current PIN or password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureCurrent
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscureCurrent = !_obscureCurrent),
                    ),
                  ),
                ),
                if (_biometricAvailable) ...[
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Fingerprint / Face unlock'),
                    subtitle: const Text('Quick unlock when opening the app'),
                    value: _biometricEnabled,
                    onChanged: _savingSecurity ? null : _toggleBiometric,
                  ),
                ],
                const Divider(height: 28),
                const Text(
                  'Change to PIN',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _newPinController,
                  obscureText: _obscureNew,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'New 4-digit PIN',
                    prefixIcon: Icon(Icons.pin_outlined),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPinController,
                  obscureText: _obscureConfirm,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Confirm new PIN',
                    prefixIcon: Icon(Icons.pin_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _savingSecurity ? null : _savePin,
                  child: const Text('Update PIN'),
                ),
                const Divider(height: 28),
                const Text(
                  'Or use password instead',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscureNew,
                  decoration: const InputDecoration(
                    labelText: 'New password (min 6 characters)',
                    prefixIcon: Icon(Icons.password_outlined),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  decoration: const InputDecoration(
                    labelText: 'Confirm new password',
                    prefixIcon: Icon(Icons.password_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _savingSecurity ? null : _savePassword,
                  child: const Text('Switch to password'),
                ),
              ],
            ),
          ),
          if (widget.onLogout != null) ...[
            const SizedBox(height: 24),
            _sectionHeader('Session'),
            const SizedBox(height: 8),
            GlassSurface.card(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Sign out of this device. Your data stays on the phone — '
                    'use your PIN or password to unlock again.',
                    style: TextStyle(color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      if (!await confirmLogout(context)) return;
                      await widget.onLogout!();
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.expense,
                      side: const BorderSide(color: AppColors.expense),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 15,
        color: AppColors.textPrimary,
      ),
    );
  }
}
