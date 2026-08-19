import { Link } from 'react-router-dom';
import { ShieldCheck, Smartphone, Wallet } from 'lucide-react';
import PageHero from '../components/PageHero';
import AdSlot from '../components/AdSlot';

export default function PrivacyPage() {
  return (
    <div className="pb-20">
      <PageHero
        index="02"
        eyebrow="Privacy"
        title="Beat cloud-first apps at their weakest point."
        subtitle="Sync is optional for others. For Household Expense, encrypted local storage is the product."
      />

      <div className="mx-auto grid max-w-6xl items-center gap-10 px-4 md:grid-cols-2">
        <div>
          <ul className="space-y-4 text-sm text-ink">
            {[
              'SQLCipher database + secure key storage',
              'Background lock with PIN / biometrics',
              'User-initiated encrypted backups only',
              'No cloud account required to track spending',
              'This marketing site may show Google ads — the household ledger still never leaves the phone',
            ].map((t) => (
              <li key={t} className="flex items-start gap-3 border-b border-line pb-4">
                <ShieldCheck className="mt-0.5 h-5 w-5 shrink-0 text-mint" />
                <span>{t}</span>
              </li>
            ))}
          </ul>
          <div className="mt-8">
            <AdSlot format="inline" />
          </div>
          <Link to="/download" className="he-link-line mt-8 inline-flex text-sm font-semibold text-mint">
            Get the private app →
          </Link>
        </div>
        <div className="he-glass animate-floaty relative overflow-hidden p-8">
          <Smartphone className="absolute -right-4 -top-4 h-40 w-40 text-mint/10" />
          <Wallet className="mb-4 h-10 w-10 text-mint" />
          <p className="font-display text-2xl font-bold text-ink">Neo-glass shell</p>
          <p className="mt-2 text-muted">
            Home · Transactions · Budgets · Goals · Menu — with a multi-path add hub for
            manual, split, SMS, receipt attach, and bank statements.
          </p>
          <div className="mt-6 grid grid-cols-2 gap-3 text-xs text-muted">
            {['Family persona', 'Pro trial', 'AdMob free tier', 'India banks'].map((chip) => (
              <div key={chip} className="rounded-full border border-line bg-page/60 px-3 py-2">
                {chip}
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
