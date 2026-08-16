import { Download } from 'lucide-react';
import PageHero from '../components/PageHero';
import { Magnetic } from '../components/motion';
import InstallQr from '../components/InstallQr';
import { apkDownloadUrl } from '../lib/apk';

const FAQ = [
  {
    q: 'Is my data uploaded?',
    a: 'No. Household Expense stores finances in an encrypted local database. Backups you export are user-initiated.',
  },
  {
    q: 'How do I install from the QR code?',
    a: 'Scan with your phone camera (same Wi‑Fi as this computer). Chrome downloads HouseholdExpense.apk — allow Install unknown apps, then tap Open. Android always asks once; it cannot install with no confirmation.',
  },
  {
    q: 'How do I install the Android APK?',
    a: 'Tap Download APK and wait for the ~94 MB file. Uninstall the previous Household Expense install first, then allow Install unknown apps and open the APK.',
  },
  {
    q: 'What is Pro?',
    a: 'Six months of full access from registration. After that, Pro is ₹100 per month or ₹600 per year — ad-free, with import and export unlocked.',
  },
];

export default function DownloadPage() {
  return (
    <div className="pb-20">
      <PageHero
        index="06"
        eyebrow="Download"
        title="Install Household Expense."
        subtitle="Scan the QR with your phone, or download the APK. Enable install from this source if Android asks."
      />

      <div className="mx-auto grid max-w-6xl items-start gap-10 px-4 md:grid-cols-[auto_1fr]">
        <InstallQr size={220} />

        <div>
          <Magnetic className="inline-flex">
            <a
              href={apkDownloadUrl()}
              download="HouseholdExpense.apk"
              className="he-btn-mint inline-flex items-center gap-3 rounded-full bg-mint px-8 py-4 text-lg font-bold text-on-mint shadow-[0_0_50px_rgba(46,230,166,0.3)]"
            >
              <Download className="h-5 w-5" /> Download APK
            </a>
          </Magnetic>
          <p className="mt-4 font-mono text-[11px] tracking-[0.18em] text-muted">
            Package: com.householdexpense.app · v1.0.0 · ~94 MB · Android
          </p>

          <div className="mt-10 max-w-xl space-y-3">
            {FAQ.map((item) => (
              <details key={item.q} className="he-glass group p-5">
                <summary className="cursor-pointer list-none font-display text-lg font-semibold text-ink marker:content-none">
                  {item.q}
                </summary>
                <p className="mt-3 text-sm leading-relaxed text-muted">{item.a}</p>
              </details>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
