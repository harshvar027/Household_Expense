import { useEffect } from 'react';
import { adsEnabled, adsenseClient } from '../lib/ads';

const SCRIPT_ID = 'he-adsense';

export default function AdScript() {
  useEffect(() => {
    if (!adsEnabled || document.getElementById(SCRIPT_ID)) return;
    const script = document.createElement('script');
    script.id = SCRIPT_ID;
    script.async = true;
    script.crossOrigin = 'anonymous';
    script.src = `https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=${adsenseClient}`;
    document.head.appendChild(script);
  }, []);

  return null;
}
