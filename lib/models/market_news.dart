enum NewsLens { all, economy, markets, forex, deals }

class MarketQuote {
  final String symbol;
  final String label;
  final double price;
  final double change;
  final double changePercent;

  const MarketQuote({
    required this.symbol,
    required this.label,
    required this.price,
    required this.change,
    required this.changePercent,
  });

  bool get isUp => change >= 0;

  factory MarketQuote.fromJson(
    Map<String, dynamic> json, {
    required String symbol,
    required String label,
  }) {
    return MarketQuote(
      symbol: symbol,
      label: label,
      price: _asDouble(json['c']),
      change: _asDouble(json['d']),
      changePercent: _asDouble(json['dp']),
    );
  }

  bool get isValid => price > 0;
}

class MarketNewsArticle {
  final int id;
  final String headline;
  final String summary;
  final String source;
  final String url;
  final String imageUrl;
  final String category;
  final DateTime publishedAt;
  final String related;

  const MarketNewsArticle({
    required this.id,
    required this.headline,
    required this.summary,
    required this.source,
    required this.url,
    required this.imageUrl,
    required this.category,
    required this.publishedAt,
    required this.related,
  });

  factory MarketNewsArticle.fromJson(Map<String, dynamic> json) {
    final rawTime = json['datetime'];
    final seconds = rawTime is int
        ? rawTime
        : rawTime is num
            ? rawTime.toInt()
            : int.tryParse('$rawTime') ?? 0;

    return MarketNewsArticle(
      id: json['id'] is int ? json['id'] as int : (json['id'] as num?)?.toInt() ?? 0,
      headline: (json['headline'] ?? '').toString().trim(),
      summary: (json['summary'] ?? '').toString().trim(),
      source: (json['source'] ?? 'Market wire').toString().trim(),
      url: (json['url'] ?? '').toString().trim(),
      imageUrl: (json['image'] ?? '').toString().trim(),
      category: (json['category'] ?? 'general').toString().trim().toLowerCase(),
      publishedAt: DateTime.fromMillisecondsSinceEpoch(
        seconds * 1000,
        isUtc: true,
      ).toLocal(),
      related: (json['related'] ?? '').toString().trim(),
    );
  }

  bool get isUsable => headline.isNotEmpty && url.startsWith('http');

  bool get touchesHousehold =>
      _matchesAny(householdImpactKeywords, '$headline $summary');

  bool get isEconomic =>
      _matchesAny(economyKeywords, '$headline $summary $related');

  NewsLens get lens {
    if (category == 'forex') return NewsLens.forex;
    if (category == 'merger') return NewsLens.deals;
    if (isEconomic) return NewsLens.economy;
    return NewsLens.markets;
  }

  String get lensLabel => switch (lens) {
        NewsLens.economy => 'Economy',
        NewsLens.forex => 'Forex',
        NewsLens.deals => 'Deals',
        NewsLens.markets => 'Markets',
        NewsLens.all => 'Markets',
      };

  String get relativeTime => formatRelativeTime(publishedAt);

  static const economyKeywords = [
    'inflation',
    'cpi',
    'gdp',
    'fed',
    'fomc',
    'interest rate',
    'rate cut',
    'rate hike',
    'rbi',
    'rupee',
    'oil',
    'crude',
    'unemployment',
    'treasury',
    'yield',
    'recession',
    'stimulus',
    'tariff',
    'trade war',
    'housing',
    'wage',
    'payroll',
    'ecb',
    'imf',
    'commodity',
    'gold',
    'energy',
    'cost of living',
    'bond',
    'deficit',
    'fiscal',
    'monetary',
    'consumer price',
    'producer price',
    'jobs report',
    'central bank',
  ];

  static const householdImpactKeywords = [
    'inflation',
    'cpi',
    'oil',
    'crude',
    'gold',
    'rbi',
    'rupee',
    'interest rate',
    'rate cut',
    'rate hike',
    'energy',
    'housing',
    'wage',
    'cost of living',
    'grocery',
    'fuel',
    'petrol',
    'diesel',
    'electricity',
    'food price',
  ];
}

class MarketNewsBundle {
  final List<MarketNewsArticle> articles;
  final List<MarketQuote> quotes;
  final DateTime fetchedAt;

  const MarketNewsBundle({
    required this.articles,
    required this.quotes,
    required this.fetchedAt,
  });

  List<MarketNewsArticle> forLens(NewsLens lens) {
    if (lens == NewsLens.all) return articles;
    return articles.where((a) => a.lens == lens).toList();
  }
}

String formatRelativeTime(DateTime time) {
  final delta = DateTime.now().difference(time);
  if (delta.isNegative || delta.inSeconds < 45) return 'Just now';
  if (delta.inMinutes < 60) return '${delta.inMinutes}m ago';
  if (delta.inHours < 24) return '${delta.inHours}h ago';
  if (delta.inDays < 7) return '${delta.inDays}d ago';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${time.day} ${months[time.month - 1]}';
}

bool _matchesAny(List<String> needles, String haystack) {
  final text = haystack.toLowerCase();
  return needles.any(text.contains);
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}
