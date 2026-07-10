import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/feedback_config.dart';
import '../../services/admin_auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui/app_scaffold.dart';
import '../../widgets/ui/mesh_background.dart';
import 'admin_feedback_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _setupCodeController = TextEditingController();

  bool _loading = true;
  bool _submitting = false;
  bool _setupMode = false;
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final configured = await AdminAuthService.instance.isAdminConfigured();
    final username = await AdminAuthService.instance.getAdminUsername();
    if (mounted) {
      setState(() {
        _setupMode = !configured;
        _loading = false;
        _usernameController.text = username;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _setupCodeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    final auth = AdminAuthService.instance;
    final ok = _setupMode
        ? await auth.setupAdmin(
            setupCode: _setupCodeController.text.trim(),
            username: _usernameController.text.trim(),
            password: _passwordController.text,
          )
        : await auth.login(
            username: _usernameController.text.trim(),
            password: _passwordController.text,
          );

    if (!mounted) return;

    if (!ok) {
      setState(() {
        _submitting = false;
        _error = _setupMode
            ? 'Invalid setup code or password too short (min 6 chars).'
            : 'Invalid admin username or password.';
      });
      return;
    }

    if (_setupMode) {
      await auth.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AdminFeedbackScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(_setupMode ? 'Admin setup' : 'Admin login'),
      ),
      body: MeshBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.admin_panel_settings_rounded,
                          size: 56,
                          color: AppColors.primary.withValues(alpha: 0.85),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _setupMode
                              ? 'Create your developer admin account'
                              : 'Developer feedback dashboard',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _setupMode
                              ? 'Use the setup code from your project config to continue.'
                              : 'View user feedback, bugs, and feature requests.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 28),
                        if (_setupMode) ...[
                          TextFormField(
                            controller: _setupCodeController,
                            decoration: const InputDecoration(
                              labelText: 'Setup code',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Setup code required'
                                : null,
                          ),
                          const SizedBox(height: 14),
                        ],
                        TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Admin username',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: _setupMode ? 'New password' : 'Password',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) => v == null || v.length < 6
                              ? 'Minimum 6 characters'
                              : null,
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            style: const TextStyle(color: AppColors.expense),
                          ),
                        ],
                        const SizedBox(height: 24),
                        PrimaryActionButton(
                          onPressed: _submitting ? null : _submit,
                          icon: _setupMode
                              ? Icons.verified_user_rounded
                              : Icons.login_rounded,
                          label: _setupMode ? 'Create admin account' : 'Sign in',
                          loading: _submitting,
                        ),
                        if (_setupMode) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Setup code is in lib/config/feedback_config.dart',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
