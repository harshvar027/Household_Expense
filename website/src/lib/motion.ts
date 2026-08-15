const BOOT_KEY = 'he-awards-boot';

export function prefersReducedMotion() {
  return typeof window !== 'undefined' && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
}

export function canHoverFine() {
  return typeof window !== 'undefined' && window.matchMedia('(hover: hover) and (pointer: fine)').matches;
}

export function hasBooted() {
  if (typeof window === 'undefined') return true;
  return sessionStorage.getItem(BOOT_KEY) === '1' || prefersReducedMotion();
}

export function markBooted() {
  sessionStorage.setItem(BOOT_KEY, '1');
}
