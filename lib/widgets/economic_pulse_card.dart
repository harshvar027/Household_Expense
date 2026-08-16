import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/market_news.dart';
import '../services/finnhub_news_service.dart';
import '../theme/app_theme.dart';
import '../theme/neo_palette.dart';
import 'ui/neo_glass.dart';
import 'ui/pressable_scale.dart';

class EconomicPulseCard extends StatefulWidget {
  final VoidCallback onOpenNews;

  const EconomicPulseCard({super.key, required this.onOpenNews});

  @override
  State<EconomicPulseCard> createState() => _EconomicPulseCardState();
}

class _EconomicPulseCardState extends State<EconomicPulseCard> {
  List<MarketNewsArticle> _headlines = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final bundle = await FinnhubNewsService.instance.load();
      if (!mounted) return;
      final economy = bundle.forLens(NewsLens.economy);
      final pick = economy.isNotEmpty ? economy : bundle.articles;
      setState(() => _headlines = pick.take(3).toList());
    } catch (_) {
      if (!mounted) return;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_headlines.isEmpty) return const SizedBox.shrink();

    return PressableScale(
      onTap: widget.onOpenNews,
      child: NeoGlass.card(
        glowColor: NeoPalette.cyberMint,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: NeoPalette.cyberMint,
                    boxShadow: [
                      BoxShadow(
                        color: NeoPalette.cyberMint.withValues(alpha: 0.7),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(0.85, 0.85),
                      end: const Offset(1.18, 1.18),
                      duration: 1200.ms,
                    ),
                const SizedBox(width: 8),
                Text(
                  'ECONOMIC PULSE',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                    color: NeoPalette.cyberMint,
                  ),
                ),
                const Spacer(),
                Text(
                  'See all',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.accentOf(context),
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: AppTheme.accentOf(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < _headlines.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 16,
                  color: NeoPalette.cyberMint.withValues(alpha: 0.08),
                ),
              Text(
                _headlines[i].headline,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13.5,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${_headlines[i].source}  ·  ${_headlines[i].relativeTime}',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 520.ms).slideY(begin: 0.06, end: 0);
  }
}
