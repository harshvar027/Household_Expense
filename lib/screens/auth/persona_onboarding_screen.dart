import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../database/database_helper.dart';
import '../../services/persona_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/persona_palette.dart';
import '../../utils/money_format.dart';
import '../../widgets/ui/app_logo.dart';
import '../../widgets/ui/mesh_background.dart';
import '../../widgets/ui/neo_glass.dart';

/// Local onboarding: life stage + monthly income seed (no cloud).
class PersonaOnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const PersonaOnboardingScreen({super.key, required this.onComplete});

  @override
  State<PersonaOnboardingScreen> createState() => _PersonaOnboardingScreenState();
}

class _PersonaOnboardingScreenState extends State<PersonaOnboardingScreen> {
  late final TextEditingController _income;
  String _persona = 'family';
  bool _busy = false;
  String? _error;

  static const _personas = [
    ('family', 'Family', 'Shared household spending', Icons.groups_rounded),
    ('professional', 'Professional', 'Salary, SIPs & growth', Icons.work_outline_rounded),
    ('student', 'Student', 'Campus life & allowance', Icons.school_rounded),
    ('senior', 'Senior', 'Essentials & peace of mind', Icons.favorite_border_rounded),
  ];

  @override
  void initState() {
    super.initState();
    final seed = PersonaService.instance.monthlyIncomeSeed;
    _income = TextEditingController(
      text: seed > 0 ? seed.toStringAsFixed(0) : '50000',
    );
    _persona = PersonaService.instance.persona;
  }

  @override
  void dispose() {
    _income.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final income = parseMoney(_income.text);
    if (income == null || income < 0) {
      setState(() => _error = 'Enter a valid monthly income.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final now = DateTime.now();
      final month =
          '${now.year}-${now.month.toString().padLeft(2, '0')}';
      if (income > 0) {
        await DatabaseHelper.instance.insertManualIncome(
          month: month,
          amount: income,
          description: 'Starting monthly income',
        );
      }
      await PersonaService.instance.completeOnboarding(
        persona: _persona,
        monthlyIncome: income,
      );
      if (!mounted) return;
      widget.onComplete();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MeshBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: NeoGlass.card(
                  borderRadius: 28,
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AppLogo(size: 64, showShadow: false),
                      const SizedBox(height: 16),
                      Text(
                        'Personalize your home',
                        style: AppTheme.displayOf(context, fontSize: 24),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Pick a life stage so accents and tips match how you spend. Everything stays on this device.',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13.5,
                          height: 1.45,
                          color: AppTheme.mutedOf(context),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Life stage',
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (final p in _personas) ...[
                        _PersonaTile(
                          selected: _persona == p.$1,
                          title: p.$2,
                          subtitle: p.$3,
                          icon: p.$4,
                          accent: PersonaPalette.of(p.$1).accent,
                          onTap: () => setState(() => _persona = p.$1),
                        ),
                        const SizedBox(height: 8),
                      ],
                      const SizedBox(height: 8),
                      TextField(
                        controller: _income,
                        keyboardType: kMoneyKeyboard,
                        inputFormatters: kMoneyInputFormatters,
                        decoration: const InputDecoration(
                          labelText: 'Typical monthly income',
                          prefixText: '₹ ',
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _error!,
                          style: const TextStyle(color: AppColors.expense, fontSize: 13),
                        ),
                      ],
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: _busy ? null : _submit,
                        child: _busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Continue'),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.04, end: 0),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PersonaTile extends StatelessWidget {
  final bool selected;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const _PersonaTile({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? accent.withValues(alpha: 0.14) : AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? accent : accent.withValues(alpha: 0.12),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        color: AppTheme.mutedOf(context),
                      ),
                    ),
                  ],
                ),
              ),
              if (selected) Icon(Icons.check_circle_rounded, color: accent, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
