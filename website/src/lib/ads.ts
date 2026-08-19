export type AdFormat = 'banner' | 'inline' | 'rectangle';

const client = (import.meta.env.VITE_ADSENSE_CLIENT ?? '').trim();
const slots = {
  banner: (import.meta.env.VITE_ADSENSE_SLOT_BANNER ?? '').trim(),
  inline: (import.meta.env.VITE_ADSENSE_SLOT_INLINE ?? '').trim(),
  rectangle: (import.meta.env.VITE_ADSENSE_SLOT_RECT ?? '').trim(),
};

export const adsenseClient = client;
export const adsenseSlots = slots;
export const adsEnabled = /^ca-pub-\d+$/.test(client);

export function slotFor(format: AdFormat) {
  return slots[format] || slots.banner || slots.inline || slots.rectangle;
}

export function adsTxtBody() {
  const pub = client.replace(/^ca-/, '');
  if (!/^pub-\d+$/.test(pub)) {
    return '# Add VITE_ADSENSE_CLIENT=ca-pub-XXXXXXXX to emit a live ads.txt\n';
  }
  return `google.com, ${pub}, DIRECT, f08c47fec0942fa0\n`;
}
