import { useMemo } from 'react';
import { QRCodeSVG } from 'qrcode.react';
import { apkDownloadUrl } from '../lib/apk';

export default function InstallQr({ size = 200 }: { size?: number }) {
  const url = useMemo(() => apkDownloadUrl(), []);

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
          Phone camera downloads the APK from this website. Allow install from this source, then tap Open.
        </p>
      </div>
    </div>
  );
}
