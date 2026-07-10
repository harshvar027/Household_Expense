import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../services/auth_service.dart';
import '../../services/entitlement_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui/app_logo.dart';
import '../../widgets/ui/mesh_background.dart';
import 'login_screen.dart';
import 'welcome_auth_screen.dart';

class AuthGate extends StatefulWidget {
  final WidgetBuilder authenticatedBuilder;

  const AuthGate({super.key, required this.authenticatedBuilder});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  bool _loading = true;
  bool _hasAccount = false;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isBackgroundLifecycleState(state) &&
        _isLoggedIn &&
        !AuthService.instance.isBackgroundLockSuppressed) {
      AuthService.instance.endSession();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        setState(() => _isLoggedIn = false);
      }
    }
  }

  bool _isBackgroundLifecycleState(AppLifecycleState state) {
    return state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden;
  }

  Future<void> _refresh({bool lockSession = true}) async {
    setState(() => _loading = true);
    if (lockSession) {
      await AuthService.instance.prepareForLaunch();
    }
    await EntitlementService.instance.migrateDeviceEnrollmentIfNeeded();
    // Open DB and migrate legacy prefs → app_user before routing.
    final hasAccount = await AuthService.instance.hasAccount();
    final loggedIn = await AuthService.instance.isLoggedIn();
    if (!mounted) return;
    setState(() {
      _hasAccount = hasAccount;
      _isLoggedIn = loggedIn;
      _loading = false;
    });
  }

  Future<void> _onUnlocked() async {
    if (!mounted) return;
    final hasAccount = await AuthService.instance.hasAccount();
    final loggedIn = await AuthService.instance.isLoggedIn();
    if (!mounted) return;
    setState(() {
      _hasAccount = hasAccount;
      _isLoggedIn = loggedIn;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const _AuthSplash();
    }

    if (_isLoggedIn && _hasAccount) {
      return widget.authenticatedBuilder(context);
    }

    // Database already has this household account → sign in with email + PIN.
    if (_hasAccount) {
      return LoginScreen(onSuccess: _onUnlocked);
    }

    // No account in the database → welcome / create account.
    return WelcomeAuthScreen(
      onRegistered: () => _refresh(lockSession: false),
      onSignedIn: _onUnlocked,
    );
  }
}

class _AuthSplash extends StatelessWidget {
  const _AuthSplash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MeshBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLogo(size: 112)
                  .animate()
                  .scale(duration: 500.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 24),
              Text(
                'Household Expense',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 16),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
