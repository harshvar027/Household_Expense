import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/finnhub_config.dart';
import '../models/market_news.dart';

class FinnhubNewsException implements Exception {
  final String message;
  const FinnhubNewsException(this.message);

  @override
  String toString() => message;
}

class FinnhubNewsService {
  FinnhubNewsService({http.Client? client}) : _client = client ?? http.Client();

  static final FinnhubNewsService instance = FinnhubNewsService();

  final http.Client _client;
  MarketNewsBundle? _cache;
  DateTime? _cacheAt;

  Future<MarketNewsBundle> load({bool force = false}) async {
    final cached = _cache;
    final cachedAt = _cacheAt;
    if (!force &&
        cached != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < FinnhubConfig.cacheTtl) {
      return cached;
    }

    if (!FinnhubConfig.isConfigured) {
      throw const FinnhubNewsException(
        'Add your Finnhub API key to unlock the economic wire.',
      );
    }

    try {
      final results = await Future.wait([
        ...FinnhubConfig.newsCategories.map(_fetchNews),
        ...FinnhubConfig.pulseSymbols.map(
          (item) => _fetchQuote(item.symbol, item.label),
        ),
      ]);

      final articles = <MarketNewsArticle>[];
      final quotes = <MarketQuote>[];
      final seen = <String>{};

      for (final result in results) {
        if (result is List<MarketNewsArticle>) {
          for (final article in result) {
            final key = article.url.isNotEmpty
                ? article.url
                : '${article.id}-${article.headline}';
            if (!article.isUsable || !seen.add(key)) continue;
            articles.add(article);
          }
        } else if (result is MarketQuote && result.isValid) {
          quotes.add(result);
        }
      }

      articles.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
      final bundle = MarketNewsBundle(
        articles: articles.take(60).toList(),
        quotes: quotes,
        fetchedAt: DateTime.now(),
      );

      if (bundle.articles.isEmpty) {
        throw const FinnhubNewsException(
          'No market headlines right now. Pull to refresh in a moment.',
        );
      }

      _cache = bundle;
      _cacheAt = bundle.fetchedAt;
      return bundle;
    } on FinnhubNewsException {
      if (cached != null) return cached;
      rethrow;
    } catch (error, stack) {
      debugPrint('Finnhub news failed: $error\n$stack');
      if (cached != null) return cached;
      throw const FinnhubNewsException(
        'Could not reach market news. Check your connection and try again.',
      );
    }
  }

  Future<List<MarketNewsArticle>> _fetchNews(String category) async {
    final uri = Uri.parse('${FinnhubConfig.baseUrl}/news').replace(
      queryParameters: {
        'category': category,
        'token': FinnhubConfig.apiKey,
      },
    );
    final response = await _client.get(uri).timeout(FinnhubConfig.requestTimeout);
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const FinnhubNewsException(
        'Finnhub rejected the API key. Set FINNHUB_API_KEY and rebuild.',
      );
    }
    if (response.statusCode == 429) {
      throw const FinnhubNewsException(
        'Market news is briefly rate-limited. Try again in a minute.',
      );
    }
    if (response.statusCode != 200) {
      throw FinnhubNewsException(
        'Market news returned ${response.statusCode}.',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map && decoded['error'] != null) {
      throw FinnhubNewsException(
        'Finnhub rejected the API key. Set FINNHUB_API_KEY and rebuild.',
      );
    }
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((row) => MarketNewsArticle.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<MarketQuote?> _fetchQuote(String symbol, String label) async {
    try {
      final uri = Uri.parse('${FinnhubConfig.baseUrl}/quote').replace(
        queryParameters: {
          'symbol': symbol,
          'token': FinnhubConfig.apiKey,
        },
      );
      final response =
          await _client.get(uri).timeout(FinnhubConfig.requestTimeout);
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return null;
      return MarketQuote.fromJson(
        Map<String, dynamic>.from(decoded),
        symbol: symbol,
        label: label,
      );
    } catch (error) {
      debugPrint('Finnhub quote $symbol failed: $error');
      return null;
    }
  }
}
