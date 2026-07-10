import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/money_amount.dart';
import '../models/bank_transaction.dart';
import '../models/bank_profile.dart';
import '../models/account.dart';
import '../services/category_detector.dart';
import '../services/import_service.dart';
import '../services/merchant_rule_service.dart';
import '../database/database_helper.dart';
import '../theme/app_theme.dart';
import '../utils/category_utils.dart';
import '../widgets/ui/app_scaffold.dart';
import '../widgets/ui/glass_surface.dart';
import '../widgets/ui/stagger_animate.dart';

class ImportPreviewScreen extends StatefulWidget {
  final List<BankTransaction> transactions;
  final int? accountId;
  final String? accountName;
  final BankId? bankId;
  final String? bankLabel;

  const ImportPreviewScreen({
    super.key,
    required this.transactions,
    this.accountId,
    this.accountName,
    this.bankId,
    this.bankLabel,
  });

  @override
  State<ImportPreviewScreen> createState() => _ImportPreviewScreenState();
}

class _ImportPreviewScreenState extends State<ImportPreviewScreen> {
  List<String> categories = [];
  bool isLoading = true;
  bool isImporting = false;
  bool hideDuplicates = false;
  bool debitCreditReversed = false;
  bool reversingSemantics = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final loaded = await DatabaseHelper.instance.getCategories();
    if (!mounted) return;
    setState(() {
      categories = loaded;
      isLoading = false;
    });
  }

  int get duplicateCount =>
      widget.transactions.where((t) => t.duplicate).length;

  int get newCount =>
      widget.transactions.where((t) => !t.duplicate).length;

  int get selectedCount =>
      widget.transactions.where((t) => t.selected && !t.duplicate).length;

  double get totalSelectedDebit => widget.transactions
      .where((t) => t.selected && !t.duplicate && t.isDebit)
      .fold(0.0, (s, t) => s + t.amount);

  double get totalSelectedCredit => widget.transactions
      .where((t) => t.selected && !t.duplicate && !t.isDebit)
      .fold(0.0, (s, t) => s + t.amount);

  int get selectedInvestmentCount => widget.transactions
      .where(
        (t) =>
            t.selected &&
            !t.duplicate &&
            t.isDebit &&
            CategoryUtils.isSavingsCategory(t.category),
      )
      .length;

  double get totalSelectedInvestments => widget.transactions
      .where(
        (t) =>
            t.selected &&
            !t.duplicate &&
            t.isDebit &&
            CategoryUtils.isSavingsCategory(t.category),
      )
      .fold(0.0, (s, t) => s + t.amount);

  List<BankTransaction> get visibleTransactions {
    if (hideDuplicates) {
      return widget.transactions.where((t) => !t.duplicate).toList();
    }
    return widget.transactions;
  }

  void selectAllNew() {
    setState(() {
      for (final t in widget.transactions) {
        if (!t.duplicate) t.selected = true;
      }
    });
  }

  void deselectAll() {
    setState(() {
      for (final t in widget.transactions) {
        t.selected = false;
      }
    });
  }

  void applyCategoryToSimilar(BankTransaction source) {
    final pattern = MerchantRuleService.instance.extractPattern(
      source.description,
    );
    if (pattern.length < 3) return;

    setState(() {
      for (final t in widget.transactions) {
        if (t.duplicate || !t.isDebit) continue;
        final text = t.description.toLowerCase();
        if (text.contains(pattern)) {
          t.category = source.category;
          t.selected = true;
        }
      }
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Applied "${source.category}" to similar "$pattern" transactions',
        ),
      ),
    );
  }

  Future<void> _createCategoryForTransaction(BankTransaction t) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Create category'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Category name',
              hintText: 'e.g. School fees, Pet care',
            ),
            onSubmitted: (value) => Navigator.pop(ctx, value.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (name == null || name.isEmpty || !mounted) return;

    await DatabaseHelper.instance.insertCategory(name);
    await _loadCategories();
    if (!mounted) return;

    final old = t.category;
    await _onCategoryChanged(t, old, name);
  }

  Future<void> _onCategoryChanged(
    BankTransaction t,
    String? oldCategory,
    String newCategory,
  ) async {
    setState(() => t.category = newCategory);
    if (oldCategory != null && oldCategory != newCategory) {
      await MerchantRuleService.instance.learnFromCategoryChange(
        t.description,
        newCategory,
      );
    }
  }

  Future<void> _toggleDebitCreditSemantics() async {
    if (reversingSemantics) return;

    setState(() => reversingSemantics = true);
    try {
      for (final t in widget.transactions) {
        t.isDebit = !t.isDebit;
        if (t.isDebit) {
          t.category = await CategoryDetector.detectExpense(t, categories);
        }
      }

      if (!mounted) return;
      setState(() {
        debitCreditReversed = !debitCreditReversed;
      });
    } finally {
      if (mounted) setState(() => reversingSemantics = false);
    }
  }

  Future<void> _confirmImport() async {
    setState(() => isImporting = true);

    if (widget.accountId != null || widget.accountName != null) {
      for (final t in widget.transactions) {
        t.accountId ??= widget.accountId;
        t.accountName ??= widget.accountName;
      }
    }

    final count = await ImportService().importTransactions(
      widget.transactions,
      bankId: widget.bankId,
    );

    if (widget.accountId != null && widget.bankId != null) {
      final accounts = await DatabaseHelper.instance.getAccounts();
      Account? matched;
      for (final account in accounts) {
        if (account.id == widget.accountId) {
          matched = account;
          break;
        }
      }
      if (matched != null) {
        await DatabaseHelper.instance.updateAccount(
          matched.copyWith(bankId: widget.bankId!.name),
        );
      }
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Imported $count transaction${count == 1 ? '' : 's'}. '
          '$duplicateCount duplicate${duplicateCount == 1 ? '' : 's'} skipped.',
        ),
      ),
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const AppScreenScaffold(
        title: 'Review Import',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return AppScreenScaffold(
      title: 'Review Import',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$selectedCount selected',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ],
      body: Column(
        children: [
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                _buildSummaryCard().staggerIn(index: 0),
                const SizedBox(height: 12),
                _buildDebitCreditCard().staggerIn(index: 1),
                const SizedBox(height: 12),
                _buildBulkActions().staggerIn(index: 2),
                const SizedBox(height: 16),
                if (selectedCount > 0) ...[
                  _buildSelectionTotals(),
                  const SizedBox(height: 12),
                ],
                ...visibleTransactions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final t = entry.value;
                  return _TransactionCard(
                    transaction: t,
                    realIndex: widget.transactions.indexOf(t),
                    categories: categories,
                    onSelected: (v) => setState(() => t.selected = v),
                    onCategoryChanged: (old, neu) =>
                        _onCategoryChanged(t, old, neu),
                    onCreateCategory: () => _createCategoryForTransaction(t),
                    onApplySimilar: () => applyCategoryToSimilar(t),
                  )
                      .animate(delay: (index * 35).ms)
                      .fadeIn(duration: 350.ms)
                      .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic);
                }),
                const SizedBox(height: 88),
              ],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return GlassSurface.card(
      padding: const EdgeInsets.all(18),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Import summary',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          if (widget.accountName != null &&
              widget.accountName!.trim().isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 16,
                  color: AppColors.primary.withValues(alpha: 0.85),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Account: ${widget.accountName} (indicative)',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (widget.bankLabel != null &&
              widget.bankLabel!.trim().isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  Icons.account_balance_outlined,
                  size: 16,
                  color: AppColors.savings.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Bank format: ${widget.bankLabel}',
                    style: TextStyle(
                      color: AppColors.savings.withValues(alpha: 0.95),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Text(
            duplicateCount > 0
                ? 'Duplicates are safe — they won\'t be added again.'
                : 'Review categories before importing.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatPill(
                label: 'New',
                value: '$newCount',
                color: AppColors.income,
                icon: Icons.fiber_new_rounded,
              ),
              StatPill(
                label: 'Duplicates',
                value: '$duplicateCount',
                color: AppColors.warning,
                icon: Icons.content_copy_rounded,
              ),
              StatPill(
                label: 'Total rows',
                value: '${widget.transactions.length}',
                color: AppColors.primary,
                icon: Icons.table_rows_rounded,
              ),
              if (selectedInvestmentCount > 0)
                StatPill(
                  label: 'Investments',
                  value: '$selectedInvestmentCount',
                  color: AppColors.savings,
                  icon: Icons.trending_up_rounded,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionTotals() {
    return GlassSurface.card(
      padding: const EdgeInsets.all(14),
      borderRadius: 18,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selected expenses',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    MoneyAmount(
                      amount: totalSelectedDebit - totalSelectedInvestments,
                      flow: MoneyFlow.debit,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: AppColors.accent.withValues(alpha: 0.12),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selected income',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      MoneyAmount(
                        amount: totalSelectedCredit,
                        flow: MoneyFlow.credit,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (selectedInvestmentCount > 0) ...[
            const SizedBox(height: 12),
            Divider(color: AppColors.accent.withValues(alpha: 0.12), height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.trending_up_rounded, size: 18, color: AppColors.savings),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Savings & investments',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
                MoneyAmount(
                  amount: totalSelectedInvestments,
                  flow: MoneyFlow.debit,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDebitCreditCard() {
    return GlassSurface.card(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.swap_horiz_rounded, color: AppColors.primary, size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Debit & credit check',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            debitCreditReversed
                ? 'Mapping reversed — debits and credits are swapped from the auto-detected layout.'
                : 'Review a few rows below. If expenses show as income (or vice versa), tap Reverse.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: reversingSemantics ? null : _toggleDebitCreditSemantics,
            icon: reversingSemantics
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    debitCreditReversed
                        ? Icons.undo_rounded
                        : Icons.swap_horiz_rounded,
                  ),
            label: Text(
              debitCreditReversed
                  ? 'Undo reverse'
                  : 'Reverse debit & credit',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.35)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkActions() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ChipButton(
          icon: Icons.select_all_rounded,
          label: 'Select all new',
          onTap: selectAllNew,
        ),
        _ChipButton(
          icon: Icons.deselect_rounded,
          label: 'Clear',
          onTap: deselectAll,
        ),
        FilterChip(
          label: Text(
            hideDuplicates ? 'New only' : 'Hide duplicates',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: hideDuplicates
                  ? AppColors.primaryLight
                  : AppColors.textPrimary,
            ),
          ),
          selected: hideDuplicates,
          backgroundColor: AppColors.surfaceElevated,
          selectedColor: AppColors.primary.withValues(alpha: 0.22),
          side: BorderSide(color: AppColors.accent.withValues(alpha: 0.18)),
          checkmarkColor: AppColors.primaryLight,
          onSelected: (v) => setState(() => hideDuplicates = v),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return GlassSurface.chrome(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      borderRadius: 0,
      child: SafeArea(
        top: false,
        child: PrimaryActionButton(
          onPressed: selectedCount == 0 ? null : _confirmImport,
          loading: isImporting,
          icon: Icons.check_circle_rounded,
          label: isImporting
              ? 'Importing…'
              : 'Import $selectedCount transaction${selectedCount == 1 ? '' : 's'}',
        ),
      ),
    );
  }
}

class _ChipButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ChipButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      elevation: 0,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  static const _createCategoryValue = '__create_category__';

  final BankTransaction transaction;
  final int realIndex;
  final List<String> categories;
  final ValueChanged<bool> onSelected;
  final Future<void> Function(String?, String) onCategoryChanged;
  final VoidCallback onCreateCategory;
  final VoidCallback onApplySimilar;

  const _TransactionCard({
    required this.transaction,
    required this.realIndex,
    required this.categories,
    required this.onSelected,
    required this.onCategoryChanged,
    required this.onCreateCategory,
    required this.onApplySimilar,
  });

  String get _dateLabel {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final d = transaction.date;
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final isDup = t.duplicate;
    final accent = t.isDebit ? AppColors.expense : AppColors.income;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: isDup
              ? AppColors.warning.withValues(alpha: 0.08)
              : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDup
                ? AppColors.warning.withValues(alpha: 0.45)
                : accent.withValues(alpha: 0.28),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: isDup ? 0.06 : 0.14),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDup
                        ? [
                            AppColors.warning,
                            AppColors.warning.withValues(alpha: 0.5),
                          ]
                        : [
                            accent,
                            Color.lerp(accent, Colors.white, 0.35)!,
                          ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Transform.translate(
                          offset: const Offset(-4, -2),
                          child: Checkbox(
                            value: t.selected,
                            activeColor: AppColors.primary,
                            onChanged:
                                isDup ? null : (v) => onSelected(v ?? false),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.description,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15.5,
                                  color: isDup
                                      ? AppColors.textSecondary
                                      : AppColors.textPrimary,
                                  height: 1.25,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _Badge(
                                    label: _dateLabel,
                                    color: AppColors.primary,
                                    icon: Icons.calendar_month_rounded,
                                    emphasized: true,
                                  ),
                                  _Badge(
                                    label: t.isDebit ? 'Expense' : 'Income',
                                    color: accent,
                                    icon: t.isDebit
                                        ? Icons.arrow_upward_rounded
                                        : Icons.arrow_downward_rounded,
                                  ),
                                  if (t.isDebit &&
                                      CategoryUtils.isSavingsCategory(
                                        t.category,
                                      ))
                                    const _Badge(
                                      label: 'Investment',
                                      color: AppColors.savings,
                                      icon: Icons.trending_up_rounded,
                                    ),
                                  if (t.accountName != null &&
                                      t.accountName!.trim().isNotEmpty)
                                    _Badge(
                                      label: t.accountName!,
                                      color: AppColors.savings,
                                      icon: Icons.account_balance_wallet_outlined,
                                    ),
                                  if (isDup)
                                    const _Badge(
                                      label: 'Duplicate',
                                      color: AppColors.warning,
                                      icon: Icons.block_rounded,
                                      emphasized: true,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.28),
                            ),
                          ),
                          child: MoneyAmount(
                            amount: t.amount,
                            flow: t.isDebit
                                ? MoneyFlow.debit
                                : MoneyFlow.credit,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            decimals: 2,
                          ),
                        ),
                      ],
                    ),
                    if (t.isDebit && !isDup) ...[
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        key: ValueKey('cat_${realIndex}_${t.category}'),
                        initialValue: categories.contains(t.category)
                            ? t.category
                            : (categories.contains('Other')
                                ? 'Other'
                                : (categories.isNotEmpty
                                    ? categories.first
                                    : null)),
                        decoration: InputDecoration(
                          labelText: 'Category',
                          isDense: true,
                          filled: true,
                          fillColor: AppColors.surfaceElevated,
                          prefixIcon: const Icon(
                            Icons.category_outlined,
                            size: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        dropdownColor: AppColors.card,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        items: [
                          ...categories.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(
                                category,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }),
                          const DropdownMenuItem(
                            value: _createCategoryValue,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.add_circle_outline_rounded,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Create new category…',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) async {
                          if (value == null) return;
                          if (value == _createCategoryValue) {
                            onCreateCategory();
                            return;
                          }
                          final old = t.category;
                          await onCategoryChanged(old, value);
                        },
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: onApplySimilar,
                          icon: const Icon(
                            Icons.auto_fix_high_rounded,
                            size: 16,
                          ),
                          label: const Text('Apply to similar'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final bool emphasized;

  const _Badge({
    required this.label,
    required this.color,
    required this.icon,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: emphasized
            ? color.withValues(alpha: 0.18)
            : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: emphasized ? 0.45 : 0.28),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: emphasized ? 12.5 : 12,
              fontWeight: FontWeight.w800,
              color: Color.lerp(color, Colors.black, 0.18),
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
