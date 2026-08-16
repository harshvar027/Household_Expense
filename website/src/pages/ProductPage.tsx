import { Link } from 'react-router-dom';
import { Fingerprint, Lock, Newspaper, PieChart, Target, Upload, Users } from 'lucide-react';
import PageHero from '../components/PageHero';
import { Magnetic } from '../components/motion';

const FEATURES = [
  {
    icon: Lock,
    title: 'Encrypted on-device ledger',
    body: 'SQLCipher vault. Your household money never needs a cloud account to work.',
  },
  {
    icon: Upload,
    title: 'Bank statement import',
    body: 'CSV, Excel, and PDF statements with India-first bank profiles and duplicate checks.',
  },
  {
    icon: PieChart,
    title: 'Budgets that stay honest',
    body: 'Monthly envelopes, category caps, and insights that read your real ledger.',
  },
  {
    icon: Target,
    title: 'Goals & recurring bills',
    body: 'Savings targets, missing-bill banners, and household members in one place.',
  },
  {
    icon: Users,
    title: 'Built for the household',
    body: 'Members, accounts, and shared visibility — without shipping data to a third party.',
  },
  {
    icon: Newspaper,
    title: 'Economic news wire',
    body: 'Finnhub headlines for rates, inflation, oil, and gold — formatted so a household can see what just moved.',
  },
  {
    icon: Fingerprint,
    title: 'PIN + biometrics',
    body: 'Lock the app the moment it backgrounds. Six-month trial, then ₹100 / month or ₹600 / year.',
  },
];

export default function ProductPage() {
  return (
    <div className="pb-20">
      <PageHero
        index="01"
        eyebrow="Product"
        title="Everything a household needs. Nothing it must sync."
        subtitle="Capture spending five ways, plan budgets and goals, and keep Pro monetization honest — while the vault stays on-device."
      />

      <div className="mx-auto grid max-w-6xl gap-4 px-4 sm:grid-cols-2 lg:grid-cols-3">
        {FEATURES.map((f, i) => (
          <article key={f.title} className="he-glass he-tilt p-6 md:p-7">
            <div className="mb-5 flex items-center justify-between">
              <div className="inline-flex h-11 w-11 items-center justify-center rounded-full border border-mint/25 bg-mint/10 text-mint">
                <f.icon className="h-5 w-5" />
              </div>
              <span className="font-mono text-[10px] tracking-[0.28em] text-muted">0{i + 1}</span>
            </div>
            <h2 className="font-display text-lg font-semibold text-ink">{f.title}</h2>
            <p className="mt-2 text-sm leading-relaxed text-muted">{f.body}</p>
          </article>
        ))}
      </div>

      <div className="mx-auto mt-12 flex max-w-6xl flex-wrap gap-3 px-4">
        <Magnetic>
          <Link to="/download" className="he-btn-mint inline-flex rounded-full bg-mint px-6 py-3 font-semibold text-on-mint">
            Download app
          </Link>
        </Magnetic>
        <Link to="/privacy" className="inline-flex rounded-full border border-line bg-surface px-6 py-3 font-medium text-ink">
          Privacy story
        </Link>
      </div>
    </div>
  );
}
