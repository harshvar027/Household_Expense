import { useMemo } from 'react';
import { QRCodeSVG } from 'qrcode.react';

function apkInstallUrl() {
  if (typeof window === 'undefined') return `${__INSTALL_ORIGIN__}/downloads/latest.apk`;
  const host = window.location.hostname;
  const local = host === 'localhost' || host === '127.0.0.1';
  const origin = local ? __INSTALL_ORIGIN__ : window.location.origin;
  return `${origin}/downloads/latest.apk`;
}

export default function InstallQr({ size = 200 }: { size?: number }) {
  const url = useMemo(() => apkInstallUrl(), []);

  return (
    <div className="he-glass inline-flex flex-col items-center gap-4 p-5">
      <div className="rounded-2xl bg-white p-3">
        <QRCodeSVG
          value={url}
          size={size}
          bgColor="#ffffff"
          fgColor="#0c6b5c"
          level="M"
          includeMargin={false}
          imageSettings={{
            src: '/branding/favicon.png',
            height: Math.round(size * 0.18),
            width: Math.round(size * 0.18),
            excavate: true,
          }}
        />
      </div>
      <div className="max-w-[220px] text-center">
        <p className="font-display text-lg text-ink">Scan to install</p>
        <p className="mt-1 text-xs leading-relaxed text-muted">
          Phone camera opens the APK. Allow install from this source, then tap Open.
        </p>
      </div>
    </div>
  );
}
