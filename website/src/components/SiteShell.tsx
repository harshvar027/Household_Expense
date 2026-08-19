import { Component, lazy, Suspense, useCallback, useEffect, useRef, useState, type ReactNode } from 'react';
import { Link, NavLink, Outlet, useLocation } from 'react-router-dom';
import gsap from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';
import Lenis from 'lenis';
import { ArrowUpRight, Moon, Sun, X } from 'lucide-react';
import { useTheme } from '../context/ThemeContext';
import { Cursor, Magnetic, Preloader } from './motion';
import { hasBooted, prefersReducedMotion } from '../lib/motion';
import Logo from './Logo';
import AdScript from './AdScript';
import AdSlot from './AdSlot';

const BackgroundField = lazy(() => import('./BackgroundField'));

gsap.registerPlugin(ScrollTrigger);

class SceneGuard extends Component<{ children: ReactNode }, { failed: boolean }> {
  state = { failed: false };
  static getDerivedStateFromError() {
    return { failed: true };
  }
  render() {
    if (this.state.failed) return null;
    return this.props.children;
  }
}

const LINKS = [
  { to: '/product', label: 'Product', index: '01' },
  { to: '/privacy', label: 'Privacy', index: '02' },
  { to: '/pricing', label: 'Pricing', index: '03' },
  { to: '/news', label: 'News', index: '04' },
  { to: '/about', label: 'About', index: '05' },
];

export default function SiteShell() {
  const { isDark, toggle } = useTheme();
  const location = useLocation();
  const [menuOpen, setMenuOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);
  const [booted, setBooted] = useState(() => hasBooted());
  const [showLoader, setShowLoader] = useState(!hasBooted());
  const lenisRef = useRef<Lenis | null>(null);
  const headerRef = useRef<HTMLElement>(null);
  const navRef = useRef<HTMLElement>(null);
  const indicatorRef = useRef<HTMLSpanElement>(null);
  const progressRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const lenis = new Lenis({
      smoothWheel: true,
      duration: prefersReducedMotion() ? 0 : 1.15,
    });
    lenisRef.current = lenis;
    lenis.on('scroll', ScrollTrigger.update);
    const raf = (time: number) => lenis.raf(time * 1000);
    gsap.ticker.add(raf);
    gsap.ticker.lagSmoothing(0);

    const onScroll = () => setScrolled(window.scrollY > 24);
    onScroll();
    window.addEventListener('scroll', onScroll, { passive: true });

    const progress = progressRef.current;
    let st: ScrollTrigger | undefined;
    if (progress) {
      st = ScrollTrigger.create({
        start: 0,
        end: 'max',
        onUpdate: (self) => {
          gsap.set(progress, { scaleX: self.progress });
        },
      });
    }

    return () => {
      window.removeEventListener('scroll', onScroll);
      st?.kill();
      gsap.ticker.remove(raf);
      lenis.destroy();
      lenisRef.current = null;
    };
  }, []);

  useEffect(() => {
    if (menuOpen) lenisRef.current?.stop();
    else lenisRef.current?.start();
    document.body.style.overflow = menuOpen ? 'hidden' : '';
    if (menuOpen && !prefersReducedMotion()) {
      gsap.fromTo(
        '.mobile-link',
        { y: 28, opacity: 0 },
        { y: 0, opacity: 1, stagger: 0.06, duration: 0.55, ease: 'power3.out' },
      );
    }
    return () => {
      document.body.style.overflow = '';
    };
  }, [menuOpen]);

  useEffect(() => {
    setMenuOpen(false);
    lenisRef.current?.scrollTo(0, { immediate: true });
    requestAnimationFrame(() => ScrollTrigger.refresh());
    if (location.pathname === '/' || prefersReducedMotion()) return;
    const ctx = gsap.context(() => {
      gsap.from('.page-title', { y: 36, opacity: 0, duration: 0.9, ease: 'power4.out' });
      gsap.from('.page-sub', { y: 18, opacity: 0, duration: 0.75, delay: 0.08, ease: 'power3.out' });
    });
    return () => ctx.revert();
  }, [location.pathname]);

  useEffect(() => {
    if (!booted || prefersReducedMotion()) return;
    const ctx = gsap.context(() => {
      gsap.from(headerRef.current, {
        y: -28,
        opacity: 0,
        duration: 0.9,
        ease: 'power4.out',
      });
    });
    return () => ctx.revert();
  }, [booted]);

  useEffect(() => {
    const nav = navRef.current;
    const indicator = indicatorRef.current;
    if (!nav || !indicator) return;
    const active = nav.querySelector<HTMLElement>('a[aria-current="page"]');
    const move = (el: HTMLElement | null) => {
      if (!el) {
        gsap.to(indicator, { opacity: 0, duration: 0.25 });
        return;
      }
      const nr = nav.getBoundingClientRect();
      const r = el.getBoundingClientRect();
      gsap.to(indicator, {
        opacity: 1,
        x: r.left - nr.left,
        width: r.width,
        duration: 0.45,
        ease: 'power3.out',
      });
    };
    move(active);
    const onResize = () => move(nav.querySelector<HTMLElement>('a[aria-current="page"]'));
    window.addEventListener('resize', onResize);
    return () => window.removeEventListener('resize', onResize);
  }, [location.pathname, booted]);

  const onLoaderDone = useCallback(() => {
    setShowLoader(false);
    setBooted(true);
  }, []);

  return (
    <div className="relative min-h-screen bg-page text-ink">
      <AdScript />
      {showLoader ? <Preloader onDone={onLoaderDone} /> : null}
      <Cursor />
      <div className="he-wash" aria-hidden />
      <div className="he-floor" aria-hidden>
        <div className="he-floor-grid" />
      </div>
      <div className="he-dots" aria-hidden />
      <SceneGuard>
        <Suspense fallback={null}>
          <BackgroundField />
        </Suspense>
      </SceneGuard>
      <div className="he-orb he-orb-a" aria-hidden />
      <div className="he-orb he-orb-b" aria-hidden />
      <div className="he-orb he-orb-c" aria-hidden />
      <div className="he-noise" aria-hidden />
      <div ref={progressRef} className="he-progress" aria-hidden />

      <header ref={headerRef} className="fixed inset-x-0 top-0 z-50 px-3 pt-3 sm:px-4 sm:pt-4">
        <div className="mx-auto w-full max-w-6xl">
          <div
            className={`he-header-glass flex items-center justify-between gap-3 rounded-full px-3 py-2 pl-4 sm:px-4 ${
              scrolled || menuOpen ? 'is-solid' : ''
            }`}
          >
            <Link to="/" className="group flex items-center gap-2" aria-label="Household Expense home">
              <Logo size={42} withWordmark />
            </Link>

            <nav
              ref={navRef}
              className="relative hidden items-center gap-0 lg:flex"
              aria-label="Primary"
            >
              <span ref={indicatorRef} className="he-nav-indicator" aria-hidden />
              {LINKS.map((l) => (
                <NavLink
                  key={l.to}
                  to={l.to}
                  className={({ isActive }) =>
                    `relative z-10 flex items-center gap-2 rounded-full px-3.5 py-2 text-[13px] transition hover:text-ink ${
                      isActive ? 'font-semibold text-ink' : 'text-muted'
                    }`
                  }
                >
                  <span className="font-mono text-[10px] tracking-widest text-mint/80">{l.index}</span>
                  {l.label}
                </NavLink>
              ))}
            </nav>

            <div className="flex items-center gap-1.5 sm:gap-2">
              <button
                type="button"
                onClick={toggle}
                aria-label={isDark ? 'Switch to light theme' : 'Switch to dark theme'}
                className="inline-flex h-9 w-9 items-center justify-center rounded-full border border-line text-ink transition hover:border-mint/40"
              >
                {isDark ? <Sun className="h-4 w-4" /> : <Moon className="h-4 w-4" />}
              </button>
              <Magnetic className="hidden sm:block">
                <Link
                  to="/download"
                  className="he-btn-mint inline-flex items-center gap-1.5 rounded-full bg-mint px-4 py-2 text-[13px] font-semibold text-on-mint"
                >
                  Get app <ArrowUpRight className="h-3.5 w-3.5" />
                </Link>
              </Magnetic>
              <button
                type="button"
                className="inline-flex h-9 w-9 items-center justify-center rounded-full border border-line lg:hidden"
                aria-label={menuOpen ? 'Close menu' : 'Open menu'}
                aria-expanded={menuOpen}
                onClick={() => setMenuOpen((v) => !v)}
              >
                {menuOpen ? (
                  <X className="h-4 w-4" />
                ) : (
                  <span className="flex flex-col gap-1">
                    <span className="block h-px w-3.5 bg-ink" />
                    <span className="block h-px w-2.5 bg-ink" />
                  </span>
                )}
              </button>
            </div>
          </div>
        </div>
      </header>

      {menuOpen ? (
        <div className="fixed inset-0 z-40 flex flex-col justify-end bg-page/95 px-6 pb-10 pt-28 backdrop-blur-xl lg:hidden">
          <div className="mb-8">
            <Logo size={64} withWordmark />
          </div>
          <nav className="flex flex-col gap-1" aria-label="Mobile">
            {LINKS.map((l) => (
              <NavLink
                key={l.to}
                to={l.to}
                className="mobile-link flex items-baseline justify-between border-b border-line py-4"
                onClick={() => setMenuOpen(false)}
              >
                <span className="font-display text-4xl font-bold tracking-tight">{l.label}</span>
                <span className="font-mono text-xs text-mint">{l.index}</span>
              </NavLink>
            ))}
            <Link
              to="/download"
              onClick={() => setMenuOpen(false)}
              className="mt-6 inline-flex items-center justify-center gap-2 rounded-full bg-mint py-4 font-semibold text-on-mint"
            >
              Get the app <ArrowUpRight className="h-4 w-4" />
            </Link>
          </nav>
        </div>
      ) : null}

      <main className="relative z-10 pt-[4.75rem]">
        <Outlet />
        <div className="mx-auto mt-6 max-w-6xl px-4 pb-4">
          <AdSlot format="banner" />
        </div>
      </main>

      <footer className="relative z-10 overflow-hidden border-t border-line">
        <div className="mx-auto max-w-6xl px-4 py-16 md:py-20">
          <p className="font-mono text-[11px] uppercase tracking-[0.32em] text-mint">Next</p>
          <div className="mt-4 flex flex-col gap-8 md:flex-row md:items-end md:justify-between">
            <h2 className="max-w-xl font-display text-4xl font-normal leading-[0.95] tracking-tight md:text-6xl">
              Keep the ledger
              <br />
              on the device.
            </h2>
            <Magnetic>
              <Link
                to="/download"
                className="he-btn-mint inline-flex items-center gap-2 rounded-full bg-mint px-6 py-3.5 font-semibold text-on-mint"
              >
                Download APK <ArrowUpRight className="h-4 w-4" />
              </Link>
            </Magnetic>
          </div>
          <div className="mt-14 flex flex-col gap-6 border-t border-line pt-8 text-sm text-muted md:flex-row md:items-center md:justify-between">
            <Link to="/" className="inline-flex">
              <Logo size={52} withWordmark />
            </Link>
            <div className="flex flex-wrap gap-x-6 gap-y-2">
              {LINKS.map((l) => (
                <Link key={l.to} to={l.to} className="he-link-line">
                  {l.label}
                </Link>
              ))}
              <Link to="/download" className="he-link-line">
                Download
              </Link>
            </div>
            <p className="font-mono text-[11px] tracking-widest">© {new Date().getFullYear()}</p>
          </div>
        </div>
      </footer>
    </div>
  );
}
