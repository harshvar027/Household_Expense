import { Link } from 'react-router-dom';
import { Check } from 'lucide-react';
import PageHero from '../components/PageHero';
import AdSlot from '../components/AdSlot';
import { Magnetic } from '../components/motion';

const PLANS = [
  {
    index: '01',
    name: 'Trial',
    price: '6 months',
    detail: 'Full features from registration. Ads may show. No cloud account required to start.',
    items: ['All features unlocked', 'On-device vault', 'No card to start'],
    featured: false,
  },
  {
    index: '02',
    name: 'Monthly',
    price: '₹100',
    suffix: ' / month',
    detail: 'After the trial, stay on Pro month to month. Cancel anytime.',
    items: ['Ad-free', 'Import & export unlocked', 'Restore purchases'],
    featured: false,
  },
  {
    index: '03',
    name: 'Yearly',
    price: '₹600',
    suffix: ' / year',
    detail: 'Best value — two months free versus paying monthly.',
    items: ['Ad-free', 'Import & export unlocked', 'Restore purchases'],
    featured: true,
  },
];

export default function PricingPage() {
  return (
    <div className="pb-20">
      <PageHero
        index="03"
        eyebrow="Pricing"
        title="Six months free. Then ₹100 a month — or ₹600 a year."
        subtitle="Full access from registration. After the trial, pick monthly or yearly Pro. Ads drop away on either paid plan."
      />

      <div className="mx-auto mb-8 max-w-6xl px-4">
        <AdSlot format="banner" />
      </div>

      <div className="mx-auto grid max-w-6xl gap-4 px-4 md:grid-cols-3">
        {PLANS.map((plan) => (
          <div
            key={plan.name}
            className={`he-glass p-8 md:p-9 ${
              plan.featured ? 'border-mint/35 shadow-[0_0_50px_rgba(46,230,166,0.12)]' : ''
            }`}
          >
            <p
              className={`font-mono text-[11px] tracking-[0.28em] ${
                plan.featured ? 'text-mint' : 'text-muted'
              }`}
            >
              {plan.index} / {plan.name}
            </p>
            <p className="mt-6 font-display text-5xl font-normal tracking-tight text-ink">
              {plan.price}
              {plan.suffix ? <span className="text-lg font-medium text-muted">{plan.suffix}</span> : null}
            </p>
            <p className="mt-4 text-sm leading-relaxed text-muted">{plan.detail}</p>
            <ul className="mt-6 space-y-3 text-sm text-muted">
              {plan.items.map((t) => (
                <li key={t} className="flex items-center gap-2">
                  <Check className="h-4 w-4 text-mint" /> {t}
                </li>
              ))}
            </ul>
          </div>
        ))}
      </div>

      <div className="mx-auto mt-12 max-w-6xl px-4">
        <Magnetic>
          <Link to="/download" className="he-btn-mint inline-flex rounded-full bg-mint px-6 py-3 font-semibold text-on-mint">
            Start with the APK
          </Link>
        </Magnetic>
      </div>
    </div>
  );
}
