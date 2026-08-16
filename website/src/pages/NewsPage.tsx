import { useEffect, useMemo, useRef, useState } from 'react';
import gsap from 'gsap';
import { ArrowUpRight, Newspaper } from 'lucide-react';
import PageHero from '../components/PageHero';
import { Magnetic } from '../components/motion';
import { prefersReducedMotion } from '../lib/motion';
import {
  articleLens,
  fetchMarketBundle,
  filterArticles,
  lensLabel,
  relativeTime,
  touchesHousehold,
  type MarketArticle,
  type MarketBundle,
  type NewsLens,
} from '../lib/news';

const LENSES: { id: NewsLens; label: string }[] = [
  { id: 'all', label: 'All' },
  { id: 'economy', label: 'Economy' },
  { id: 'markets', label: 'Markets' },
  { id: 'forex', label: 'Forex' },
  { id: 'deals', label: 'Deals' },
];

export default function NewsPage() {
  const root = useRef<HTMLDivElement>(null);
  const [bundle, setBundle] = useState<MarketBundle | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [lens, setLens] = useState<NewsLens>('all');

  useEffect(() => {
    let alive = true;
    fetchMarketBundle()
      .then((data) => {
        if (!alive) return;
        setBundle(data);
        setError(null);
      })
      .catch((err: Error) => {
        if (!alive) return;
        setError(err.message);
      })
      .finally(() => {
        if (alive) setLoading(false);
      });
    return () => {
      alive = false;
    };
  }, []);

  const articles = useMemo(
    () => (bundle ? filterArticles(bundle.articles, lens) : []),
    [bundle, lens],
  );
  const featured = articles[0];
  const rest = articles.slice(1);

  useEffect(() => {
    if (!bundle || prefersReducedMotion()) return;
    const ctx = gsap.context(() => {
      gsap.from('.news-reveal', {
        y: 28,
        opacity: 0,
        duration: 0.7,
        stagger: 0.06,
        ease: 'power3.out',
      });
    }, root);
    return () => ctx.revert();
  }, [bundle, lens]);

  return (
    <div ref={root} className="pb-20">
      <PageHero
        index="04"
        eyebrow="News"
        title="Economic changes, written for the household."
        subtitle="Live market headlines from Finnhub — rates, inflation, oil, gold, and the moves that change a family budget."
      />

      {bundle && bundle.articles.length > 0 ? (
        <div className="he-marquee mb-10 border-y border-line py-3">
          <div className="he-marquee-track gap-10">
            {[0, 1].map((copy) => (
              <div key={copy} className="flex items-center gap-10 pr-10">
                {bundle.articles.slice(0, 12).map((article) => (
                  <span key={`${copy}-${article.id}-${article.headline}`} className="flex items-center gap-10">
                    <span className="font-mono text-[11px] uppercase tracking-[0.22em] text-mint">
                      {lensLabel(articleLens(article))}
                    </span>
                    <span className="font-display text-xl text-ink/85 md:text-2xl">{article.headline}</span>
                    <span className="h-1.5 w-1.5 rounded-full bg-mint" />
                  </span>
                ))}
              </div>
            ))}
          </div>
        </div>
      ) : null}

      <div className="mx-auto max-w-6xl px-4">
        {bundle?.quotes.length ? (
          <div className="news-reveal mb-8 grid grid-cols-2 gap-3 md:grid-cols-4">
            {bundle.quotes.map((quote) => {
              const up = quote.change >= 0;
              return (
                <article key={quote.symbol} className="he-glass px-4 py-4">
                  <p className="font-mono text-[10px] uppercase tracking-[0.22em] text-muted">{quote.label}</p>
                  <p className="mt-2 font-display text-2xl tracking-tight">{quote.price.toFixed(2)}</p>
                  <p className={`mt-1 text-sm font-semibold ${up ? 'text-mint' : 'text-amber'}`}>
                    {up ? '+' : ''}
                    {quote.changePercent.toFixed(2)}%
                  </p>
                </article>
              );
            })}
          </div>
        ) : null}

        <div className="news-reveal mb-8 flex flex-wrap items-center justify-between gap-4">
          <div className="flex flex-wrap gap-2">
            {LENSES.map((item) => {
              const active = lens === item.id;
              return (
                <button
                  key={item.id}
                  type="button"
                  onClick={() => setLens(item.id)}
                  className={`rounded-full border px-4 py-2 text-sm transition ${
                    active
                      ? 'border-mint/50 bg-mint/15 font-semibold text-ink'
                      : 'border-line bg-surface/40 text-muted hover:text-ink'
                  }`}
                >
                  {item.label}
                </button>
              );
            })}
          </div>
          <p className="font-mono text-[11px] uppercase tracking-[0.22em] text-muted">
            {bundle ? `Updated ${relativeTime(Math.floor(bundle.fetchedAt / 1000))}` : 'Finnhub wire'}
          </p>
        </div>

        {loading ? <NewsSkeleton /> : null}

        {!loading && error ? (
          <div className="he-glass px-6 py-12 text-center">
            <Newspaper className="mx-auto mb-4 h-8 w-8 text-mint" />
            <h2 className="font-display text-2xl">The wire is quiet</h2>
            <p className="mt-2 text-muted">{error}</p>
          </div>
        ) : null}

        {!loading && !error && featured ? (
          <>
            <FeaturedCard article={featured} />
            <div className="mt-6 grid gap-4 md:grid-cols-2">
              {rest.map((article, index) => (
                <StoryCard key={`${article.id}-${article.url}`} article={article} index={index} />
              ))}
            </div>
          </>
        ) : null}

        {!loading && !error && !featured ? (
          <div className="he-glass px-6 py-12 text-center">
            <h2 className="font-display text-2xl">No stories in this lens</h2>
            <p className="mt-2 text-muted">Try another filter. The wire refreshes throughout the day.</p>
          </div>
        ) : null}
      </div>
    </div>
  );
}

function FeaturedCard({ article }: { article: MarketArticle }) {
  const lens = articleLens(article);
  return (
    <a
      href={article.url}
      target="_blank"
      rel="noreferrer"
      className="news-reveal he-news-card he-glass group relative block overflow-hidden"
    >
      <div className="grid md:grid-cols-[1.15fr_0.85fr]">
        <div className="he-news-media relative min-h-[240px] overflow-hidden md:min-h-[360px]">
          {article.image ? (
            <img src={article.image} alt="" className="absolute inset-0 h-full w-full object-cover" />
          ) : (
            <div className="he-news-fallback absolute inset-0" />
          )}
          <div className="absolute inset-0 bg-gradient-to-t from-page via-page/20 to-transparent md:bg-gradient-to-r" />
        </div>
        <div className="relative flex flex-col justify-end p-6 md:p-8">
          <div className="mb-4 flex flex-wrap gap-2">
            <span className="rounded-full border border-mint/30 bg-mint/10 px-3 py-1 font-mono text-[10px] uppercase tracking-[0.22em] text-mint">
              {lensLabel(lens)}
            </span>
            {touchesHousehold(article) ? (
              <span className="rounded-full border border-amber/30 bg-amber/10 px-3 py-1 font-mono text-[10px] uppercase tracking-[0.22em] text-amber">
                Household
              </span>
            ) : null}
          </div>
          <h2 className="font-display text-3xl leading-[1.05] tracking-tight md:text-4xl">{article.headline}</h2>
          {article.summary ? (
            <p className="mt-4 line-clamp-3 text-sm leading-relaxed text-muted md:text-base">{article.summary}</p>
          ) : null}
          <div className="mt-6 flex items-center justify-between gap-3 text-sm text-muted">
            <span>
              {article.source} · {relativeTime(article.datetime)}
            </span>
            <Magnetic>
              <span className="inline-flex items-center gap-1 font-semibold text-mint">
                Read <ArrowUpRight className="h-4 w-4" />
              </span>
            </Magnetic>
          </div>
        </div>
      </div>
    </a>
  );
}

function StoryCard({ article, index }: { article: MarketArticle; index: number }) {
  const lens = articleLens(article);
  return (
    <a
      href={article.url}
      target="_blank"
      rel="noreferrer"
      className="news-reveal he-news-card he-glass he-tilt group overflow-hidden"
      style={{ animationDelay: `${index * 40}ms` }}
    >
      <div className="he-news-media relative h-44 overflow-hidden">
        {article.image ? (
          <img src={article.image} alt="" className="absolute inset-0 h-full w-full object-cover" />
        ) : (
          <div className="he-news-fallback absolute inset-0" />
        )}
        <div className="absolute inset-0 bg-gradient-to-t from-page/80 to-transparent" />
        <div className="absolute left-4 top-4 flex gap-2">
          <span className="rounded-full border border-white/15 bg-black/35 px-2.5 py-1 font-mono text-[10px] uppercase tracking-[0.18em] text-snow">
            {lensLabel(lens)}
          </span>
        </div>
      </div>
      <div className="p-5">
        <h3 className="font-display text-xl leading-tight tracking-tight">{article.headline}</h3>
        {article.summary ? (
          <p className="mt-2 line-clamp-2 text-sm leading-relaxed text-muted">{article.summary}</p>
        ) : null}
        <p className="mt-4 font-mono text-[11px] uppercase tracking-[0.18em] text-muted">
          {article.source} · {relativeTime(article.datetime)}
        </p>
      </div>
    </a>
  );
}

function NewsSkeleton() {
  return (
    <div className="grid gap-4">
      <div className="he-shimmer h-72 rounded-[1.25rem]" />
      <div className="grid gap-4 md:grid-cols-2">
        <div className="he-shimmer h-64 rounded-[1.25rem]" />
        <div className="he-shimmer h-64 rounded-[1.25rem]" />
      </div>
    </div>
  );
}
