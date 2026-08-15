import { Link } from 'react-router-dom';
import PageHero from '../components/PageHero';
import { Magnetic } from '../components/motion';

export default function AboutPage() {
  return (
    <div className="pb-20">
      <PageHero
        index="04"
        eyebrow="About"
        title="Built for households that want control."
        subtitle="A Flutter vault for family spending — neo-glass UI, encrypted locally, with six months free then Pro."
      />

      <div className="mx-auto max-w-6xl space-y-6 px-4 text-muted leading-relaxed md:max-w-3xl md:text-lg">
        <p>
          Household Expense is an Android (and iOS-capable) Flutter app for tracking family
          spending entirely on the device. It pairs a neo-glass UI with SQLCipher encryption,
          bank statement import, budgets, goals, recurring bills, and a six-month trial then
          ₹100 / month or ₹600 / year.
        </p>
        <p>
          This site is the product showcase: privacy story, feature set, pricing, and a direct
          APK download — with light and dark themes so the brand reads well day or night.
        </p>
        <p>
          Differentiator vs sync-first money apps: your ledger stays local. Ads and Pro fund the
          free tier without requiring a cloud account to use the core product.
        </p>
      </div>
      <div className="mx-auto mt-12 flex max-w-6xl flex-wrap gap-3 px-4 md:max-w-3xl">
        <Link to="/product" className="inline-flex rounded-full border border-line bg-surface px-5 py-3 text-ink">
          Product
        </Link>
        <Magnetic>
          <Link to="/download" className="he-btn-mint inline-flex rounded-full bg-mint px-5 py-3 font-semibold text-on-mint">
            Download
          </Link>
        </Magnetic>
      </div>
    </div>
  );
}
