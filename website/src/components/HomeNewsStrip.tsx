import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { ArrowUpRight } from 'lucide-react';
import { Magnetic } from './motion';
import {
  articleLens,
  fetchMarketBundle,
  filterArticles,
  lensLabel,
  relativeTime,
  type MarketArticle,
} from '../lib/news';

export default function HomeNewsStrip() {
  const [stories, setStories] = useState<MarketArticle[]>([]);

  useEffect(() => {
    let alive = true;
    fetchMarketBundle()
      .then((bundle) => {
        if (!alive) return;
        const economy = filterArticles(bundle.articles, 'economy');
        setStories((economy.length ? economy : bundle.articles).slice(0, 3));
      })
      .catch(() => undefined);
    return () => {
      alive = false;
    };
  }, []);

  if (stories.length === 0) return null;

  return (
    <section className="mx-auto max-w-6xl px-4 py-20 md:py-28">
      <div className="reveal flex flex-col gap-6 md:flex-row md:items-end md:justify-between">
        <div>
          <p className="font-mono text-[11px] uppercase tracking-[0.32em] text-mint">Economic wire</p>
          <h2 className="mt-3 font-display text-3xl font-bold tracking-tight md:text-5xl">
            What just moved the household.
          </h2>
        </div>
        <Magnetic>
          <Link to="/news" className="he-btn-mint inline-flex items-center gap-2 rounded-full bg-mint px-5 py-3 text-sm font-semibold text-on-mint">
            Open news <ArrowUpRight className="h-4 w-4" />
          </Link>
        </Magnetic>
      </div>
      <div className="mt-10 grid gap-4 md:grid-cols-3">
        {stories.map((article, index) => (
          <a
            key={`${article.id}-${article.url}`}
            href={article.url}
            target="_blank"
            rel="noreferrer"
            className="reveal he-news-card he-glass he-tilt overflow-hidden"
          >
            <div className="he-news-media relative h-40 overflow-hidden">
              {article.image ? (
                <img src={article.image} alt="" className="absolute inset-0 h-full w-full object-cover" />
              ) : (
                <div className="he-news-fallback absolute inset-0" />
              )}
              <div className="absolute inset-0 bg-gradient-to-t from-page/85 to-transparent" />
              <span className="absolute left-4 top-4 rounded-full border border-white/15 bg-black/35 px-2.5 py-1 font-mono text-[10px] uppercase tracking-[0.18em] text-snow">
                {lensLabel(articleLens(article))}
              </span>
            </div>
            <div className="p-5">
              <p className="font-mono text-[10px] uppercase tracking-[0.2em] text-muted">0{index + 1}</p>
              <h3 className="mt-2 font-display text-xl leading-tight tracking-tight">{article.headline}</h3>
              <p className="mt-3 font-mono text-[11px] uppercase tracking-[0.18em] text-muted">
                {article.source} · {relativeTime(article.datetime)}
              </p>
            </div>
          </a>
        ))}
      </div>
    </section>
  );
}
