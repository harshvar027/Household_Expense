/// Finnhub market-news configuration.
///
/// Pass a personal key at build time:
/// `flutter run --dart-define=FINNHUB_API_KEY=your_key`
///
/// The website proxy reads `FINNHUB_API_KEY` from the environment.
class FinnhubConfig {
  FinnhubConfig._();

  static const apiKey = String.fromEnvironment('FINNHUB_API_KEY');

  static bool get isConfigured =>
      apiKey.isNotEmpty && apiKey.toLowerCase() != 'demo';

  static const baseUrl = 'https://finnhub.io/api/v1';

  static const cacheTtl = Duration(minutes: 8);

  static const requestTimeout = Duration(seconds: 12);

  static const newsCategories = ['general', 'forex', 'merger'];

  static const pulseSymbols = <({String symbol, String label})>[
    (symbol: 'SPY', label: 'S&P 500'),
    (symbol: 'QQQ', label: 'Nasdaq'),
    (symbol: 'GLD', label: 'Gold'),
    (symbol: 'USO', label: 'Oil'),
  ];
}
