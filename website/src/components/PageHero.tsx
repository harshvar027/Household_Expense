import Logo from './Logo';

export default function PageHero({
  index,
  eyebrow,
  title,
  subtitle,
}: {
  index: string;
  eyebrow: string;
  title: string;
  subtitle?: string;
}) {
  return (
    <header className="relative overflow-hidden px-4 pb-14 pt-8 md:pb-20 md:pt-12">
      <div className="mx-auto max-w-6xl">
        <Logo size={72} className="mb-8" />
        <p className="font-mono text-[11px] uppercase tracking-[0.32em] text-mint">
          {index} / {eyebrow}
        </p>
        <h1 className="page-title mt-5 max-w-4xl font-display text-4xl font-normal leading-[0.95] tracking-tight text-ink sm:text-5xl md:text-6xl lg:text-7xl">
          {title}
        </h1>
        {subtitle ? (
          <p className="page-sub mt-6 max-w-xl text-base leading-relaxed text-muted md:text-lg">{subtitle}</p>
        ) : null}
      </div>
      <span
        aria-hidden
        className="pointer-events-none absolute -right-2 bottom-[-0.2em] select-none font-display text-[28vw] font-bold leading-none text-ink/[0.035] md:text-[18vw]"
      >
        {index}
      </span>
    </header>
  );
}
