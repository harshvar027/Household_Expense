import {
  useCallback,
  useEffect,
  useRef,
  type MouseEvent as ReactMouseEvent,
  type ReactNode,
} from 'react';
import gsap from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';
import { canHoverFine, markBooted, prefersReducedMotion } from '../lib/motion';

gsap.registerPlugin(ScrollTrigger);

export function Magnetic({
  children,
  className,
  strength = 0.32,
}: {
  children: ReactNode;
  className?: string;
  strength?: number;
}) {
  const ref = useRef<HTMLDivElement>(null);

  const onMove = (e: ReactMouseEvent) => {
    if (prefersReducedMotion() || !canHoverFine() || !ref.current) return;
    const r = ref.current.getBoundingClientRect();
    gsap.to(ref.current, {
      x: (e.clientX - r.left - r.width / 2) * strength,
      y: (e.clientY - r.top - r.height / 2) * strength,
      duration: 0.4,
      ease: 'power3.out',
    });
  };

  const onLeave = () => {
    if (!ref.current) return;
    gsap.to(ref.current, { x: 0, y: 0, duration: 0.75, ease: 'elastic.out(1, 0.45)' });
  };

  return (
    <div ref={ref} className={className} onMouseMove={onMove} onMouseLeave={onLeave}>
      {children}
    </div>
  );
}

export function CountUp({
  end,
  prefix = '',
  suffix = '',
  className,
}: {
  end: number;
  prefix?: string;
  suffix?: string;
  className?: string;
}) {
  const ref = useRef<HTMLSpanElement>(null);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    if (prefersReducedMotion()) {
      el.textContent = `${prefix}${end.toLocaleString('en-IN')}${suffix}`;
      return;
    }
    const obj = { v: 0 };
    const st = ScrollTrigger.create({
      trigger: el,
      start: 'top 88%',
      once: true,
      onEnter: () => {
        gsap.to(obj, {
          v: end,
          duration: 1.7,
          ease: 'power3.out',
          onUpdate: () => {
            el.textContent = `${prefix}${Math.round(obj.v).toLocaleString('en-IN')}${suffix}`;
          },
        });
      },
    });
    return () => {
      st.kill();
    };
  }, [end, prefix, suffix]);

  return (
    <span ref={ref} className={className}>
      {prefix}0{suffix}
    </span>
  );
}

export function Cursor() {
  const dot = useRef<HTMLDivElement>(null);
  const ring = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!canHoverFine() || prefersReducedMotion()) return;
    const root = document.documentElement;
    root.classList.add('he-cursor-on');

    gsap.set([dot.current, ring.current], { xPercent: -50, yPercent: -50 });

    const move = (e: MouseEvent) => {
      gsap.to(dot.current, { x: e.clientX, y: e.clientY, duration: 0.08, overwrite: 'auto' });
      gsap.to(ring.current, { x: e.clientX, y: e.clientY, duration: 0.32, ease: 'power3.out', overwrite: 'auto' });
    };

    const hoverOn = () => {
      gsap.to(ring.current, { scale: 1.85, duration: 0.35, ease: 'power3.out' });
      gsap.to(dot.current, { scale: 0.4, duration: 0.35 });
    };
    const hoverOff = () => {
      gsap.to(ring.current, { scale: 1, duration: 0.35, ease: 'power3.out' });
      gsap.to(dot.current, { scale: 1, duration: 0.35 });
    };

    const over = (e: MouseEvent) => {
      if (e.target instanceof Element && e.target.closest('a, button, summary, [data-cursor]')) hoverOn();
    };
    const out = (e: MouseEvent) => {
      if (e.target instanceof Element && e.target.closest('a, button, summary, [data-cursor]')) hoverOff();
    };

    window.addEventListener('mousemove', move);
    document.addEventListener('mouseover', over);
    document.addEventListener('mouseout', out);

    return () => {
      root.classList.remove('he-cursor-on');
      window.removeEventListener('mousemove', move);
      document.removeEventListener('mouseover', over);
      document.removeEventListener('mouseout', out);
    };
  }, []);

  return (
    <>
      <div ref={ring} className="he-cursor-ring" aria-hidden />
      <div ref={dot} className="he-cursor-dot" aria-hidden />
    </>
  );
}

export function Preloader({ onDone }: { onDone: () => void }) {
  const wrap = useRef<HTMLDivElement>(null);
  const count = useRef<HTMLSpanElement>(null);
  const once = useRef(false);
  const done = useCallback(() => {
    if (once.current) return;
    once.current = true;
    markBooted();
    onDone();
  }, [onDone]);

  useEffect(() => {
    const finish = () => done();
    if (prefersReducedMotion()) {
      finish();
      return;
    }
    const safety = window.setTimeout(finish, 2800);
    const obj = { v: 0 };
    const tl = gsap.timeline({
      onComplete: () => {
        gsap.to(wrap.current, {
          yPercent: -110,
          duration: 0.8,
          ease: 'power4.inOut',
          onComplete: finish,
        });
      },
    });
    tl.from('.pre-brand', { y: 28, opacity: 0, duration: 0.55, ease: 'power3.out' });
    tl.to(
      obj,
      {
        v: 100,
        duration: 1.25,
        ease: 'power2.inOut',
        onUpdate: () => {
          if (count.current) count.current.textContent = String(Math.round(obj.v)).padStart(2, '0');
        },
      },
      0.15,
    );
    tl.to('.pre-bar-fill', { scaleX: 1, duration: 1.25, ease: 'power2.inOut' }, 0.15);
    return () => {
      window.clearTimeout(safety);
      tl.kill();
    };
  }, [done]);

  return (
    <div
      ref={wrap}
      className="fixed inset-0 z-[90] flex flex-col justify-between bg-page px-6 py-8 text-ink md:px-10"
    >
      <div className="flex items-center justify-between font-mono text-[11px] uppercase tracking-[0.28em] text-muted">
        <span>Household Expense</span>
        <span>Private vault</span>
      </div>
      <div className="pre-brand mx-auto max-w-3xl text-center">
        <p className="font-mono text-xs tracking-[0.4em] text-mint">INDEX / 00</p>
        <img
          src="/branding/app_logo.png"
          alt="Household Expense"
          className="he-logo mx-auto mt-5 h-40 w-40 object-contain sm:h-52 sm:w-52"
        />
        <p className="mt-3 text-sm text-muted">Loading the on-device ledger</p>
      </div>
      <div className="flex items-end justify-between gap-8">
        <span ref={count} className="font-display text-5xl font-bold tabular-nums md:text-7xl">
          00
        </span>
        <div className="mb-3 h-px flex-1 origin-left overflow-hidden bg-line">
          <div className="pre-bar-fill h-full origin-left scale-x-0 bg-mint" />
        </div>
        <span className="font-mono text-[11px] tracking-[0.28em] text-muted">100</span>
      </div>
    </div>
  );
}
