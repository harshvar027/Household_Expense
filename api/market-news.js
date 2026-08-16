const { fetchMarketBundle } = require('./finnhub.cjs');

module.exports = async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Cache-Control', 's-maxage=180, stale-while-revalidate=600');

  if (req.method === 'OPTIONS') {
    res.status(204).end();
    return;
  }

  try {
    const payload = await fetchMarketBundle();
    res.status(200).json(payload);
  } catch (error) {
    const missing = error?.message === 'Missing FINNHUB_API_KEY';
    res.status(missing ? 401 : 502).json({
      error: missing
        ? 'Add FINNHUB_API_KEY to unlock the economic wire.'
        : 'Market news is unavailable right now.',
    });
  }
};
