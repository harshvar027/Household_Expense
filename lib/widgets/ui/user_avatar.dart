import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

class UserAvatar extends StatelessWidget {
  final String? name;
  final double radius;

  const UserAvatar({
    super.key,
    this.name,
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    final trimmed = (name ?? '').trim();
    final initial = trimmed.isEmpty ? 'H' : trimmed.characters.first.toUpperCase();
    final accent = AppTheme.accentOf(context);

    return CircleAvatar(
      radius: radius,
      backgroundColor: accent.withValues(alpha: 0.22),
      child: Text(
        initial,
        style: GoogleFonts.spaceGrotesk(
          fontSize: radius * 0.85,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
