import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/expense.dart';
import '../../models/income.dart';
import '../../utils/account_label.dart';
import '../../theme/app_theme.dart';
import '../../theme/neo_palette.dart';
import '../../widgets/ui/neo_glass.dart';
import '../../utils/money_format.dart';
import '../../widgets/money_amount.dart';
import '../../utils/category_utils.dart';
import '../../widgets/expense_filter_bar.dart';
import '../../widgets/ui/empty_state_view.dart';
import '../../widgets/ui/finance_illustration.dart';
import '../../widgets/ui/stagger_animate.dart';

class ExpensesTab extends StatefulWidget {
  final String monthLabel;
  final List<Expense> expenses;
  final List<Expense> investments;
  final List<Income> incomes;
  final double investmentTotal;
  final List<String> categories;
  final List<String> paymentMethods;
  final ExpenseFilterState filter;
  final ValueChanged<ExpenseFilterState> onFilterChanged;
  final String Function(String) formatDate;
  final void Function(Expense) onEditExpense;
  final void Function(int) onDeleteExpense;
  final void Function(Income) onEditIncome;
  final void Function(int) onDeleteIncome;
  final bool Function(Income) isSystemIncome;
  final Map<int, String> accountNames;
  final Map<int, String> accountBankLabels;
  final double bottomScrollPadding;

  const ExpensesTab({
    super.key,
    required this.monthLabel,
    required this.expenses,
    required this.investments,
    required this.incomes,
    required this.investmentTotal,
    required this.categories,
    required this.paymentMethods,
    required this.filter,
    required this.onFilterChanged,
    required this.formatDate,
    required this.onEditExpense,
    required this.onDeleteExpense,
    required this.onEditIncome,
    required this.onDeleteIncome,
    required this.isSystemIncome,
    required this.accountNames,
    required this.accountBankLabels,
    this.bottomScrollPadding = 160,
  });

  @override
  State<ExpensesTab> createState() => _ExpensesTabState();
}

class _ExpensesTabState extends State<ExpensesTab> {
  TransactionHistoryType _historyType = TransactionHistoryType.expenses;

  void _onHistoryTypeChanged(TransactionHistoryType type) {
    if (_historyType == type) return;
    setState(() => _historyType = type);
    widget.onFilterChanged(ExpenseFilterState());
  }

  String? _accountLabelForExpense(Expense expense) {
    return accountNameFromNote(expense.notes) ??
        (expense.accountId != null
            ? widget.accountNames[expense.accountId!]
            : null);
  }

  String? _bankLabelForExpense(Expense expense) {
    return bankNameFromNote(expense.notes) ??
        (expense.accountId != null
            ? widget.accountBankLabels[expense.accountId!]
            : null);
  }

  String? _bankLabelForIncome(Income income) {
    return income.accountId != null
        ? widget.accountBankLabels[income.accountId!]
        : null;
  }

  String? _accountLabelForIncome(Income income) {
    return income.accountId != null
        ? widget.accountNames[income.accountId!]
        : null;
  }

  List<String> get _filterCategories {
    switch (_historyType) {
      case TransactionHistoryType.expenses:
        return widget.categories
            .where((c) => !CategoryUtils.isSavingsCategory(c))
            .toList();
      case TransactionHistoryType.savingsInvestments:
        return widget.categories
            .where(CategoryUtils.isSavingsCategory)
            .toList();
      case TransactionHistoryType.income:
        return widget.incomes
            .map((i) => i.category)
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    }
  }

  String get _subtitle {
    switch (_historyType) {
      case TransactionHistoryType.expenses:
        return '${widget.expenses.length} expenses for ${widget.monthLabel}';
      case TransactionHistoryType.income:
        return '${widget.incomes.length} income entries for ${widget.monthLabel}';
      case TransactionHistoryType.savingsInvestments:
        return '${widget.investments.length} records · ${formatMoneyWithCurrency(widget.investmentTotal)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Transactions',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.8,
                            ),
                          ).staggerIn(index: 0),
                          const SizedBox(height: 4),
                          Text(
                            _subtitle,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ).staggerIn(index: 1),
                        ],
                      ),
                    ),
                    const FinanceIllustration(
                      type: FinanceIllustrationType.empty,
                      size: 64,
                    ).staggerIn(index: 1),
                  ],
                ),
                const SizedBox(height: 16),
                _HistoryTypeSelector(
                  selected: _historyType,
                  onChanged: _onHistoryTypeChanged,
                ).staggerIn(index: 2),
                const SizedBox(height: 16),
                ExpenseFilterBar(
                  filter: widget.filter,
                  historyType: _historyType,
                  categories: _filterCategories,
                  paymentMethods: widget.paymentMethods,
                  onChanged: widget.onFilterChanged,
                ).staggerIn(index: 3),
              ],
            ),
          ),
        ),
        ..._buildHistorySlivers(),
      ],
    );
  }

  List<Widget> _buildHistorySlivers() {
    switch (_historyType) {
      case TransactionHistoryType.expenses:
        return _buildExpenseSlivers();
      case TransactionHistoryType.income:
        return _buildIncomeSlivers();
      case TransactionHistoryType.savingsInvestments:
        return _buildInvestmentSlivers();
    }
  }

  List<Widget> _buildExpenseSlivers() {
    if (widget.expenses.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyStateView(
            illustration: FinanceIllustrationType.empty,
            title: 'No expenses yet',
            message:
                'Start tracking your household spending.\nTap + to add your first expense.',
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, widget.bottomScrollPadding),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _ExpenseTile(
              expense: widget.expenses[index],
              formatDate: widget.formatDate,
              accountName: _accountLabelForExpense(widget.expenses[index]),
              bankName: _bankLabelForExpense(widget.expenses[index]),
              onEdit: () => widget.onEditExpense(widget.expenses[index]),
              onDelete: () => widget.onDeleteExpense(widget.expenses[index].id!),
            )
                .animate(delay: (index * 40).ms)
                .fadeIn(duration: 350.ms)
                .slideX(begin: 0.04, end: 0, curve: Curves.easeOutCubic),
            childCount: widget.expenses.length,
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildInvestmentSlivers() {
    if (widget.investments.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyStateView(
            illustration: FinanceIllustrationType.empty,
            title: 'No investments yet',
            message: 'No savings or investment entries for ${widget.monthLabel}.',
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, widget.bottomScrollPadding),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _ExpenseTile(
              expense: widget.investments[index],
              formatDate: widget.formatDate,
              isInvestment: true,
              accountName: _accountLabelForExpense(widget.investments[index]),
              bankName: _bankLabelForExpense(widget.investments[index]),
              onEdit: () => widget.onEditExpense(widget.investments[index]),
              onDelete: () =>
                  widget.onDeleteExpense(widget.investments[index].id!),
            )
                .animate(delay: (index * 40).ms)
                .fadeIn(duration: 350.ms)
                .slideX(begin: 0.04, end: 0, curve: Curves.easeOutCubic),
            childCount: widget.investments.length,
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildIncomeSlivers() {
    if (widget.incomes.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyStateView(
            illustration: FinanceIllustrationType.empty,
            title: 'No income yet',
            message: 'No income entries for ${widget.monthLabel}.',
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, widget.bottomScrollPadding),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final income = widget.incomes[index];
              final system = widget.isSystemIncome(income);
              return _IncomeTile(
                income: income,
                formatDate: widget.formatDate,
                isSystem: system,
                accountName: system ? null : _accountLabelForIncome(income),
                bankName: system ? null : _bankLabelForIncome(income),
                onEdit: system ? null : () => widget.onEditIncome(income),
                onDelete: system ? null : () => widget.onDeleteIncome(income.id!),
              )
                  .animate(delay: (index * 40).ms)
                  .fadeIn(duration: 350.ms)
                  .slideX(begin: 0.04, end: 0, curve: Curves.easeOutCubic);
            },
            childCount: widget.incomes.length,
          ),
        ),
      ),
    ];
  }
}

class _HistoryTypeSelector extends StatelessWidget {
  final TransactionHistoryType selected;
  final ValueChanged<TransactionHistoryType> onChanged;

  const _HistoryTypeSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cyberMint.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _HistoryTab(
            label: 'Expenses',
            icon: Icons.shopping_bag_rounded,
            color: AppColors.expense,
            isSelected: selected == TransactionHistoryType.expenses,
            onTap: () => onChanged(TransactionHistoryType.expenses),
          ),
          _HistoryTab(
            label: 'Income',
            icon: Icons.account_balance_rounded,
            color: AppColors.income,
            isSelected: selected == TransactionHistoryType.income,
            onTap: () => onChanged(TransactionHistoryType.income),
          ),
          _HistoryTab(
            label: 'Savings',
            icon: Icons.trending_up_rounded,
            color: AppColors.savings,
            isSelected: selected == TransactionHistoryType.savingsInvestments,
            onTap: () => onChanged(TransactionHistoryType.savingsInvestments),
          ),
        ],
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _HistoryTab({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.14) : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? color.withValues(alpha: 0.45)
                  : AppColors.cyberMint.withValues(alpha: 0.08),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.18)
                      : color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isSelected ? color : color.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? color : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final Expense expense;
  final String Function(String) formatDate;
  final String? accountName;
  final String? bankName;
  final bool isInvestment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExpenseTile({
    required this.expense,
    required this.formatDate,
    this.accountName,
    this.bankName,
    this.isInvestment = false,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final flow = isInvestment ? MoneyFlow.credit : MoneyFlow.debit;
    final accent = isInvestment ? AppColors.savings : AppColors.expense;

    return _TxnCard(
      accent: accent,
      icon: isInvestment
          ? Icons.trending_up_rounded
          : Icons.shopping_bag_rounded,
      title: expense.item,
      category: expense.category,
      dateLabel: formatDate(expense.expenseDate),
      meta: buildPaymentMeta(
        paymentMethod: expense.paymentMethod,
        accountName: accountName,
        bankName: bankName,
      ),
      amount: expense.amount,
      flow: flow,
      onEdit: onEdit,
      onDelete: onDelete,
    );
  }
}

class _IncomeTile extends StatelessWidget {
  final Income income;
  final String Function(String) formatDate;
  final bool isSystem;
  final String? accountName;
  final String? bankName;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _IncomeTile({
    required this.income,
    required this.formatDate,
    required this.isSystem,
    this.accountName,
    this.bankName,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return _TxnCard(
      accent: AppColors.income,
      icon: isSystem
          ? Icons.forward_rounded
          : Icons.account_balance_rounded,
      title: income.source,
      category: income.category,
      dateLabel: formatDate(income.incomeDate),
      meta: isSystem
          ? 'Brought forward'
          : buildPaymentMeta(
              paymentMethod: income.paymentMethod,
              accountName: accountName,
              bankName: bankName,
            ),
      amount: income.amount,
      flow: MoneyFlow.credit,
      softHighlight: isSystem,
      onEdit: isSystem ? null : onEdit,
      onDelete: isSystem ? null : onDelete,
    );
  }
}

/// Shared layout: description / category / date on separate readable lines.
class _TxnCard extends StatelessWidget {
  final Color accent;
  final IconData icon;
  final String title;
  final String category;
  final String dateLabel;
  final String? meta;
  final double amount;
  final MoneyFlow flow;
  final bool softHighlight;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _TxnCard({
    required this.accent,
    required this.icon,
    required this.title,
    required this.category,
    required this.dateLabel,
    required this.amount,
    required this.flow,
    this.meta,
    this.softHighlight = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return NeoGlass.card(
      glowColor: accent,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
      borderRadius: 20,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accent.withValues(alpha: 0.28),
                  accent.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.25),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(icon, color: accent, size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15.5,
                    color: AppColors.textPrimary,
                    height: 1.25,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                _MetaRow(
                  icon: Icons.label_rounded,
                  label: category.isEmpty ? 'Uncategorized' : category,
                  accent: accent,
                ),
                const SizedBox(height: 5),
                _MetaRow(
                  icon: Icons.calendar_today_rounded,
                  label: dateLabel,
                  accent: AppColors.cyberMint,
                ),
                if (meta != null && meta!.trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  _MetaRow(
                    icon: Icons.payments_outlined,
                    label: meta!,
                    accent: AppColors.textSecondary,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              MoneyAmount(
                amount: amount,
                flow: flow,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
              if (onEdit != null || onDelete != null)
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    size: 20,
                    color: AppColors.textSecondary.withValues(alpha: 0.9),
                  ),
                  color: NeoPalette.slateCard,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32),
                  onSelected: (v) {
                    if (v == 'edit') onEdit?.call();
                    if (v == 'delete') onDelete?.call();
                  },
                  itemBuilder: (_) => [
                    if (onEdit != null)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                    if (onDelete != null)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;

  const _MetaRow({
    required this.icon,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: accent.withValues(alpha: 0.9)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color.lerp(AppColors.textPrimary, accent, 0.22),
              height: 1.3,
            ),
            softWrap: true,
          ),
        ),
      ],
    );
  }
}
