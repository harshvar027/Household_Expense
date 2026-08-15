/** Same-origin APK so the private GitHub repo is never used for downloads. */
export function apkDownloadUrl() {
  if (typeof window === 'undefined') return '/downloads/latest.apk';
  return `${window.location.origin}/downloads/latest.apk`;
}
