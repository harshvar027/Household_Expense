import 'package:flutter_test/flutter_test.dart';
import 'package:household_expense/models/market_news.dart';

void main() {
  MarketNewsArticle article({
    String headline = 'Markets hold steady',
    String summary = 'Equities were mixed.',
    String category = 'general',
    String url = 'https://example.com/story',
    int datetime = 1710000000,
  }) {
    return MarketNewsArticle.fromJson({
      'id': 12,
      'headline': headline,
      'summary': summary,
      'source': 'Reuters',
      'url': url,
      'image': 'https://example.com/img.jpg',
      'category': category,
      'datetime': datetime,
      'related': '',
    });
  }

  test('parses Finnhub news payload', () {
    final news = article(
      headline: 'Fed holds rates as inflation cools',
      summary: 'The central bank kept the policy rate unchanged.',
    );
    expect(news.isUsable, isTrue);
    expect(news.source, 'Reuters');
    expect(news.publishedAt.isUtc, isFalse);
  });

  test('classifies economy and household impact', () {
    final news = article(
      headline: 'RBI rate cut eases household EMIs',
      summary: 'Inflation cooled and fuel prices slipped.',
    );
    expect(news.isEconomic, isTrue);
    expect(news.touchesHousehold, isTrue);
    expect(news.lens, NewsLens.economy);
  });

  test('maps forex and merger categories', () {
    expect(article(category: 'forex').lens, NewsLens.forex);
    expect(article(category: 'merger').lens, NewsLens.deals);
  });

  test('rejects empty or non-http stories', () {
    expect(article(headline: '  ', url: 'https://x.com').isUsable, isFalse);
    expect(article(url: 'ftp://x.com').isUsable, isFalse);
  });

  test('filters a bundle by lens', () {
    final bundle = MarketNewsBundle(
      articles: [
        article(headline: 'CPI inflation cools in July'),
        article(headline: 'Chipmaker shares jump', summary: 'Tech rally'),
        article(headline: 'Dollar slips vs rupee', category: 'forex'),
      ],
      quotes: const [],
      fetchedAt: DateTime.now(),
    );
    expect(bundle.forLens(NewsLens.all), hasLength(3));
    expect(bundle.forLens(NewsLens.economy), hasLength(1));
    expect(bundle.forLens(NewsLens.forex), hasLength(1));
  });

  test('formats relative time', () {
    expect(formatRelativeTime(DateTime.now()), 'Just now');
    expect(
      formatRelativeTime(DateTime.now().subtract(const Duration(minutes: 12))),
      '12m ago',
    );
  });

  test('parses quote payload', () {
    final quote = MarketQuote.fromJson(
      {'c': 512.4, 'd': -1.2, 'dp': -0.23},
      symbol: 'SPY',
      label: 'S&P 500',
    );
    expect(quote.isValid, isTrue);
    expect(quote.isUp, isFalse);
    expect(quote.changePercent, closeTo(-0.23, 0.0001));
  });
}
