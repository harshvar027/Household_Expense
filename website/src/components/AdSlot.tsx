import { useEffect, useRef } from 'react';
import { adsEnabled, adsenseClient, slotFor, type AdFormat } from '../lib/ads';

declare global {
  interface Window {
    adsbygoogle?: unknown[];
  }
}

const SIZE: Record<AdFormat, { minHeight: number; label: string }> = {
  banner: { minHeight: 90, label: 'Display' },
  inline: { minHeight: 120, label: 'In-feed' },
  rectangle: { minHeight: 250, label: 'Rectangle' },
};

export default function AdSlot({
  format = 'banner',
  className = '',
}: {
  format?: AdFormat;
  className?: string;
}) {
  const insRef = useRef<HTMLModElement>(null);
  const pushed = useRef(false);
  const slot = slotFor(format);
  const live = adsEnabled && Boolean(slot);
  const size = SIZE[format];

  useEffect(() => {
    if (!live || pushed.current || !insRef.current) return;
    try {
      (window.adsbygoogle = window.adsbygoogle || []).push({});
      pushed.current = true;
    } catch {
      // AdSense throws if the unit is already filled during HMR.
    }
  }, [live]);

  return (
    <aside
      className={`he-ad he-ad-${format} ${className}`.trim()}
      aria-label="Sponsored"
    >
      <div className="he-ad-meta">
        <span>Sponsored</span>
        <span>{size.label}</span>
      </div>
      <div className="he-ad-frame" style={{ minHeight: size.minHeight }}>
        {live ? (
          <ins
            ref={insRef}
            className="adsbygoogle"
            style={{ display: 'block', width: '100%', minHeight: size.minHeight }}
            data-ad-client={adsenseClient}
            data-ad-slot={slot}
            data-ad-format={format === 'banner' ? 'horizontal' : 'auto'}
            data-full-width-responsive="true"
          />
        ) : (
          <div className="he-ad-placeholder">
            <span className="he-ad-placeholder-mark" />
            <p>Advertisement</p>
            <p>Household Expense</p>
          </div>
        )}
      </div>
    </aside>
  );
}
