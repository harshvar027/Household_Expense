const BASE = 'https://finnhub.io/api/v1';
const NEWS_CATEGORIES = ['general', 'forex', 'merger'];
const PULSE = [
  { symbol: 'SPY', label: 'S&P 500' },
  { symbol: 'QQQ', label: 'Nasdaq' },
  { symbol: 'GLD', label: 'Gold' },
  { symbol: 'USO', label: 'Oil' },
];

function token() {
  return (process.env.FINNHUB_API_KEY || '').trim();
}

function assertToken() {
  const value = token();
  if (!value || value.toLowerCase() === 'demo') {
    const error = new Error('Missing FINNHUB_API_KEY');
    error.status = 401;
    throw error;
  }
  return value;
}

async function fetchJson(url) {
  const response = await fetch(url, { headers: { Accept: 'application/json' } });
  const data = await response.json().catch(() => null);
  if (!response.ok || data?.error) {
    const error = new Error(data?.error || `Finnhub ${response.status}`);
    error.status = response.status || 502;
    throw error;
  }
  return data;
}

async function fetchNews(category) {
  const url = `${BASE}/news?category=${encodeURIComponent(category)}&token=${encodeURIComponent(assertToken())}`;
  const data = await fetchJson(url);
  return Array.isArray(data) ? data : [];
}

async function fetchQuote(symbol, label) {
  try {
    const url = `${BASE}/quote?symbol=${encodeURIComponent(symbol)}&token=${encodeURIComponent(assertToken())}`;
    const data = await fetchJson(url);
    const price = Number(data?.c ?? 0);
    if (!price) return null;
    return {
      symbol,
      label,
      price,
      change: Number(data?.d ?? 0),
      changePercent: Number(data?.dp ?? 0),
    };
  } catch {
    return null;
  }
}

async function fetchMarketBundle() {
  assertToken();
  const settled = await Promise.allSettled([
    ...NEWS_CATEGORIES.map(fetchNews),
    ...PULSE.map((item) => fetchQuote(item.symbol, item.label)),
  ]);

  const articles = [];
  const quotes = [];
  const seen = new Set();

  for (const result of settled) {
    if (result.status !== 'fulfilled' || !result.value) continue;
    if (Array.isArray(result.value)) {
      for (const row of result.value) {
        const headline = String(row?.headline ?? '').trim();
        const url = String(row?.url ?? '').trim();
        const key = url || `${row?.id}-${headline}`;
        if (!headline || !url.startsWith('http') || seen.has(key)) continue;
        seen.add(key);
        articles.push({
          id: Number(row.id ?? 0),
          headline,
          summary: String(row.summary ?? '').trim(),
          source: String(row.source ?? 'Market wire').trim(),
          url,
          image: String(row.image ?? '').trim(),
          category: String(row.category ?? 'general').trim().toLowerCase(),
          datetime: Number(row.datetime ?? 0),
          related: String(row.related ?? '').trim(),
        });
      }
    } else {
      quotes.push(result.value);
    }
  }

  articles.sort((a, b) => b.datetime - a.datetime);

  if (articles.length === 0) {
    const error = new Error('No market headlines');
    error.status = 502;
    throw error;
  }

  return {
    articles: articles.slice(0, 60),
    quotes,
    fetchedAt: Date.now(),
  };
}

module.exports = { fetchMarketBundle };
