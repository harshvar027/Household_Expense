import { lazy, Suspense, useEffect, useRef } from 'react';
import { Link } from 'react-router-dom';
import gsap from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';
import { ArrowDown, ArrowUpRight, Fingerprint, Lock, PieChart, ShieldCheck } from 'lucide-react';
import { CountUp, Magnetic } from '../components/motion';
import { prefersReducedMotion } from '../lib/motion';
import Logo from '../components/Logo';
import InstallQr from '../components/InstallQr';

const HeroScene = lazy(() => import('./HeroScene'));

gsap.registerPlugin(ScrollTrigger);

const MARQUEE = [
  'SQLCipher vault',
  'Bank import',
  'Budgets',
  'Goals',
  'PIN lock',
  'Biometrics',
  'CSV · Excel · PDF',
  'On-device',
  'No cloud ledger',
  '₹100 / month',
  '₹600 / year',
];

const FEATURES = [
  {
    index: '01',
    title: 'Capture without the cloud',
    body: 'Manual entry, SMS paste, receipts, splits, and India-first bank statements — parsed where the money already lives.',
  },
  {
    index: '02',
    title: 'Budgets that stay honest',
    body: 'Envelopes, category caps, and goals that read the real ledger. Recurring bills surface before they go missing.',
  },
  {
    index: '03',
    title: 'A vault, not a sync product',
    body: 'SQLCipher, secure keys, background lock. Backups exist only when you export them.',
  },
];

export default function HomePage() {
  const root = useRef<HTMLDivElement>(null);
  const pin = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const ctx = gsap.context(() => {
      if (!prefersReducedMotion()) {
        gsap.from('.hero-line', {
          yPercent: 112,
          duration: 1.2,
          stagger: 0.11,
          ease: 'power4.out',
          delay: 0.12,
        });
        gsap.from('.hero-meta', {
          y: 24,
          opacity: 0,
          duration: 0.9,
          stagger: 0.08,
          ease: 'power3.out',
          delay: 0.55,
        });
      }

      gsap.utils.toArray<HTMLElement>('.reveal').forEach((el) => {
        gsap.from(el, {
          scrollTrigger: { trigger: el, start: 'top 86%' },
          y: 40,
          opacity: 0,
          duration: 0.85,
          ease: 'power3.out',
        });
      });

      const mm = gsap.matchMedia();
      mm.add('(min-width: 768px)', () => {
        const track = pin.current;
        if (!track) return;
        const row = track.querySelector<HTMLElement>('.pin-row');
        if (!row) return;
        gsap.to(row, {
          x: () => -(row.scrollWidth - track.clientWidth),
          ease: 'none',
          scrollTrigger: {
            trigger: track,
            start: 'top 18%',
            end: () => `+=${row.scrollWidth}`,
            pin: true,
            scrub: 0.8,
            anticipatePin: 1,
          },
        });
      });
    }, root);

    return () => ctx.revert();
  }, []);

  return (
    <div ref={root}>
      <section className="relative min-h-[100svh] overflow-hidden he-grid">
        <div className="pointer-events-none absolute inset-0 z-0">
          <Suspense fallback={null}>
            <HeroScene />
          </Suspense>
          <div className="absolute inset-0 he-hero-fade" />
        </div>

        <div className="relative z-10 mx-auto flex min-h-[calc(100svh-4.75rem)] max-w-6xl flex-col justify-end px-4 pb-10 pt-10 md:justify-center md:pb-16">
          <div className="hero-meta mb-6">
            <Logo size={88} />
          </div>
          <div className="hero-meta mb-7 flex items-center gap-3 font-mono text-[11px] uppercase tracking-[0.32em] text-mint">
            <span className="h-px w-8 bg-mint/70" />
            Private · On-device · India
          </div>

          <h1 className="max-w-4xl font-display text-[12vw] font-normal leading-[0.92] tracking-tight text-ink [text-shadow:0_8px_40px_var(--he-page)] sm:text-7xl md:text-8xl lg:text-[6.4rem]">
            {['Your money.', 'Locked on', 'your phone.'].map((line) => (
              <span key={line} className="block overflow-hidden">
                <span className="hero-line block">{line}</span>
              </span>
            ))}
          </h1>

          <p className="hero-meta mt-6 max-w-md text-base leading-relaxed text-muted md:text-lg">
            Family finance with bank import, budgets, and a neo-glass shell — encrypted locally.
            No cloud ledger required.
          </p>

          <div className="hero-meta mt-9 flex flex-wrap items-center gap-3">
            <Magnetic>
              <Link
                to="/download"
                className="he-btn-mint inline-flex items-center gap-2 rounded-full bg-mint px-6 py-3.5 font-semibold text-on-mint shadow-[0_0_40px_rgba(46,230,166,0.22)]"
              >
                Get the Android app <ArrowUpRight className="h-4 w-4" />
              </Link>
            </Magnetic>
            <Magnetic>
              <Link
                to="/product"
                className="inline-flex items-center gap-2 rounded-full border border-line bg-surface/50 px-6 py-3.5 font-medium text-ink backdrop-blur"
              >
                Explore product
              </Link>
            </Magnetic>
          </div>

          <div className="hero-meta mt-10">
            <InstallQr size={168} />
          </div>
        </div>

        <div className="absolute bottom-6 left-4 hidden items-center gap-3 font-mono text-[10px] uppercase tracking-[0.28em] text-muted md:flex">
          <span className="he-scroll-line" />
          Scroll
          <ArrowDown className="h-3 w-3" />
        </div>

        <div className="absolute bottom-10 right-6 hidden md:block" aria-hidden>
          <div className="he-spin-slow relative h-28 w-28">
            <svg viewBox="0 0 100 100" className="h-full w-full">
              <path
                id="he-circle-path"
                d="M50,50 m-38,0 a38,38 0 1,1 76,0 a38,38 0 1,1 -76,0"
                fill="none"
              />
              <text className="fill-muted text-[9px] uppercase tracking-[0.28em]">
                <textPath href="#he-circle-path">On-device vault · Scroll to explore · </textPath>
              </text>
            </svg>
          </div>
        </div>
      </section>

      <div className="he-marquee border-y border-line py-4">
        <div className="he-marquee-track gap-10">
          {[0, 1].map((copy) => (
            <div key={copy} className="flex items-center gap-10 pr-10">
              {MARQUEE.map((item) => (
                <span key={`${copy}-${item}`} className="flex items-center gap-10">
                  <span className="font-display text-2xl font-semibold tracking-tight text-ink/80 md:text-3xl">
                    {item}
                  </span>
                  <span className="h-1.5 w-1.5 rounded-full bg-mint" />
                </span>
              ))}
            </div>
          ))}
        </div>
      </div>

      <section className="mx-auto max-w-6xl px-4 py-24 md:py-32">
        <div className="reveal grid gap-10 md:grid-cols-[1fr_1.2fr] md:items-end">
          <p className="font-mono text-[11px] uppercase tracking-[0.32em] text-mint">Manifesto</p>
          <p className="text-sm text-muted md:text-right">The product is the vault — not the account.</p>
        </div>
        <h2 className="reveal mt-6 max-w-5xl font-display text-4xl font-normal leading-[0.95] tracking-tight md:text-6xl lg:text-7xl">
          The ledger never leaves the device.
        </h2>
        <p className="reveal mt-8 max-w-xl text-muted md:text-lg">
          Sync-first money apps trade convenience for a server. Household Expense keeps SQLCipher,
          keys, and statements on the phone you already hold.
        </p>
      </section>

      <section ref={pin} className="relative overflow-x-auto overflow-y-hidden px-4 pb-8 md:overflow-hidden md:pb-16">
        <div className="pin-row flex w-max gap-5 md:gap-6">
          {FEATURES.map((f) => (
            <article
              key={f.index}
              className="he-glass he-tilt w-[min(88vw,420px)] shrink-0 p-8 md:h-[420px] md:w-[520px] md:p-10"
            >
              <p className="font-mono text-xs tracking-[0.28em] text-mint">{f.index}</p>
              <h3 className="mt-8 font-display text-3xl font-bold leading-tight tracking-tight md:text-4xl">
                {f.title}
              </h3>
              <p className="mt-5 max-w-sm text-sm leading-relaxed text-muted md:text-base">{f.body}</p>
            </article>
          ))}
        </div>
      </section>

      <section className="mx-auto grid max-w-6xl gap-4 px-4 py-20 sm:grid-cols-3">
        {[
          { icon: Lock, title: 'On-device vault', body: 'SQLCipher encryption. The household ledger never needs a server to open.' },
          { icon: PieChart, title: 'Budgets & goals', body: 'Envelopes, category caps, and savings targets that read real spend.' },
          { icon: ShieldCheck, title: 'Privacy-first', body: 'PIN, biometrics, and user-initiated backups — not silent cloud sync.' },
        ].map((card, i) => (
          <article key={card.title} className="reveal he-glass he-tilt p-6 md:p-7">
            <card.icon className="mb-5 h-5 w-5 text-mint" />
            <p className="font-mono text-[10px] tracking-[0.28em] text-muted">0{i + 1}</p>
            <h3 className="mt-2 font-display text-xl font-semibold text-ink">{card.title}</h3>
            <p className="mt-3 text-sm leading-relaxed text-muted">{card.body}</p>
          </article>
        ))}
      </section>

      <section className="border-y border-line">
        <div className="mx-auto grid max-w-6xl divide-y divide-line md:grid-cols-3 md:divide-x md:divide-y-0">
          {[
            { end: 6, prefix: '', suffix: '', label: 'Months of full trial' },
            { end: 100, prefix: '₹', suffix: '', label: 'Monthly Pro' },
            { end: 600, prefix: '₹', suffix: '', label: 'Yearly Pro' },
          ].map((stat) => (
            <div key={stat.label} className="px-6 py-12 text-center md:py-16">
              <p className="font-display text-5xl font-normal tracking-tight md:text-6xl">
                <CountUp end={stat.end} prefix={stat.prefix} suffix={stat.suffix} />
              </p>
              <p className="mt-3 font-mono text-[11px] uppercase tracking-[0.22em] text-muted">{stat.label}</p>
            </div>
          ))}
        </div>
      </section>

      <section className="mx-auto max-w-6xl px-4 py-24 md:py-32">
        <div className="reveal flex items-end justify-between gap-6">
          <h2 className="font-display text-3xl font-bold tracking-tight md:text-5xl">How the vault works</h2>
          <Fingerprint className="hidden h-10 w-10 text-mint/50 md:block" />
        </div>
        <ol className="mt-12 space-y-0">
          {[
            ['Lock', 'Register once. Unlock with PIN or biometrics. The database stays encrypted at rest.'],
            ['Capture', 'Add spend five ways — including India bank PDFs — without leaving the phone.'],
            ['Steer', 'Budgets, goals, and household members sit on the same local ledger.'],
          ].map(([title, body], i) => (
            <li
              key={title}
              className="reveal group grid gap-4 border-t border-line py-8 md:grid-cols-[120px_1fr_1.4fr] md:items-baseline"
            >
              <span className="font-mono text-sm text-mint">0{i + 1}</span>
              <h3 className="font-display text-2xl font-semibold tracking-tight md:text-3xl">{title}</h3>
              <p className="text-muted">{body}</p>
            </li>
          ))}
        </ol>
      </section>
    </div>
  );
}
