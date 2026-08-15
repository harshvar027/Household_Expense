export default function Logo({
  size = 40,
  withWordmark = false,
  className = '',
}: {
  size?: number;
  withWordmark?: boolean;
  className?: string;
}) {
  return (
    <span className={`inline-flex items-center gap-2.5 ${className}`.trim()}>
      <img
        src="/branding/app_logo.png"
        alt="Household Expense"
        width={size}
        height={size}
        className="he-logo shrink-0 object-contain"
        style={{ width: size, height: size }}
      />
      {withWordmark ? (
        <span className="hidden font-display text-[15px] font-normal tracking-tight text-ink sm:inline">
          Household Expense
        </span>
      ) : null}
    </span>
  );
}
