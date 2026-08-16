import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/market_news.dart';
import '../../services/finnhub_news_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/neo_palette.dart';
import '../../utils/responsive_layout.dart';
import '../../widgets/ui/empty_state.dart';
import '../../widgets/ui/neo_glass.dart';
import '../../widgets/ui/pressable_scale.dart';
import '../../widgets/ui/stagger_animate.dart';

class NewsTab extends StatefulWidget {
  final double bottomScrollPadding;

  const NewsTab({super.key, this.bottomScrollPadding = 120});

  @override
  State<NewsTab> createState() => _NewsTabState();
}

class _NewsTabState extends State<NewsTab> {
  MarketNewsBundle? _bundle;
  Object? _error;
  bool _loading = true;
  NewsLens _lens = NewsLens.all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool force = false}) async {
    if (!force) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final bundle = await FinnhubNewsService.instance.load(force: force);
      if (!mounted) return;
      setState(() {
        _bundle = bundle;
        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _openArticle(MarketNewsArticle article) async {
    hapticTap();
    final uri = Uri.tryParse(article.url);
    if (uri == null) return;
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this story.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bundle = _bundle;
    final articles = bundle?.forLens(_lens) ?? const <MarketNewsArticle>[];
    final featured = articles.isNotEmpty ? articles.first : null;
    final rest = articles.length > 1 ? articles.sublist(1) : const <MarketNewsArticle>[];

    return RefreshIndicator(
      color: NeoPalette.cyberMint,
      backgroundColor: NeoPalette.slateCard,
      onRefresh: () => _load(force: true),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: ResponsiveLayout.screenPadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _NewsHeader(
                    fetchedAt: bundle?.fetchedAt,
                    live: bundle != null && _error == null,
                  ).staggerIn(index: 0, slideY: 0.08),
                  const SizedBox(height: 16),
                  if (bundle != null && bundle.quotes.isNotEmpty)
                    _QuoteStrip(quotes: bundle.quotes).staggerIn(index: 1, slideY: 0.06),
                  if (bundle != null && bundle.quotes.isNotEmpty)
                    const SizedBox(height: 16),
                  _LensChips(
                    selected: _lens,
                    onSelected: (lens) => setState(() => _lens = lens),
                  ).staggerIn(index: 2, slideY: 0.05),
                  const SizedBox(height: 18),
                  if (_loading && bundle == null)
                    const _NewsSkeleton()
                  else if (_error != null && bundle == null)
                    EmptyState(
                      icon: _error.toString().contains('API key')
                          ? Icons.key_rounded
                          : Icons.wifi_off_rounded,
                      title: _error.toString().contains('API key')
                          ? 'Connect Finnhub'
                          : 'News is offline',
                      subtitle: _error.toString(),
                      actionLabel: 'Try again',
                      onAction: () => _load(force: true),
                    )
                  else if (featured == null)
                    EmptyState(
                      icon: Icons.newspaper_outlined,
                      title: 'No stories in this lens',
                      subtitle: 'Try another filter or pull to refresh the wire.',
                      actionLabel: 'Show all',
                      onAction: () => setState(() => _lens = NewsLens.all),
                    )
                  else ...[
                    _FeaturedStory(
                      article: featured,
                      onOpen: () => _openArticle(featured),
                    ).staggerIn(index: 3, slideY: 0.08),
                    const SizedBox(height: 22),
                    NeoGlass.sectionHeader(
                      'Latest moves',
                      trailing: '${articles.length} stories',
                    ),
                    const SizedBox(height: 12),
                    for (var i = 0; i < rest.length; i++) ...[
                      _NewsRow(
                        article: rest[i],
                        onOpen: () => _openArticle(rest[i]),
                      ).staggerIn(index: 4 + i, baseDelayMs: 36, slideY: 0.05),
                      const SizedBox(height: 10),
                    ],
                  ],
                  SizedBox(height: widget.bottomScrollPadding),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewsHeader extends StatelessWidget {
  final DateTime? fetchedAt;
  final bool live;

  const _NewsHeader({required this.fetchedAt, required this.live});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _LiveDot(active: live),
            const SizedBox(width: 8),
            Text(
              'ECONOMIC WIRE',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
                color: NeoPalette.cyberMint,
              ),
            ),
            const Spacer(),
            if (fetchedAt != null)
              Text(
                'Updated ${formatRelativeTime(fetchedAt!)}',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.mutedOf(context),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Market news', style: AppTheme.displayOf(context, fontSize: 28)),
        const SizedBox(height: 6),
        Text(
          'Rates, inflation, oil, and the moves that change a household budget.',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            height: 1.4,
            color: AppTheme.mutedOf(context),
          ),
        ),
      ],
    );
  }
}

class _LiveDot extends StatelessWidget {
  final bool active;
  const _LiveDot({required this.active});

  @override
  Widget build(BuildContext context) {
    final color = active ? NeoPalette.cyberMint : AppColors.textMuted;
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: active
            ? [BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 8)]
            : null,
      ),
    )
        .animate(onPlay: (c) => active ? c.repeat(reverse: true) : null)
        .scale(
          begin: const Offset(0.82, 0.82),
          end: const Offset(1.15, 1.15),
          duration: 1200.ms,
          curve: Curves.easeInOut,
        );
  }
}

class _QuoteStrip extends StatelessWidget {
  final List<MarketQuote> quotes;
  const _QuoteStrip({required this.quotes});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: quotes.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final quote = quotes[index];
          final up = quote.isUp;
          final color = up ? AppColors.income : AppColors.expense;
          return NeoGlass.card(
            glowColor: color,
            glowIntensity: 0.12,
            borderRadius: 18,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: SizedBox(
              width: 118,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    quote.label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    quote.price.toStringAsFixed(2),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${up ? '+' : ''}${quote.changePercent.toStringAsFixed(2)}%',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LensChips extends StatelessWidget {
  final NewsLens selected;
  final ValueChanged<NewsLens> onSelected;

  const _LensChips({required this.selected, required this.onSelected});

  static const _items = [
    (NewsLens.all, 'All'),
    (NewsLens.economy, 'Economy'),
    (NewsLens.markets, 'Markets'),
    (NewsLens.forex, 'Forex'),
    (NewsLens.deals, 'Deals'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (final item in _items) ...[
            _LensChip(
              label: item.$2,
              selected: selected == item.$1,
              onTap: () => onSelected(item.$1),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _LensChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LensChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      scale: 0.97,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: selected
              ? LinearGradient(
                  colors: [
                    NeoPalette.cyberMint.withValues(alpha: 0.22),
                    NeoPalette.electricAmethyst.withValues(alpha: 0.14),
                  ],
                )
              : null,
          color: selected ? null : NeoPalette.slateCard.withValues(alpha: 0.7),
          border: Border.all(
            color: selected
                ? NeoPalette.cyberMint.withValues(alpha: 0.55)
                : NeoPalette.cyberMint.withValues(alpha: 0.14),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: NeoPalette.cyberMint.withValues(alpha: 0.18),
                    blurRadius: 14,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? NeoPalette.cyberMint : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _FeaturedStory extends StatelessWidget {
  final MarketNewsArticle article;
  final VoidCallback onOpen;

  const _FeaturedStory({required this.article, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onOpen,
      child: NeoGlass.card(
        glowColor: NeoPalette.electricAmethyst,
        padding: EdgeInsets.zero,
        borderRadius: 26,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _NewsImage(url: article.imageUrl, hero: true),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            NeoPalette.obsidian.withValues(alpha: 0.88),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 14,
                      child: Row(
                        children: [
                          _MetaChip(label: article.lensLabel),
                          if (article.touchesHousehold) ...[
                            const SizedBox(width: 8),
                            const _MetaChip(
                              label: 'Household',
                              accent: true,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.headline,
                    style: AppTheme.displayOf(context, fontSize: 22),
                  ),
                  if (article.summary.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      article.summary,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13.5,
                        height: 1.45,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${article.source}  ·  ${article.relativeTime}',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.north_east_rounded,
                        size: 16,
                        color: NeoPalette.cyberMint.withValues(alpha: 0.85),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewsRow extends StatelessWidget {
  final MarketNewsArticle article;
  final VoidCallback onOpen;

  const _NewsRow({required this.article, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onOpen,
      child: NeoGlass.card(
        glowColor: article.touchesHousehold
            ? NeoPalette.cyberMint
            : NeoPalette.electricAmethyst,
        glowIntensity: 0.1,
        borderRadius: 20,
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 84,
                height: 84,
                child: _NewsImage(url: article.imageUrl),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 84,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _TinyTag(label: article.lensLabel),
                        if (article.touchesHousehold) ...[
                          const SizedBox(width: 6),
                          const _TinyTag(label: 'Home', mint: true),
                        ],
                        const Spacer(),
                        Text(
                          article.relativeTime,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Text(
                        article.headline,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      article.source,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewsImage extends StatelessWidget {
  final String url;
  final bool hero;

  const _NewsImage({required this.url, this.hero = false});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty || !url.startsWith('http')) {
      return const _ImageFallback();
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          return child
              .animate()
              .fadeIn(duration: 420.ms, curve: Curves.easeOutCubic)
              .scale(
                begin: hero ? const Offset(1.04, 1.04) : const Offset(1.02, 1.02),
                end: const Offset(1, 1),
                duration: 700.ms,
                curve: Curves.easeOutCubic,
              );
        }
        return const _ImageFallback(shimmer: true);
      },
      errorBuilder: (_, _, _) => const _ImageFallback(),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  final bool shimmer;
  const _ImageFallback({this.shimmer = false});

  @override
  Widget build(BuildContext context) {
    final child = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            NeoPalette.slateElevated,
            NeoPalette.obsidianSlate,
            NeoPalette.electricAmethyst.withValues(alpha: 0.18),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.stacked_line_chart_rounded,
          color: NeoPalette.cyberMint.withValues(alpha: 0.55),
          size: 28,
        ),
      ),
    );
    if (!shimmer) return child;
    return child
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1400.ms, color: Colors.white.withValues(alpha: 0.08));
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final bool accent;
  const _MetaChip({required this.label, this.accent = false});

  @override
  Widget build(BuildContext context) {
    final color = accent ? NeoPalette.cyberMint : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.black.withValues(alpha: 0.42),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.spaceGrotesk(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: color,
        ),
      ),
    );
  }
}

class _TinyTag extends StatelessWidget {
  final String label;
  final bool mint;
  const _TinyTag({required this.label, this.mint = false});

  @override
  Widget build(BuildContext context) {
    final color = mint ? NeoPalette.cyberMint : NeoPalette.electricAmethyst;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _NewsSkeleton extends StatelessWidget {
  const _NewsSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget block({required double height, double radius = 22}) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          color: NeoPalette.slateCard.withValues(alpha: 0.7),
        ),
      )
          .animate(onPlay: (c) => c.repeat())
          .shimmer(
            duration: 1400.ms,
            color: Colors.white.withValues(alpha: 0.06),
          );
    }

    return Column(
      children: [
        block(height: 220, radius: 26),
        const SizedBox(height: 14),
        block(height: 108),
        const SizedBox(height: 10),
        block(height: 108),
        const SizedBox(height: 10),
        block(height: 108),
      ],
    );
  }
}
