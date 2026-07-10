import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/region_config.dart';
import '../../config/dev_auth_config.dart';
import '../../models/app_region.dart';
import '../../models/user_profile.dart';
import '../../services/app_locale_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/auth_validators.dart';
import '../../widgets/ui/finance_illustration.dart';
import '../../widgets/ui/glass_surface.dart';
import '../../widgets/ui/mesh_background.dart';
import '../../widgets/bank_dropdown_field.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onCompleted;

  const RegisterScreen({super.key, required this.onCompleted});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _householdController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  AppRegion _region = AppRegion.india;
  String _currency = 'INR';
  String? _primaryBankId;
  bool _obscurePin = true;
  bool _obscureConfirmPin = true;
  bool _loading = false;
  bool _acceptedTerms = false;
  bool _deviceBlocked = false;
  String? _blockMessage;

  RegionConfig get _regionConfig => RegionConfig.forRegion(_region);

  @override
  void initState() {
    super.initState();
    _applyRegionPreview();
    _checkDeviceRegistration();
  }

  Future<void> _checkDeviceRegistration() async {
    final check = await AuthService.instance.checkRegistrationAllowed();
    if (!mounted) return;
    if (!check.allowed) {
      setState(() {
        _deviceBlocked = true;
        _blockMessage = check.message;
      });
    }
  }

  void _applyRegionPreview() {
    AppLocaleService.instance.applyProfile(
      UserProfile(
        name: '',
        email: '',
        phone: '',
        region: _region.storageKey,
        currency: _currency,
      ),
    );
  }

  void _onRegionChanged(AppRegion? region) {
    if (region == null) return;
    setState(() {
      _region = region;
      _currency = RegionConfig.forRegion(region).currencyCode;
      _primaryBankId = null;
    });
    _applyRegionPreview();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _householdController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the terms to continue')),
      );
      return;
    }
    if (_primaryBankId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your primary bank')),
      );
      return;
    }

    setState(() => _loading = true);

    final profile = UserProfile(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: AuthValidators.normalizePhone(_phoneController.text, region: _region),
      householdName: _householdController.text.trim(),
      region: _region.storageKey,
      currency: _currency,
      primaryBankId: _primaryBankId,
    );

    try {
      final check = await AuthService.instance.checkRegistrationAllowed(
        email: profile.email,
        phone: profile.phone,
        region: _region,
      );
      if (!check.allowed) {
        if (!mounted) return;
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(check.message)),
        );
        return;
      }

      await AuthService.instance.register(
        profile: profile,
        pin: _pinController.text.trim(),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
      return;
    }

    if (!mounted) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    if (_deviceBlocked) {
      return Scaffold(
        body: MeshBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.block, size: 56, color: AppColors.expense),
                  const SizedBox(height: 16),
                  const Text(
                    'Cannot create another account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _blockMessage ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go back to sign in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final config = _regionConfig;
    final smsHelper = config.supportsSmsQuickEntry
        ? 'Used for SMS transaction alerts'
        : 'Optional — for account recovery';

    return Scaffold(
      body: MeshBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  children: [
                    const FinanceIllustration(
                      type: FinanceIllustrationType.chart,
                      size: 76,
                    ).animate().fadeIn().scale(duration: 450.ms),
                    const SizedBox(height: 18),
                    Text(
                      'Set up your account',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Choose your region so dates, currency, and banks match your statements. '
                      'Statement import uses universal Debit/Credit columns.',
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
                            _sectionTitle('Region & household'),
                            if (DevAuthConfig.showTestRegistrationUi) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.warning.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: const Text(
                                  'Test mode: you can register again and pick any region '
                                  '(India, US, UK, Europe, International).',
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.35,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            DropdownButtonFormField<AppRegion>(
                              initialValue: _region,
                              decoration: const InputDecoration(
                                labelText: 'Region',
                                prefixIcon: Icon(Icons.public_outlined),
                                helperText:
                                    'Sets currency, date format, and bank list for imports.',
                              ),
                              items: AppRegion.values
                                  .map(
                                    (region) => DropdownMenuItem(
                                      value: region,
                                      child: Text(region.label),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _onRegionChanged,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _householdController,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'Household name (optional)',
                                prefixIcon: Icon(Icons.home_outlined),
                                hintText: 'e.g. Sharma Family',
                              ),
                            ),
                            const SizedBox(height: 12),
                            BankDropdownField(
                              value: _primaryBankId,
                              allowAutoDetect: false,
                              labelText: 'Primary bank',
                              helperText:
                                  'Used for statement imports — each account can have its own bank later.',
                              onChanged: (value) =>
                                  setState(() => _primaryBankId = value),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _currency,
                              decoration: InputDecoration(
                                labelText: 'Currency',
                                prefixIcon: const Icon(Icons.payments_outlined),
                                helperText:
                                    'Default: ${config.currencyCode} (${config.currencySymbol})',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'INR',
                                  child: Text('INR — Indian Rupee'),
                                ),
                                DropdownMenuItem(
                                  value: 'USD',
                                  child: Text('USD — US Dollar'),
                                ),
                                DropdownMenuItem(
                                  value: 'EUR',
                                  child: Text('EUR — Euro'),
                                ),
                                DropdownMenuItem(
                                  value: 'GBP',
                                  child: Text('GBP — British Pound'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _currency = value);
                                  _applyRegionPreview();
                                }
                              },
                            ),
                            const SizedBox(height: 20),
                            _sectionTitle('Personal details'),
                            const SizedBox(height: 12),
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
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(
                                  config.phoneMaxDigits,
                                ),
                              ],
                              decoration: InputDecoration(
                                labelText: 'Mobile number',
                                prefixText: '${config.phoneDialCode} ',
                                prefixIcon: const Icon(Icons.phone_android_outlined),
                                helperText: smsHelper,
                              ),
                              validator: (value) =>
                                  AuthValidators.phone(value, region: _region),
                            ),
                            const SizedBox(height: 20),
                            _sectionTitle('Security'),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _pinController,
                              obscureText: _obscurePin,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                              ],
                              decoration: InputDecoration(
                                labelText: 'Create 4-digit PIN',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePin
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscurePin = !_obscurePin),
                                ),
                                helperText: 'You will use this PIN to sign in',
                              ),
                              validator: AuthValidators.pin,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _confirmPinController,
                              obscureText: _obscureConfirmPin,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                              ],
                              decoration: InputDecoration(
                                labelText: 'Confirm PIN',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPin
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscureConfirmPin = !_obscureConfirmPin,
                                  ),
                                ),
                              ),
                              validator: (value) => AuthValidators.confirmPin(
                                value,
                                _pinController.text.trim(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            CheckboxListTile(
                              value: _acceptedTerms,
                              onChanged: (value) =>
                                  setState(() => _acceptedTerms = value ?? false),
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              title: const Text(
                                'I agree to store my profile locally on this device for expense tracking.',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                            const SizedBox(height: 8),
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
                                  : const Text('Create account & continue'),
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

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}
