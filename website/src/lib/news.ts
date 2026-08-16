export type NewsLens = 'all' | 'economy' | 'markets' | 'forex' | 'deals';

export type MarketQuote = {
  symbol: string;
  label: string;
  price: number;
  change: number;
  changePercent: number;
};

export type MarketArticle = {
  id: number;
  headline: string;
  summary: string;
  source: string;
  url: string;
  image: string;
  category: string;
  datetime: number;
  related: string;
};

export type MarketBundle = {
  articles: MarketArticle[];
  quotes: MarketQuote[];
  fetchedAt: number;
};

const ECONOMY = [
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

const HOUSEHOLD = [
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

function matches(needles: string[], haystack: string) {
  const text = haystack.toLowerCase();
  return needles.some((needle) => text.includes(needle));
}

export function articleLens(article: MarketArticle): Exclude<NewsLens, 'all'> {
  if (article.category === 'forex') return 'forex';
  if (article.category === 'merger') return 'deals';
  if (matches(ECONOMY, `${article.headline} ${article.summary} ${article.related}`)) {
    return 'economy';
  }
  return 'markets';
}

export function lensLabel(lens: Exclude<NewsLens, 'all'>) {
  return { economy: 'Economy', markets: 'Markets', forex: 'Forex', deals: 'Deals' }[lens];
}

export function touchesHousehold(article: MarketArticle) {
  return matches(HOUSEHOLD, `${article.headline} ${article.summary}`);
}

export function filterArticles(articles: MarketArticle[], lens: NewsLens) {
  if (lens === 'all') return articles;
  return articles.filter((article) => articleLens(article) === lens);
}

export function relativeTime(unixSeconds: number, now = Date.now()) {
  const published = unixSeconds * 1000;
  const delta = now - published;
  if (delta < 45_000) return 'Just now';
  if (delta < 3_600_000) return `${Math.floor(delta / 60_000)}m ago`;
  if (delta < 86_400_000) return `${Math.floor(delta / 3_600_000)}h ago`;
  if (delta < 604_800_000) return `${Math.floor(delta / 86_400_000)}d ago`;
  return new Date(published).toLocaleDateString('en-IN', {
    day: 'numeric',
    month: 'short',
  });
}

export async function fetchMarketBundle(): Promise<MarketBundle> {
  const response = await fetch('/api/market-news');
  if (!response.ok) {
    throw new Error('Market news is unavailable right now.');
  }
  return response.json();
}
