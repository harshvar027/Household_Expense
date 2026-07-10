import 'package:flutter/material.dart';
import '../models/income.dart';
import '../theme/app_theme.dart';
import '../widgets/ui/app_scaffold.dart';
import '../widgets/ui/glass_surface.dart';
import '../widgets/money_amount.dart';
import '../utils/category_utils.dart';
import '../widgets/category_budget_card.dart';
import '../utils/money_format.dart';

/// Display data for the income & budget form (saved totals, not input values).
class BudgetFormSnapshot {
  final double manualIncome;
  final double monthlyBudget;
  final double broughtForwardIncome;
  final double importedIncome;
  final double monthlyIncome;
  final List<Income> manualEntries;
  final String? previousMonthLabel;

  const BudgetFormSnapshot({
    required this.manualIncome,
    required this.monthlyBudget,
    required this.broughtForwardIncome,
    required this.importedIncome,
    required this.monthlyIncome,
    required this.manualEntries,
    this.previousMonthLabel,
  });
}

class BudgetScreen extends StatefulWidget {
  final String monthLabel;
  final Map<String, double> categoryTotals;
  final Map<String, double> categoryBudgets;
  final List<String> categories;
  final Future<BudgetFormSnapshot> Function() loadSnapshot;
  final Future<String?> Function(double amount, String description) onSaveIncome;
  final Future<String?> Function(double amount) onSaveBudget;
  final Future<void> Function(String category, double amount) onSaveCategoryBudget;

  const BudgetScreen({
    super.key,
    required this.monthLabel,
    required this.categoryTotals,
    required this.categoryBudgets,
    required this.categories,
    required this.loadSnapshot,
    required this.onSaveIncome,
    required this.onSaveBudget,
    required this.onSaveCategoryBudget,
  });

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _incomeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();

  BudgetFormSnapshot? _snapshot;
  bool _loading = true;
  bool _savingIncome = false;
  bool _savingBudget = false;

  @override
  void initState() {
    super.initState();
    _refreshSnapshot();
  }

  @override
  void dispose() {
    _incomeController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _refreshSnapshot() async {
    setState(() => _loading = true);
    final data = await widget.loadSnapshot();
    if (!mounted) return;
    setState(() {
      _snapshot = data;
      _loading = false;
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _handleSaveIncome() async {
    final amount = parseMoney(_incomeController.text.trim());
    final description = _descriptionController.text.trim();

    if (description.isEmpty) {
      _showError('Description is required (e.g. Salary, Business, Bonus).');
      return;
    }
    if (amount == null || amount <= 0) {
      _showError('Enter an income amount greater than zero.');
      return;
    }

    setState(() => _savingIncome = true);
    final error = await widget.onSaveIncome(amount, description);
    if (!mounted) return;
    setState(() => _savingIncome = false);

    if (error != null) {
      _showError(error);
      return;
    }

    _incomeController.clear();
    _descriptionController.clear();
    await _refreshSnapshot();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Income saved successfully.')),
    );
  }

  Future<void> _handleSaveBudget() async {
    final amount = parseMoney(_budgetController.text.trim());
    if (amount == null || amount < 0) {
      _showError('Enter a valid budget amount.');
      return;
    }

    setState(() => _savingBudget = true);
    final error = await widget.onSaveBudget(amount);
    if (!mounted) return;
    setState(() => _savingBudget = false);

    if (error != null) {
      _showError(error);
      return;
    }

    _budgetController.clear();
    await _refreshSnapshot();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Budget saved successfully.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final snap = _snapshot;

    return AppScreenScaffold(
      title: 'Income & Budget',
      scrollBody: true,
      body: _loading && snap == null
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                children: [
                  _BudgetCard(
                    icon: Icons.account_balance_wallet_rounded,
                    iconColor: AppColors.income,
                    title: 'Monthly Income',
                    subtitle: widget.monthLabel,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _descriptionController,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'Description *',
                            hintText: 'Salary, Business, Bonus…',
                            helperText: 'Required — explains this income entry',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _incomeController,
                          keyboardType: kMoneyKeyboard,
                          inputFormatters: kMoneyInputFormatters,
                          decoration: InputDecoration(
                            labelText: 'Income amount',
                            prefixText: moneyInputPrefix(),
                            helperText: 'Enter a new amount each time you save',
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton.icon(
                            onPressed: _savingIncome ? null : _handleSaveIncome,
                            icon: _savingIncome
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save_rounded),
                            label: const Text('Save Income'),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _SavedTotalRow(
                          label: 'Saved manual income',
                          amount: snap?.manualIncome ?? 0,
                          flow: MoneyFlow.credit,
                        ),
                        if (snap != null && snap.manualEntries.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ...snap.manualEntries.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      entry.source,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  MoneyAmount(
                                    amount: entry.amount,
                                    flow: MoneyFlow.credit,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        if (snap != null &&
                            (snap.broughtForwardIncome > 0 ||
                                snap.importedIncome > 0)) ...[
                          const Divider(height: 24),
                          if (snap.broughtForwardIncome > 0)
                            _RowStat(
                              'Brought forward from ${snap.previousMonthLabel ?? ''}',
                              snap.broughtForwardIncome,
                              MoneyFlow.credit,
                            ),
                          if (snap.importedIncome > 0)
                            _RowStat(
                              'Imported from bank',
                              snap.importedIncome,
                              MoneyFlow.credit,
                            ),
                          const Divider(height: 16),
                          _RowStat(
                            'Total income',
                            snap.monthlyIncome,
                            MoneyFlow.credit,
                            bold: true,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _BudgetCard(
                    icon: Icons.speed_rounded,
                    iconColor: AppColors.warning,
                    title: 'Monthly Budget',
                    subtitle: 'Spending limit for ${widget.monthLabel}',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _budgetController,
                          keyboardType: kMoneyKeyboard,
                          inputFormatters: kMoneyInputFormatters,
                          decoration: InputDecoration(
                            labelText: 'Budget amount',
                            prefixText: moneyInputPrefix(),
                            helperText: 'Enter amount and save to set the limit',
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton.icon(
                            onPressed: _savingBudget ? null : _handleSaveBudget,
                            icon: _savingBudget
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save_rounded),
                            label: const Text('Save Budget'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.warning,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _SavedTotalRow(
                          label: 'Total budget',
                          amount: snap?.monthlyBudget ?? 0,
                          flow: MoneyFlow.debit,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  CategoryBudgetCard(
                    monthLabel: widget.monthLabel,
                    categoryTotals: widget.categoryTotals,
                    categoryBudgets: widget.categoryBudgets,
                    categories: widget.categories
                        .where((c) => !CategoryUtils.isSavingsCategory(c))
                        .toList(),
                    onSaveBudget: widget.onSaveCategoryBudget,
                  ),
                ],
              ),
            ),
    );
  }
}

class _SavedTotalRow extends StatelessWidget {
  final String label;
  final double amount;
  final MoneyFlow flow;

  const _SavedTotalRow({
    required this.label,
    required this.amount,
    required this.flow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          MoneyAmount(
            amount: amount,
            flow: flow,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget child;

  const _BudgetCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GlassSurface.card(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _RowStat extends StatelessWidget {
  final String label;
  final double amount;
  final MoneyFlow flow;
  final bool bold;

  const _RowStat(this.label, this.amount, this.flow, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          MoneyAmount(
            amount: amount,
            flow: flow,
            fontSize: bold ? 16 : 14,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
          ),
        ],
      ),
    );
  }
}
